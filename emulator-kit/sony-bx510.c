/*
 * Sony BDP-BX510 / MediaTek MT8560 direct kernel boot, QEMU 9.2.
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Register references: Sony BDP-S1100 family Linux 2.6.35 release,
 * mach-mt85xx/include/mach/board-mt8560.h and drivers/serial/mt85xx_uart.h.
 */
#include "qemu/osdep.h"
#include "qapi/error.h"
#include "hw/arm/boot.h"
#include "hw/boards.h"
#include "hw/irq.h"
#include "hw/sysbus.h"
#include "sysemu/block-backend.h"
#include "sysemu/block-backend-global-state.h"
#include "block/block-common.h"
#include "hw/block/block.h"
#include "hw/qdev-properties.h"
#include "hw/qdev-properties.h"
#include "exec/address-spaces.h"
#include "sysemu/sysemu.h"
#include "sysemu/reset.h"
#include "chardev/char-fe.h"
#include "qemu/log.h"
#include "qemu/units.h"
#include "qemu/host-utils.h"
#include "qemu/timer.h"
#include "target/arm/cpu.h"
#include "mt8560-nfi.h"
#include "mt8560-hdhost.h"

#define TYPE_BX510_MACHINE MACHINE_TYPE_NAME("sony-bx510")
OBJECT_DECLARE_SIMPLE_TYPE(Bx510State, BX510_MACHINE)

#define BX_IO_BASE 0x70000000u
#define BX_BIM     0x8000u
#define BX_UART    0xc000u
#define BX_T0_IRQ  (1u << 27)
/* VERIFIED kernel-iomap.md (BIM group decode): SATA/ATAPI port = virq 53 ->
 * BIM group 1, pending 0x70008138 bit 21 (pending2/mask2); FE/SVOIF = virq 18
 * -> group 0, pending 0x70008030 bit 18 (pending/mask). The sata module
 * hard-codes these (registers its platform device with no resources). */
#define BX_FE_IRQ   (1u << 18)
#define BX_SATA_IRQ (1u << 21)
#define BX_BUS_HZ  135000000u
#define BX_UART_TX_EMPTY (1u << 5)
#define BX_UART_RX_READY (1u << 7)
#define BX_UART_IRQ      (1u << 14)

/* ==== FE mailbox reply constants (evidence/bx510-guest/bdpdrv/decode/
 * fe-ata-cmd.md §5) ==== */
/* 0x5c804 bit16 = "an FE message is pending" (§2.2). */
#define FE_IRQ_MSG    0x00010000u
/* Staged replies. The driver never has more than two outstanding — the
 * IDENTIFY payload and its type-0 completion (§5.2) — so four slots is
 * slack, not a ring-buffer design. */
#define FE_MSG_SLOTS  4
/* Loader-table block offset inside the FE DRAM window (fe-status-handshake.md
 * §9.1). */
#define FE_REPLY_OFF  0x1000u
#define FE_REPLY_LEN  0x0200u
/* IDENTIFY PACKET payload offset in the same window: the block rides the FE
 * DRAM window, never a mailbox word (§2.3, §5.3), and 0x2000 stays clear of
 * the table block above. */
#define FE_IDENT_OFF  0x2000u
#define FE_IDENT_LEN  0x0200u        /* == sizeof(Bx510State.identify) */

struct Bx510State {
    MachineState parent_obj;
    struct arm_boot_info boot;
    MemoryRegion io, drama_alias;
    CharBackend uart;
    qemu_irq irq;
    Mt8560Nfi nfi;
    Mt8560Hdhost hdhost;
    char *hdhost_path;
    uint32_t mask2, pending2;
    QEMUTimer *tick;
    uint32_t pending, mask, reload, control, hsem;
    uint32_t uart_mode, uart_comm, uart_ien;
    bool uart_tx_event;
    uint8_t rx[64];
    unsigned rx_head, rx_count;
    uint32_t mac[64];
    /* Minimal GFX/2D engine model (Phase C): the driver's GFX_HwReset
     * kicks 0xa0000000/0xc00001f0 then polls status until
     * (st & 0xc0000000)==0x80000000 && (st & 0x30000000)==0x20000000,
     * i.e. a read of 0xa0000000. Before the kick (write of 0x0 to the
     * cmd/status reg) reads return 0, matching the rmw observed on the
     * wire (read 0 -> write 0xf0000000 -> write 0x0). */
    bool gfx_kicked, gfx2_kicked;
    uint32_t gfx_cmd, gfx_cmd2, gfx2_cmd, gfx2_cmd2;
    /* ADSP load-table port (vAudHalSetDspLoadTable): index[0x110] +
     * data[0x108] with readback verify, mode[0x10c], port[0x100].
     * Model: last-written-value readback on the seen registers. */
    uint32_t adsp_port, adsp_idx, adsp_data, adsp_mode;
    uint16_t phy[32];
    int64_t tick_deadline;
    /* ==== SATA/ATAPI drive model (Phase C Feature 1+2) ====
     * The mt85xx SATA controller (bus 0x7000a000) presents ONE ATAPI
     * CD-ROM drive backed by a disc image. Register contract decoded
     * from bdpdrv i4IdeHal* (stub-run.md C53): link state 0x37
     * (PhyRdy), PHY signature 0xA000414D, taskfile echo, IDENTIFY
     * PACKET payload, IRQ status W1C at +0x220. */
    BlockBackend *sata_blk;
    char *sata_disc_path;
    bool sata_present;          /* media present */
    /* taskfile storage: [0]=feature [1]=nsect [2]=lbal [3]=lbam
       [4]=lbah [5]=device; command register separate */
    uint8_t tf[6], sata_cmd;
    /* status byte served at the status/command word (+0x1c). A status
     * MODEL, not a command echo: in C92 the echo returned 0xa1 after the
     * IDENTIFY issue — as a status byte that is BSY|ERR, so libata sat in
     * qc-timeout and the whole EH SRST loop failed on it
     * (ata-probe-path.md §5b). 0x50 = DRDY ready, 0x58 = DRDY|DRQ data
     * ready, 0x00 = busy/reset. */
    uint8_t sata_st;
    unsigned sata_didx;         /* IDENTIFY read cursor (word index) */
    /* RMW-storage registers the probe path touches (ata-probe-path.md §6
     * additions 1,3,4,5,6,7,8): read back the last written value. */
    uint32_t sata_a604, sata_a620, sata_a634, sata_a680;
    uint32_t sata_a080, sata_a114, sata_a108;
    bool trace_all;             /* BX510_TRACE=1: log EVERY MMIO access
                                 * (instrumentation decay: as cases become
                                 * implemented they vanish from the UNIMP
                                 * log — C92 lost the whole a-window). */
    /* IDENTIFY PACKET data (512 bytes, word-swapped words) */
    uint8_t identify[512];
    uint32_t sata_ist, sata_im; /* IRQ status (W1C) + mask */
    /* simple LBA -> disc offset state for read tracking */
    uint64_t sata_reads;
    /* FE boot-code SRAM FIFO (VERIFIED decode sata-fw-load.md sec 5a:
     * driver writes bytes at 0xfd324184 with write-pointer 0xfd324180
     * incrementing per byte; readback verifies through the SAME data
     * address 0xfd324184). FIFO storage + both counters. */
    uint8_t sram_fifo[0x4000];
    bool fe_booted;          /* set on 0x5c704 |= 0x601 (FE reset release) */
    /* FE mailbox (VERIFIED fe-status-handshake.md, recipe fe-ata-cmd.md §5):
     * 0x5c000..c00c = 16-byte command block (byte3 = code, byte2 = type),
     * 0x5c020 bit0 = doorbell, 0x5c040..c04c = 4-word status block,
     * 0x5c800 = interrupt mask, 0x5c804 bit16 = message pending (a LATCH,
     * write-1-to-clear — the FE IRQ top half drains it in a loop that ends
     * only on a zero read, so it must never be sticky).
     * C96 replaced the byte3-keyed fe_msg counter with a staged-message
     * queue: the reply is keyed on the command CONTENT (an `0xa1` post with
     * nonzero args is ATA IDENTIFY PACKET, not a chk_int_ldr call), and the
     * IDENTIFY case stages two messages (payload, then completion). */
    uint32_t fe_cmd[4];      /* 0x5c000..c00c */
    uint32_t fe_doorbell;    /* 0x5c020 */
    uint32_t fe_msg[FE_MSG_SLOTS][4]; /* staged replies [slot][word] */
    unsigned fe_msg_head;    /* slot the 0x5c040..c04c block serves */
    unsigned fe_msg_count;   /* staged replies not yet retired */
    uint32_t fe_irq;         /* 0x5c804 pending latch (W1C) */
    uint32_t fe_mask;        /* 0x5c800 interrupt mask */
    uint32_t fe_dma[4];      /* 0x5c400 addr, 0x5c404 len, 0x5c408/40c arm */
    /* 0x24200..0x2421f RMW bank (§5.1 rows 15-16; model-spec.md §3.1
     * identifies the block as the IR-RX conf/status words — the recipe's
     * echoed value leaves the poll bit 18 clear, i.e. "no remote packet"). */
    uint32_t fe_csr[8];
    uint32_t fe_dram_page;   /* value of 0x5c500 (window page) */
    unsigned unimp_logs;     /* storm cap for the default-arm -d log */
    uint32_t sram_wptr;      /* value of 0xfd324180 */
    uint32_t sram_ridx;      /* readback cursor (bytes consumed) */
};

