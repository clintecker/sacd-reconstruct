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

#define TYPE_BX510_MACHINE MACHINE_TYPE_NAME("player.local")
OBJECT_DECLARE_SIMPLE_TYPE(Bx510State, BX510_MACHINE)

#define BX_IO_BASE 0x70000000u
#define BX_BIM     0x8000u
#define BX_UART    0xc000u
#define BX_T0_IRQ  (1u << 27)
#define BX_BUS_HZ  135000000u
#define BX_UART_TX_EMPTY (1u << 5)
#define BX_UART_RX_READY (1u << 7)
#define BX_UART_IRQ      (1u << 14)

struct Bx510State {
    MachineState parent_obj;
    struct arm_boot_info boot;
    MemoryRegion io, drama_alias;
    CharBackend uart;
    qemu_irq irq;
    Mt8560Nfi nfi;
    uint32_t mask2, pending2;
    QEMUTimer *tick;
    uint32_t pending, mask, reload, control, hsem;
    uint32_t uart_mode, uart_comm, uart_ien;
    bool uart_tx_event;
    uint8_t rx[64];
    unsigned rx_head, rx_count;
    uint32_t mac[64];
    uint16_t phy[32];
    int64_t tick_deadline;
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

static uint64_t bx510_read(void *opaque, hwaddr off, unsigned size)
{
    Bx510State *s = opaque;
    uint64_t ns;
    if (off >= 0x33000 && off < 0x33100) {
        return bx510_mac_read(s, off - 0x33000);
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
    default:
        qemu_log_mask(LOG_UNIMP, "bx510: unimplemented read 0x%" HWADDR_PRIx " (%u)\n",
                      off + BX_IO_BASE, size);
        return 0;
    }
}

static void bx510_write(void *opaque, hwaddr off, uint64_t val, unsigned size)
{
    Bx510State *s = opaque;
    uint8_t ch = val;
    if (off >= 0x33000 && off < 0x33100) {
        bx510_mac_write(s, off - 0x33000, val);
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
    case BX_BIM + 0x138: case BX_BIM + 0x140: break; /* level-sensitive NFI */
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
    default:
        qemu_log_mask(LOG_UNIMP, "bx510: unimplemented write 0x%" HWADDR_PRIx " = 0x%" PRIx64 " (%u)\n",
                      off + BX_IO_BASE, val, size);
    }
}

static const MemoryRegionOps bx510_ops = {
    .read = bx510_read, .write = bx510_write,
    .endianness = DEVICE_LITTLE_ENDIAN,
    .valid.min_access_size = 1, .valid.max_access_size = 4,
};

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
    mt8560_nfi_reset(&s->nfi);
    bx510_update_irq(s);
}

static void bx510_init(MachineState *machine)
{
    Bx510State *s = BX510_MACHINE(machine);
    DeviceState *l2;
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
                          "mt8560.peripherals", 0x400000);
    memory_region_add_subregion(get_system_memory(), BX_IO_BASE, &s->io);
    mt8560_nfi_init(&s->nfi, OBJECT(machine), get_system_memory(),
                    qemu_allocate_irq(bx510_nfi_irq, s, 0));
    l2 = qdev_new("l2x0");
    qdev_prop_set_uint32(l2, "cache-id", 0x41000080); /* ARM L220 */
    sysbus_realize_and_unref(SYS_BUS_DEVICE(l2), &error_fatal);
    sysbus_mmio_map(SYS_BUS_DEVICE(l2), 0, 0x50000000);
    qemu_register_reset(bx510_reset, s);
    s->boot = (struct arm_boot_info) {
        .loader_start = 0,
        .board_id = 2000,
        .ram_size = machine->ram_size,
    };
    arm_load_kernel(ARM_CPU(cpu), machine, &s->boot);
}

static void bx510_class_init(ObjectClass *klass, void *data)
{
    MachineClass *mc = MACHINE_CLASS(klass);
    mc->desc = "Sony BDP-BX510 (MT8560, experimental)";
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