static uint32_t bx510_l1_pending(Bx510State *s)
{
    bool rx_irq = s->rx_count && (s->uart_ien & 0xc0);
    bool tx_irq = s->uart_tx_event && (s->uart_ien & BX_UART_TX_EMPTY);
    return s->pending | ((rx_irq || tx_irq) ? BX_UART_IRQ : 0);
}

static void bx510_update_irq(Bx510State *s)
{
    qemu_set_irq(s->irq, !!((bx510_l1_pending(s) & s->mask) | (s->pending2 & s->mask2)));
}

static int bx510_uart_room(void *opaque)
{
    Bx510State *s = opaque;
    return sizeof(s->rx) - s->rx_count;
}

static void bx510_uart_receive(void *opaque, const uint8_t *buf, int size)
{
    Bx510State *s = opaque;
    for (int i = 0; i < size && s->rx_count < sizeof(s->rx); i++) {
        s->rx[(s->rx_head + s->rx_count) % sizeof(s->rx)] = buf[i];
        s->rx_count++;
    }
    bx510_update_irq(s);
}

static void bx510_nfi_irq(void *opaque, int line, int level)
{
    Bx510State *s = opaque;
    if (level) {
        s->pending2 |= 2;
    } else {
        s->pending2 &= ~2u;
    }
    bx510_update_irq(s);
}

/* Timer 0 counts bus clock cycles down to zero. */
static void bx510_schedule(Bx510State *s)
{
    timer_del(s->tick);
    if ((s->control & 1) && s->reload) {
        int64_t period_ns = muldiv64(s->reload, NANOSECONDS_PER_SECOND, BX_BUS_HZ);
        s->tick_deadline = qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL) + MAX(period_ns, 1);
        timer_mod(s->tick, s->tick_deadline);
    }
}

static void bx510_tick(void *opaque)
{
    Bx510State *s = opaque;
    s->pending |= BX_T0_IRQ;
    bx510_update_irq(s);
    if (s->control & 2) {
        bx510_schedule(s);
    } else {
        s->control &= ~1u;
    }
}

/* STAR control plane. The PHY can be probed; this version has no MAC DMA backend. */
/* The status block the FE 'DMAes' into the internal-loader DRAM window when
 * message A is posted. Six non-zero bytes: 'O','B','T','O' at 0x2e..0x31
 * (four SEPARATE byte compares in sata_mt85xx_chk_int_ldr .text+0x29a4..0x2a14
 * — the literal ASCII order 'BOOT' fails, mutant-proven) and the length
 * marker 0xeeee at 0x100 (LE16, .text+0x29b0, sets *out=1). */
static const uint8_t fe_reply_block[FE_REPLY_LEN] = {
    [0x2e] = 0x4f, [0x2f] = 0x42, [0x30] = 0x54, [0x31] = 0x4f,
    [0x100] = 0xee, [0x101] = 0xee,
};
static uint32_t bx510_mac_read(Bx510State *s, hwaddr reg)
{
    switch (reg) {
    case 0x08: return s->mac[reg / 4] | (1u << 29);
    case 0x1c: return (s->mac[reg / 4] & ~(1u << 14)) | (3u << 16);
    case 0x2c: return s->mac[reg / 4] | 1;
    default: return s->mac[reg / 4];
    }
}

static void bx510_mac_write(Bx510State *s, hwaddr reg, uint32_t val)
{
    if (reg != 0) {
        s->mac[reg / 4] = val;
        return;
    }
    unsigned phy = val & 31, index = (val >> 8) & 31;
    if (val & (1u << 14)) {
        uint16_t data = phy ? 0xffff : s->phy[index];
        s->mac[0] = ((uint32_t)data << 16) | (1u << 15);
    } else if (val & (1u << 13)) {
        if (!phy) {
            s->phy[index] = val >> 16;
            if (!index) { s->phy[index] &= ~(1u << 15); }
        }
        s->mac[0] = 1u << 15;
    } else if (val & (1u << 15)) {
        s->mac[0] &= ~(1u << 15);
    }
}

/* ==== C96 FE reply state machine (fe-ata-cmd.md §5.2) ==== */

/* Write a block into the FE DRAM window the driver programmed at 0x5c500
 * (page << 22, fe-ata-cmd.md §2.3). Skip when the driver never programmed a
 * page — don't scribble low RAM. */
static void bx510_fe_dram_write(Bx510State *s, uint32_t off,
                                const uint8_t *buf, unsigned len)
{
    hwaddr win;
    unsigned i;
    if (!s->fe_dram_page) {
        return;
    }
    win = ((hwaddr)(s->fe_dram_page & 0xff)) << 22;
    for (i = 0; i < len; i++) {
        stb_phys(&address_space_memory, win + off + i, buf[i]);
    }
}

/* Stage one 4-word reply message and raise the message-pending bit. The
 * caller must have published the payload first: the bottom half reads
 * 0x5c040..c04c only after the latch (§5.2 hard rule 2), and the bit is
 * raised here, never inside the same write that staged the words. */
static void bx510_fe_post(Bx510State *s, uint32_t w0, uint32_t w1,
                          uint32_t w2, uint32_t w3)
{
    unsigned slot = (s->fe_msg_head + s->fe_msg_count) % FE_MSG_SLOTS;

    if (s->fe_msg_count >= FE_MSG_SLOTS) {
        /* the driver retires a message before posting the next one */
        qemu_log_mask(LOG_GUEST_ERROR,
                      "bx510: FE reply queue full, overwriting newest\n");
        slot = (s->fe_msg_head + FE_MSG_SLOTS - 1) % FE_MSG_SLOTS;
        s->fe_msg_count = FE_MSG_SLOTS - 1;
    }
    s->fe_msg[slot][0] = w0;
    s->fe_msg[slot][1] = w1;
    s->fe_msg[slot][2] = w2;
    s->fe_msg[slot][3] = w3;
    s->fe_msg_count++;
    s->fe_irq |= FE_IRQ_MSG;   /* 0x5c804 bit16 */
    s->pending |= BX_FE_IRQ;   /* BIM group0 bit18 */
    bx510_update_irq(s);
}

/* Content-keyed reply dispatch on the 0x5c020 doorbell (§5.2). Keying is on
 * w0/w1..w3 content, never on byte3 alone: `.text+0xa1` is BOTH the
 * chk_int_ldr entry code and the ATA IDENTIFY PACKET command byte, and only
 * the argument words tell them apart (§3.3). */
static void bx510_fe_dispatch(Bx510State *s)
{
    uint32_t w0 = s->fe_cmd[0];
    unsigned code = (w0 >> 24) & 0xff;
    unsigned type = (w0 >> 16) & 0xff;
    uint32_t arg = s->fe_cmd[1] | s->fe_cmd[2] | s->fe_cmd[3];

    if (type == 0x10) {
        /* _svoif_mt85xx_send_table_data_ack_cmd (.text+0x3c50): the driver
         * ACKed message A, so post message B — a bare type-0 completion. Keyed
         * on the type byte alone, which is the pre-C96 behaviour and is
         * equivalent here: the ACK is the driver's only type-0x10 post and it
         * always carries w1 = w2 = w3 = 0 (§3). */
        bx510_fe_post(s, 0, 0, 0, 0);
        return;
    }
    if (code == 0xa1 && arg == 0) {
        /* chk_int_ldr entry (.text+0x2850): it zeroes the six taskfile words
         * immediately before posting (.text+0x285c..0x2870), so an `0xa1`
         * post with arg == 0 is the table-data request. Message A = a
         * type-0x10 offer of the loader block at (w1, w2) (§5.1 rows 4-7). */
        bx510_fe_dram_write(s, FE_REPLY_OFF, fe_reply_block, FE_REPLY_LEN);
        bx510_fe_post(s, 0x00100000u, FE_REPLY_OFF, FE_REPLY_LEN, 0);
        return;
    }
    if (code == 0xa1) {
        /* ATA IDENTIFY PACKET DEVICE (C95 cmd#3, §3.3): the payload rides the
         * FE DRAM window in a type-0x10 message. C98 LESSON (hsm-buffer-seq.md
         * §0.2/§3.2): the bottom-half work item reads the status block EXACTLY
         * ONCE per invocation (priv+0x2dc is never cleared, so its loop-back
         * tail is dead), and two posts collapse into one latch bit whose block
         * content is the LAST message written. Any two-message scheme therefore
         * fails: payload-then-completion overwrites the payload (C97:
         * 'device reports invalid type'), completion-then-payload consumes the
         * completion and orphans the payload (C98: 'unsupported CDB len').
         * Variant A (hsm-buffer-seq.md §3.3-A): post ONLY the type-0x10 payload
         * — it is the single block read the driver will ever do for this qc;
         * the predicted C99 observable is 'ST_FIRST: !(DRQ|ERR|DF)' +
         * err_mask=0x2 (the DRQ-less poll), which converts the state question
         * into a measurement. */
        bx510_fe_dram_write(s, FE_IDENT_OFF, s->identify, FE_IDENT_LEN);
        bx510_fe_post(s, 0x00100000u, FE_IDENT_OFF, FE_IDENT_LEN, 0);
        return;
    }
    /* 0xf7 prereset / 0x08 soft reset / anything unknown: a type-0 success
     * completion. Never stay silent — silence is a 30 s libata timeout, not a
     * fast failure (§5.2 last row). */
    bx510_fe_post(s, 0, 0, 0, 0);
}

static uint64_t bx510_read(void *opaque, hwaddr off, unsigned size)
{
    Bx510State *s = opaque;
    if (s->trace_all) {
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: MMIO R %06x sz%u\n",
                      (unsigned)off, size);
    } else if (off >= 0xa000 && off < 0xb000) {
        /* a-window trace (C92 blind spot: the -D log only carried UNIMP
         * lines, so every a-window access was invisible). */
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: SATA RD a+%03x sz%u\n",
                      (unsigned)off, size);
    }
    uint64_t ns;
    if (off >= 0x33000 && off < 0x33100) {
        return bx510_mac_read(s, off - 0x33000);
    }
    if (off >= 0x24200 && off < 0x24220) {
        /* 0x24200..0x2421f RMW bank: echo what was written (fe-ata-cmd.md
         * §5.1 rows 15-16, "first try the stored 0x111"). */
        return s->fe_csr[(off - 0x24200) / 4];
    }
    switch (off) {
    case 0x1effc: return 0; /* DMA writes have drained */
    case 0: return 0x8560; /* MT8560 revision A */
    case BX_UART:
        if (s->rx_count) {
            uint8_t ch = s->rx[s->rx_head];
            s->rx_head = (s->rx_head + 1) % sizeof(s->rx);
            s->rx_count--;
            bx510_update_irq(s);
            qemu_chr_fe_accept_input(&s->uart);
            return ch;
        }
        return 0;
    case BX_UART + 0x04: return (s->uart_mode & 0x40) | 2 | !!s->rx_count;
    case BX_UART + 0x0c: return s->uart_ien;
    case BX_UART + 0x10: return (s->uart_tx_event ? BX_UART_TX_EMPTY : 0) |
                                (s->rx_count ? BX_UART_RX_READY : 0);
    case BX_UART + 0x28: return s->uart_comm;
    case BX_UART + 0x4c: return 0x1f00; /* transmit FIFO free; RX empty */
    case BX_BIM + 0x138: return s->pending2;
    case BX_BIM + 0x13c: return s->mask2;
    case BX_BIM + 0x154: case BX_BIM + 0x158: return 0;
    case BX_BIM + 0xe8: return 0; /* bootloader console-suppression flag */
    case BX_BIM + 0x1b4: return s->hsem;
    case BX_BIM + 0x30: return bx510_l1_pending(s);
    case BX_BIM + 0x34: return s->mask;
    case BX_BIM + 0x60: return s->reload;
    case BX_BIM + 0x64:
        ns = MAX((int64_t)0, s->tick_deadline - qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL));
        return muldiv64(ns, BX_BUS_HZ, NANOSECONDS_PER_SECOND);
    case BX_BIM + 0x78: return s->control;
    case 0x4000: /* GFX engine status/command */
        return s->gfx_kicked ? 0xa0000000u : 0u;
    case 0x4800: /* second engine slot (RLE/SE; RLE_HwReset) */
        return s->gfx2_kicked ? 0xa0000000u : 0u;
    case 0x8118: /* FastLogo_STATUS: vAudInitThread polls until ==0x40
                  * (logo playback finished / idle). We boot straight to
                  * idle. VERIFIED Run C23-28: poll-only, never written. */
        return 0x40u;
    case 0x5c804: /* FE interrupt STATUS; bit16 = an FE message is pending
                   * (fe-ata-cmd.md §2.2). A LATCH cleared by write-1-to-clear,
                   * not a read-and-clear: every reader writes back what it
                   * read (chk_int_ldr .text+0x28b0, port_start .text+0x327c,
                   * and the IRQ top half's drain loop .text+0x34b4..34c8,
                   * which exits only on a ZERO read — so returning 0 once the
                   * queue is consumed is mandatory, and a sticky bit is the
                   * pre-C95 4.4 GB storm). */
        return s->fe_irq & FE_IRQ_MSG;
    case 0x5c808: /* secondary status word folded into the wake payload
                   * ((extra) | (bit16 << 8), .text+0x34f8..0x350c); 0 is safe
                   * — the value only lands in priv+0x234[n] (§5.1 row 10). */
        return 0;
    case 0x5c800: /* FE interrupt MASK (.text+0x34b0). port_start programs
                   * 0xfffffff0 here (.text+0x32d0) after chk_int_ldr call #1;
                   * the reset default keeps bit16 set (see bx510_reset) so the
                   * top half's (pending & mask) still latches a message before
                   * that write — a 0 mask silently discards every FE message
                   * (fe-ata-cmd.md §0 defect #2). */
        return s->fe_mask;
    case 0x5c040: case 0x5c044: case 0x5c048: case 0x5c04c: {
        /* The four-word FE->CPU reply: w0 byte2 = type, byte3 = status,
         * w1 = DRAM-window offset, w2 = length, w3 unused (§2.1). Always the
         * head message; the words stay readable after the queue drains (the
         * block is a register set, not a FIFO read port). Retire on the LAST
         * word: both consumers read w0..w3 in order (chk_int_ldr
         * .text+0x28b8..28d8, the IRQ bottom half .text+0x4640..4660), so w3
         * ends the message. */
        unsigned i = (off - 0x5c040) / 4;
        uint32_t v = s->fe_msg[s->fe_msg_head][i];
        if (i == 3 && s->fe_msg_count) {
            s->fe_msg_count--;
            if (s->fe_msg_count) {
                /* the next staged message becomes the block content; re-arm
                 * the pending bit so the driver polls it out (the IDENTIFY
                 * completion, §5.2 step (3)). */
                s->fe_msg_head = (s->fe_msg_head + 1) % FE_MSG_SLOTS;
                s->fe_irq |= FE_IRQ_MSG;
                s->pending |= BX_FE_IRQ;
                bx510_update_irq(s);
            }
        }
        return v;
    }
    case 0x5c000: case 0x5c004: case 0x5c008: case 0x5c00c:
        return s->fe_cmd[(off - 0x5c000) / 4];
    case 0x5c020:
        return s->fe_doorbell;   /* stored value: the RMW must be lossless */
    case 0x5c400: case 0x5c404: case 0x5c408: case 0x5c40c:
        /* data_xfer's READ-CDB descriptor (.text+0x5814..0x5874): host
         * address, byte count, and two flag words the driver only ever ORs
         * bits into, so returning what was written keeps the RMW lossless
         * (§5.1 rows 11-12). */
        return s->fe_dma[(off - 0x5c400) / 4];
    /* ---- SATA/ATAPI (bus 0x7000a000, off 0xa000) ---- */
    case 0x324180: /* FE SRAM FIFO write pointer readback */
        return s->sram_wptr;
    case 0x324184: /* FE SRAM FIFO data: pops the byte stream in write order */
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: FE-SRAM FIFO read idx=%u val=%02x\n",
                      s->sram_ridx, s->sram_ridx < sizeof(s->sram_fifo) ? s->sram_fifo[s->sram_ridx] : 0);
        if (s->sram_ridx < sizeof(s->sram_fifo)) {
            return s->sram_fifo[s->sram_ridx++];
        }
        return 0;
    case 0xa600: /* PHY_CTRL00: signature readback + reset bit0 */
        return 0xa000414du | (s->sata_present ? 0x370000u : 0x220000u);
    case 0xa610: /* LNK_CTRL08: link state bits[21:16] */
        return s->sata_present ? 0x370000u : 0x220000u;
    case 0xa648: /* per-ch busy poll: bits[12:8] must clear */
        return 0;
    case 0xa220: /* IRQ status (W1C) */
        return s->sata_ist;
    case 0xa01c: /* status/command word — serve the STATUS model */
        return s->sata_st;
    case 0xa004: case 0xa008: case 0xa00c:
    case 0xa010: case 0xa014: case 0xa018: {
        unsigned i = (off - 0xa004) / 4;
        /* The post-reset ATAPI signature: ONE block, the SATA D2H
         * signature word 0xeb140101, nsect/lbal/lbam/lbah = 01/01/14/eb at
         * i=2..5 (+0x00c..+0x018). Two drivers read DISJOINT slices of it,
         * one word apart, and each one's own arithmetic then lands on its
         * expected constant (decode/ide-hal-rows.md):
         *  - libata: port_start recomposes lbah<<16 | lbam<<8 | lbal from
         *    i=3..5 -> 0x00eb1401, and ata_dev_classify compares
         *    (lbam | lbah<<8) == 0xeb14 (ata-probe-path.md §6 add.10; run
         *    C101's "class=3" is the guest proof of this placement).
         *  - IDE HAL: i4IdeHalGetSignature (0x9a384) loads the hard literals
         *    0xfd00a014 / 0xfd00a010 / 0xfd00a00c and composes
         *    +014<<16 | +010<<8 | +00c = lbam<<16 | lbal<<8 | nsect ->
         *    0x140101, which is what a real player prints (it only branches
         *    on sig == 1, i.e. ATAPI 0xa1 for anything else).
         * The old table started at i=3 and so left +0x00c reading 0. Serve
         * the block while the stored tf byte is still zero (nothing
         * loaded); after tf_load writes a real command the stored byte
         * wins, so real commands see their own taskfile. */
        if (i >= 2 && s->tf[i] == 0) {
            static const uint8_t sig[4] = { 0x01, 0x01, 0x14, 0xeb };
            return sig[i - 2];
        }
        return s->tf[i];
    }
    case 0xa604: return s->sata_a604;   /* PHY_CFG0 reset-pulse RMW */
    case 0xa620: return s->sata_a620;   /* PHY_CFG1 */
    case 0xa634: return s->sata_a634;   /* PHY_CFG2 speed/width field */
    case 0xa680: return s->sata_a680;   /* PHY_CFG3 */
    case 0xa080: return s->sata_a080;   /* CH_IRQ_EN (bit8 RMW'd) */
    case 0xa114: return s->sata_a114;   /* PHY_CH_EN per-channel bytes */
    case 0xa108: return s->sata_a108;   /* FE data word (bit15 doorbell) */
    case 0xa000: case 0xa25c: {
        /* PIO data port (+0x000; +0x25c is data_xfer's burst-store port,
         * aliased here so the FE-path stores are absorbed too). Serve the
         * IDENTIFY payload as 16-bit LE words in issue order. */
        uint32_t v = 0;
        if (s->sata_didx < 256) {
            unsigned wi = s->sata_didx;
            v = s->identify[wi * 2] | (s->identify[wi * 2 + 1] << 8);
            s->sata_didx = wi + 1;
            if (size == 4 && s->sata_didx < 256) {
                wi = s->sata_didx;
                v |= (uint32_t)(s->identify[wi * 2] |
                                (s->identify[wi * 2 + 1] << 8)) << 16;
                s->sata_didx = wi + 1;
            }
            if (s->sata_didx == 256) {
                s->sata_st = 0x50;  /* payload fully drained */
            }
        }
        return v;
    }
    case 0xa400: case 0xa480: /* per-channel regs (ch0/ch1 base) */
        return 0;
    case 0x62c: /* global ctrl (vIdeHalBusEnable toggles bit4) */
        return 0;
    case 0x6c8: /* IRQ mask/unmask */
        return s->sata_im;
    case 0x5100: return s->adsp_port;
    case 0x5108: return s->adsp_data;   /* readback verify */
    case 0x510c: return s->adsp_mode;
    case 0x5110: return s->adsp_idx;
    default:
        if (s->unimp_logs++ < 200000) {
            qemu_log_mask(LOG_UNIMP, "bx510: unimplemented read 0x%" HWADDR_PRIx " (%u)\n",
                          off + BX_IO_BASE, size);
        }
        return 0;
    }
}

static void bx510_write(void *opaque, hwaddr off, uint64_t val, unsigned size)
{
    Bx510State *s = opaque;
    uint8_t ch = val;
    if (s->trace_all) {
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: MMIO W %06x sz%u = %llx\n",
                      (unsigned)off, size, (unsigned long long)val);
    } else if (off >= 0xa000 && off < 0xb000) {
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: SATA WR a+%03x sz%u = %llx\n",
                      (unsigned)off, size, (unsigned long long)val);
    }
    if (off >= 0x33000 && off < 0x33100) {
        bx510_mac_write(s, off - 0x33000, val);
        return;
    }
    if (off >= 0x24200 && off < 0x24220) {
        /* 0x24200..0x2421f RMW bank: store; reads echo it back (§5.1 rows
         * 15-16). C95 wrote 0x2420c=0x111, 0x24210=0xe1, 0x24214=0x200,
         * 0x24218=1 (FE/HAL descriptor + start bit, §4.2). */
        s->fe_csr[(off - 0x24200) / 4] = val;
        return;
    }
    switch (off) {
    case BX_UART:
        qemu_chr_fe_write_all(&s->uart, &ch, 1);
        /* One empty transition per drained burst. Linux leaves the enable
         * set when idle and acknowledges the latched event at the BIM. */
        if (s->uart_ien & BX_UART_TX_EMPTY) {
            s->uart_tx_event = true;
            bx510_update_irq(s);
        }
        break;
    case BX_UART + 0x0c: s->uart_ien = val; bx510_update_irq(s); break;
    case BX_UART + 0x10:
        if (val & BX_UART_TX_EMPTY) {
            s->uart_tx_event = false;
            bx510_update_irq(s);
        }
        break;
    case BX_UART + 0x04: s->uart_mode = val; break;
    case BX_UART + 0x28: s->uart_comm = val; break;
    case BX_BIM + 0x13c: s->mask2 = val; bx510_update_irq(s); break;
    case BX_BIM + 0x138:
        /* group1 pending is W1C (kernel-iomap.md BIM decode: groups mirror
         * the 0x30/0x34/0x38 shape). The SATA ISR acks here — without this
         * the raised BX_SATA_IRQ never clears and the level line storms
         * (C73 ENOSPC: the interrupt storm flooded the UART). */
        s->pending2 &= ~val;
        bx510_update_irq(s);
        break;
    case BX_BIM + 0x140:
        s->pending2 &= ~val;   /* cascade group ack (same W1C shape) */
        bx510_update_irq(s);
        break;
    case BX_BIM + 0x1b4:
        /* The single CPU writes the same bit to acquire and release it. */
        s->hsem ^= val;
        break;
    case BX_BIM + 0x30:
    case BX_BIM + 0x38:
        s->pending &= ~val;
        if (val & BX_UART_IRQ) {
            s->uart_tx_event = false;
        }
        bx510_update_irq(s);
        break;
    case BX_BIM + 0x34:
        s->mask = val;
        bx510_update_irq(s);
        break;
    case BX_BIM + 0x60: s->reload = val; bx510_schedule(s); break;
    case BX_BIM + 0x78: s->control = val; bx510_schedule(s); break;
    case 0x4000: /* GFX engine: 0xa0000000/0xf0000000 = command words,
                  * 0x0 = GO. (VERIFIED Run C22-25: GFX_HwReset kick.) */
        s->gfx_cmd = val;
        if (val == 0) {
            s->gfx_kicked = true;
        }
        break;
    case 0x4010: s->gfx_cmd2 = val; break;
    case 0x4104:
    case 0x4134: break;
    case 0x4800:
        s->gfx2_cmd = val;
        if (val == 0) {
            s->gfx2_kicked = true;
        }
        break;
    case 0x4810: s->gfx2_cmd2 = val; break;
    case 0x4804:
    case 0x4834: break;
    /* ---- SATA/ATAPI writes ---- */
    case 0xa004: case 0xa008: case 0xa00c:
    case 0xa010: case 0xa014: case 0xa018:
        s->tf[(off - 0xa004) / 4] = val & 0xff;
        break;
    case 0xa01c: /* command/control word issued */
        /* Two kinds of write land on this word: ATA commands (>= 0x10:
         * 0xa1 IDENTIFY PACKET, 0xec, ...) and Device-Control writes
         * (0x00/0x02 nIEN, 0x04/0x06/0x0e SRST). Classify by bit2: an
         * SRST write is a device reset — complete it instantly (status
         * back to 0x50, taskfile cleared so the signature trio serves
         * again) instead of pretending it was a command. */
        if ((val & 0xff) < 0x10) {
            if (val & 0x04) {
                memset(s->tf, 0, sizeof(s->tf));
                s->sata_st = 0x50;   /* reset already complete */
                s->sata_didx = 0;
            }
            break;                   /* nIEN/ctl write: no command */
        }
        s->sata_cmd = val & 0xff;
        /* Any real command completes immediately and raises virq 53
         * (BIM group1 bit21, VERIFIED kernel-iomap.md). Status goes to
         * DRQ (data ready on the PIO port); libata drains 256 words and
         * the port then reads 0x50 again.
         * Completion also latches bit5: the IDE HAL finishes a command on
         * (status & 0x20) when flags&3 == 1 (i4IdeHalWaitEvt 0x9e300,
         * `tst r3,#32`), while the libata/FE consumers test bit0
         * (trig_fe_boot 0x25d4: bits 0|4) or bit4 (xfer_fe_data 0x2240).
         * Nothing anywhere tests bit5 for a different meaning (the
         * sata_mt85xx `tst #32` hits are all the ide_log_en flag), and
         * every a+220 reader accumulates the whole word and writes it back
         * (_u4IdeHalHwIntStatus 0x9dc3c..0x9dc40, trig_fe_boot 0x25dc,
         * xfer_fe_data 0x2244) — so both bits ack write-1-to-clear and the
         * extra bit5 is invisible to the bit0/bit4 tests
         * (decode/ide-hal-rows.md, completion row). */
        s->sata_ist |= 0x1u | 0x20u;
        s->sata_st = 0x58;
        s->sata_didx = 0;
        s->pending2 |= BX_SATA_IRQ;
        bx510_update_irq(s);
        break;
    case 0x324180: /* FE SRAM FIFO pointer. The driver uses it as a random-
                    * access index (stores i before byte i) and resets it to 0
                    * before the readback verify (.init.text+0x5bc). Reads of
                    * 0x324184 auto-increment the same cursor, so the reset must
                    * move the read cursor too — otherwise the 16,384 dummy
                    * readbacks at .init.text+0x58c exhaust it and the verify
                    * reads 0 forever (decode/sram-readback-live.md). */
        qemu_log_mask(LOG_GUEST_ERROR, "bx510: FE-SRAM FIFO wptr=%u\n", (unsigned)val);
        s->sram_wptr = val;
        s->sram_ridx = val;
        break;
    case 0x324184: /* FE SRAM FIFO data byte */
        if (s->sram_wptr < sizeof(s->sram_fifo)) {
            s->sram_fifo[s->sram_wptr++] = (uint8_t)val;
        }
        break;
    case 0xa000: /* PIO data port write — record, no-op */
        break;
    case 0xa25c: /* PIO burst store port (data_xfer, 7x32-bit) — record */
        break;
    case 0xa604: s->sata_a604 = val; break;
    case 0xa620: s->sata_a620 = val; break;
    case 0xa634: s->sata_a634 = val; break;
    case 0xa680: s->sata_a680 = val; break;
    case 0xa080: s->sata_a080 = val; break;
    case 0xa114: s->sata_a114 = val; break;
    case 0xa108: /* FE data word: bit15 is the doorbell the driver sets and
                  * polls back — the FE consumes the command, so clear it. */
        s->sata_a108 = val & ~0x8000u;
        break;
    case 0xa220: /* IRQ status W1C */
        s->sata_ist &= ~val;
        bx510_update_irq(s);
        break;
    case 0x6c8: /* IRQ mask */
        s->sata_im = val;
        bx510_update_irq(s);
        break;
    case 0x5c000: case 0x5c004: case 0x5c008: case 0x5c00c:
        s->fe_cmd[(off - 0x5c000) / 4] = val;
        break;
    case 0x5c020: /* doorbell: bit0 = "a command block was posted"
                   * (data_xfer .text+0x57e0, send_ata_cmd .text+0x3b60, ack
                   * .text+0x3cb4 — all read-modify-write `|= 1`, so bit0 is
                   * never cleared by the driver and an edge trigger would
                   * swallow every post after the first: dispatch on EVERY
                   * write with bit0 set). Bits 1..31 stay latched so the RMW
                   * is lossless (fe-ata-cmd.md §5.1 row 3). */
        s->fe_doorbell = val;
        if (val & 1) {
            bx510_fe_dispatch(s);
        }
        break;
    case 0x5c800: /* FE interrupt mask (port_start writes 0xfffffff0).
                   * bit16 is OR'd in on every write (fe-ata-cmd.md §5.1 row 8
                   * "at minimum 0x10000"): a mask write of 0 would otherwise
                   * silently discard every FE message — the exact defect-#2
                   * mechanism. No decoded writer ever writes 0 here, so this
                   * only guards the latent case. */
        s->fe_mask = val | FE_IRQ_MSG;
        break;
    case 0x5c804: /* FE interrupt status: write-1-to-clear exactly the bits
                   * written — all three readers write back the value they
                   * read (fe-ata-cmd.md §2.2). */
        s->fe_irq &= ~(uint32_t)val;
        break;
    case 0x5c400: case 0x5c404: case 0x5c408: case 0x5c40c:
        /* data_xfer descriptor writes: host addr, length, arm/direction
         * flags. On the executed path they are only written, never
         * consumed — the reply still arrives as a mailbox message (§1.2). */
        s->fe_dma[(off - 0x5c400) / 4] = val;
        break;
    case 0x5c500: /* FE DRAM window page (xfer_int_ldr_fw .text+0x1940) */
        s->fe_dram_page = val;
        break;
    case 0x5c704: /* FE reset release (i4IdeDrvBootup: |= 0x601 arms the FE).
                     virq 18 = BIM group0 bit18 (VERIFIED kernel-iomap.md):
                     the release is what 'polling frontend reset interrupt'
                     waits for. It also arms the bare 0x5c804 bit16 that
                     port_start's state==1 fast path polls BEFORE any command
                     is posted (.text+0x3244..0x3280).
                     C96 LESSON: the arm must key on the FULL release value
                     (val & 0x601) == 0x601, not merely nonzero — the driver
                     writes 0xa01 first (0xa01 & 0x601 = 0x201, truthy) and
                     THEN issues its 'clear default interrupt' W1C
                     (0x5c804 = 0x10000); an arm that fired at 0xa01 is
                     consumed by that W1C and the fast-path poll then reads 0
                     forever ('polling frontend reset interrupt timeout').
                     0x601 re-fires the arm after the clear, matching the
                     C95 trace (R 05c804 = 0x10000 at the first poll read). */
        if (val & 0x601) {
            if (!s->fe_booted) {
                s->fe_booted = true;
            }
            if ((val & 0x601) == 0x601) {
                s->fe_irq |= FE_IRQ_MSG;   /* boot-ready; W1C-consumable */
            }
            s->pending |= BX_FE_IRQ;
            bx510_update_irq(s);
        }
        break;
    case 0x5c600: case 0x5c604: case 0x5c708: case 0x5c780:
    case 0x60004: case 0x90308: case 0x9030c: case 0x90324:
        break; /* FE/clock/DRAM-wrapper control writes accepted silently
                * (0x5c500 has its own case above — the DRAM window page) */
    case 0xa600: case 0xa610: case 0xa648:
    case 0xa400: case 0xa480: case 0x62c:
        break; /* accepted silently */
    case 0x5100: s->adsp_port = val; break;
    case 0x5108: s->adsp_data = val; break;
    case 0x510c: s->adsp_mode = val; break;
    case 0x5110: s->adsp_idx = val; break;
    default:
        if (s->unimp_logs++ < 200000) {
            qemu_log_mask(LOG_UNIMP, "bx510: unimplemented write 0x%" HWADDR_PRIx " = 0x%" PRIx64 " (%u)\n",
                          off + BX_IO_BASE, val, size);
        }
    }
}


static const MemoryRegionOps bx510_ops = {
    .read = bx510_read, .write = bx510_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
    .valid.min_access_size = 1, .valid.max_access_size = 4,
};

/* ---- SATA/ATAPI helpers (Phase C Feature 1) ----
 * Build a minimal ATAPI IDENTIFY PACKET DEVICE payload: packet device,
 * CD-ROM, SATA bridge, serial/firmware strings, LBA capacity from the
 * block backend. Word layout per ATA8; driver reads it through the
 * 16-bit PIO port. */
static void bx510_sata_build_identify(Bx510State *s)
{
    uint16_t *w = (uint16_t *)s->identify;
    uint64_t sectors = 0;
    memset(s->identify, 0, sizeof(s->identify));
    if (s->sata_blk) {
        sectors = blk_getlength(s->sata_blk) / 2048;
    }
    /* id-validity-check.md §3.3/§4: libata's class-3 payload gate is id[0]
     * bit15 only (libata .text+0x3cb8 ldrsh/bge); bits[1:0] = 0 selects the
     * 12-byte CDB (configure .text+0x4b0c, table .rodata+0x728); bits[6:5]
     * stay 00 (no ", CDB intr"); word 2 must not be a spin-up magic. */
    w[0] = 0x8000 | 5 << 8 | 0x80; /* type 5 = CD-ROM, removable, ATAPI */
    w[2] = 0x0000;                 /* never 0x37c8/0x738c: that asks for SPINUP */
    w[49] = 1 << 9;                /* LBA supported */
    w[49] |= 1 << 11;              /* LBA48 (ata_do_set_mode verify .text+0x64cc) */
    w[53] = 0x0007;                /* words 54-58 / 64-70 / 88 valid */
    w[63] = 7;                     /* PIO modes 3/4 supported */
    w[64] = 0x0003;                /* advanced PIO3/PIO4 (pio = 7 | ((w64&3)<<3)) */
    w[80] = 0x1e;                  /* ATA-4..ATA-6 */
    w[84] = 0x4000; w[85] = 0x4000;
    w[87] = 0x4000;                /* DMA setup */
    w[88] = 0x0007;                /* UDMA modes (needs w[53]&4) */
    w[83] = 0x4000;                /* LBA48 count valid; NOT 0x4004 (CFA branch!) */
    w[60] = (uint16_t)sectors;     /* ata_id_n_sectors reads w[60]|w[61]<<16 */
    w[61] = (uint16_t)(sectors >> 16);
    w[100] = (uint16_t)sectors;
    w[101] = (uint16_t)(sectors >> 16);
    w[102] = (uint16_t)(sectors >> 32);
    w[103] = (uint16_t)(sectors >> 48);
    /* ata_id_string takes the HIGH byte of each word first, so ASCII must be
     * stored WORD-SWAPPED (ata_id_string reads pairs as [hi,lo] and prints in
     * sequence — C100 proved unswapped ASCII prints as 'OSYN DBSPCAEDUM').
     * Byte offset 2*word is the word index; each 2-char pair is reversed. */
    {   /* helper: store a string with each 2-char pair swapped */
        const char *src; unsigned char *dst; unsigned i, n;
        src = "SONY    BDPSACDEMUL  "; dst = (unsigned char *)w + 54;
        for (i = 0; i < 20; i += 2) { dst[i] = src[i + 1]; dst[i + 1] = src[i]; }
        src = "1.00    "; dst = (unsigned char *)w + 46;
        for (i = 0; i < 8; i += 2) { dst[i] = src[i + 1]; dst[i + 1] = src[i]; }
        src = "SACDEMUL0001  "; dst = (unsigned char *)w + 20;
        for (i = 0; i < 20; i += 2) { dst[i] = src[i + 1]; dst[i + 1] = src[i]; }
        (void)n;
    }
    /* 'Drive reports diagnostics failure' (C100): the diag message comes from
     * the smart/diag bits libata reads — clear the offline SMART capability
     * bits so no diagnostics are advertised (id-validity-check.md §3.2 notes
     * w[84/85/87] are pass-through; the diag print reads w[82]/w[83]-adjacent
     * SMART bits — keep them zero). */
}

static void bx510_reset(void *opaque)
{
    Bx510State *s = opaque;
    timer_del(s->tick);
    s->pending = s->pending2 = s->mask = s->mask2 = 0;
    s->control = s->reload = s->hsem = 0;
    s->tick_deadline = 0;
    s->uart_tx_event = false;
    s->rx_count = s->rx_head = s->uart_mode = s->uart_ien = s->uart_comm = 0;
    memset(s->mac, 0, sizeof(s->mac));
    memset(s->phy, 0, sizeof(s->phy));
    s->mac[0x74 / 4] = 0x77; /* AHB signature tested by the Sony driver */
    s->phy[3] = 0x0430;     /* internal Vitesse PHY identifier */
    s->sata_ist = s->sata_im = 0;
    s->fe_booted = false;
    memset(s->fe_cmd, 0, sizeof(s->fe_cmd));
    memset(s->fe_msg, 0, sizeof(s->fe_msg));
    s->fe_msg_head = s->fe_msg_count = 0;
    s->fe_irq = 0;
    /* Default mask: bit16 set. The polled chk_int_ldr path never looks at the
     * mask, but the FE IRQ top half latches (0x5c804 & 0x5c800), so a zero
     * default discards every message it drains (fe-ata-cmd.md §0 defect #2).
     * port_start replaces this with 0xfffffff0 — which also keeps bit16. */
    s->fe_mask = FE_IRQ_MSG;
    s->fe_doorbell = 0;
    memset(s->fe_dma, 0, sizeof(s->fe_dma));
    memset(s->fe_csr, 0, sizeof(s->fe_csr));
    s->fe_dram_page = 0;
    s->sram_wptr = 0;
    s->sram_ridx = 0;
    memset(s->sram_fifo, 0, sizeof(s->sram_fifo));
    s->sata_cmd = 0;
    s->sata_st = 0;
    s->sata_didx = 0;
    s->sata_a604 = s->sata_a620 = s->sata_a634 = s->sata_a680 = 0;
    s->sata_a080 = s->sata_a114 = s->sata_a108 = 0;
    memset(s->tf, 0, sizeof(s->tf));
    mt8560_nfi_reset(&s->nfi);
    bx510_update_irq(s);
}

static void bx510_init(MachineState *machine)
{
    Bx510State *s = BX510_MACHINE(machine);
    DeviceState *l2;
    s->trace_all = getenv("BX510_TRACE") != NULL;
    Object *cpu = object_new(machine->cpu_type);
    qdev_realize(DEVICE(cpu), NULL, &error_fatal);
    s->irq = qdev_get_gpio_in(DEVICE(cpu), ARM_CPU_IRQ);
    s->tick = timer_new_ns(QEMU_CLOCK_VIRTUAL, bx510_tick, s);
    qemu_chr_fe_init(&s->uart, serial_hd(0), &error_fatal);
    qemu_chr_fe_set_handlers(&s->uart, bx510_uart_room, bx510_uart_receive,
                             NULL, NULL, s, NULL, true);
    memory_region_add_subregion(get_system_memory(), 0, machine->ram);
    /* MT8560 U-Boot defines the channel-A bus alias DRAMA_BASE at 0xc0000000. */
    memory_region_init_alias(&s->drama_alias, OBJECT(machine), "mt8560.dram-a",
                             machine->ram, 0, MIN(machine->ram_size, 256 * MiB));
    memory_region_add_subregion(get_system_memory(), 0xc0000000u, &s->drama_alias);
    memory_region_init_io(&s->io, OBJECT(machine), &bx510_ops, s,
                          "mt8560.peripherals", 0x1000000);
    memory_region_add_subregion(get_system_memory(), BX_IO_BASE, &s->io);
    mt8560_nfi_init(&s->nfi, OBJECT(machine), get_system_memory(),
                    qemu_allocate_irq(bx510_nfi_irq, s, 0));
    /* HDHOST: synthetic read-only host-image interface, instantiated only
     * when a host image is configured (-machine sony-bx510,hdhost=...).
     * Design and register contract: docs/large-image-interface.md. */
    if (s->hdhost_path && s->hdhost_path[0]) {
        mt8560_hdhost_init(&s->hdhost, OBJECT(machine), s->hdhost_path);
        memory_region_add_subregion_overlap(get_system_memory(),
                                             HDHOST_BASE, &s->hdhost.regs, 1);
    }
    l2 = qdev_new("l2x0");
    qdev_prop_set_uint32(l2, "cache-id", 0x41000080); /* ARM L220 */
    sysbus_realize_and_unref(SYS_BUS_DEVICE(l2), &error_fatal);
    sysbus_mmio_map(SYS_BUS_DEVICE(l2), 0, 0x50000000);
    /* SATA ATAPI drive (Feature 1): open the disc image if configured */
    if (s->sata_disc_path && s->sata_disc_path[0]) {
        Error *err = NULL;
        s->sata_blk = blk_new_open(s->sata_disc_path, NULL, NULL,
                                   0 /* read-only: no BDRV_O_RDWR */, &err);
        if (!s->sata_blk) {
            error_reportf_err(err, "bx510: cannot open sata-disc: ");
            exit(1);
        }
        s->sata_present = true;
        bx510_sata_build_identify(s);
        printf("bx510: SATA ATAPI drive attached: %s (%" PRIu64 " sectors)\n",
               s->sata_disc_path,
               (uint64_t)(blk_getlength(s->sata_blk) / 2048));
    }
    qemu_register_reset(bx510_reset, s);
    s->boot = (struct arm_boot_info) {
        .loader_start = 0,
        .board_id = 2000,
        .ram_size = machine->ram_size,
    };
    arm_load_kernel(ARM_CPU(cpu), machine, &s->boot);
}

static char *bx510_get_sata_disc(Object *obj, Error **errp)
{
    Bx510State *s = BX510_MACHINE(obj);
    return g_strdup(s->sata_disc_path ? s->sata_disc_path : "");
}

static void bx510_set_sata_disc(Object *obj, const char *value, Error **errp)
{
    Bx510State *s = BX510_MACHINE(obj);
    g_free(s->sata_disc_path);
    s->sata_disc_path = g_strdup(value);
}

static char *bx510_get_hdhost(Object *obj, Error **errp)
{
    return g_strdup(BX510_MACHINE(obj)->hdhost_path);
}

static void bx510_set_hdhost(Object *obj, const char *value, Error **errp)
{
    g_free(BX510_MACHINE(obj)->hdhost_path);
    BX510_MACHINE(obj)->hdhost_path = g_strdup(value);
}

static void bx510_class_init(ObjectClass *klass, void *data)
{
    MachineClass *mc = MACHINE_CLASS(klass);
    mc->desc = "Sony BDP-BX510 (MT8560, experimental)";
    object_class_property_add_str(klass, "hdhost", bx510_get_hdhost,
                                  bx510_set_hdhost);
    object_class_property_set_description(klass, "hdhost",
        "HDHOST synthetic read-only host-image path (see "
        "docs/large-image-interface.md)");
    object_class_property_add_str(klass, "sata-disc",
                                  bx510_get_sata_disc,
                                  bx510_set_sata_disc);
    object_class_property_set_description(klass, "sata-disc",
        "optical disc image for the emulated SATA ATAPI drive "
        "(raw 2048-byte sectors)");
    mc->init = bx510_init;
    mc->default_cpu_type = ARM_CPU_TYPE_NAME("arm1176");
    mc->default_ram_id = "bx510.ram";
    mc->default_ram_size = 512 * MiB;
    mc->default_cpus = mc->max_cpus = 1;
}

static const TypeInfo bx510_type = {
    .name = TYPE_BX510_MACHINE, .parent = TYPE_MACHINE,
    .instance_size = sizeof(Bx510State), .class_init = bx510_class_init,
};

static void bx510_register_types(void)
{
    type_register_static(&bx510_type);
}
type_init(bx510_register_types)
