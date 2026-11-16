/*
 * hud.c — the ONE HUD, running inside the daemon (see docs/HUD.md,
 * "Architecture: where the HUD lives").
 *
 * Doctrine (binding, operator 2026-11-16): one HUD, built into
 * sacd_extract_160, showing the daemon's own internal state — clients,
 * ripping progress, disc stats. This file is that HUD. It reads
 * hud_state_copy() (the daemon publishes at its 1 Hz heartbeat and in the
 * DISC_READ dispatch) and renders at its own pace.
 *
 * Modes (--hud=):
 *   console — one status line per tick on stdout; the honest, testable
 *             observables for the guest gates (the UART transcript carries
 *             it; a gate asserts counters MOVE, never eyeballs them).
 *   panel   — the framebuffer render. The renderer core is the proven
 *             sacd_hud path (pool-mmap render); its integration into this
 *             thread is the next ladder rung (unit -> SIM -> guest).
 *
 * NOTE ON STDOUT ORIENTATION: main() calls fwide(stdout, 1) before the
 * server loop, so stdout is WIDE-oriented; narrow printf() on it silently
 * fails (proven 2026-11-16: the first guest fire showed the status line but
 * no HUD output — the thread rendered into a stream that rejected narrow
 * writes). Everything here prints through fwprintf, like the daemon's own
 * status line (safe_fwprintf).
 *
 * The thread is created from main() when opts.hud_mode != HUD_NONE and the
 * daemon is in server mode. Parity safety: everything here is compiled
 * only under -DENABLE_HUD.
 */
#ifdef ENABLE_HUD

#include <stdio.h>
#include <wchar.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include "hud_state.h"
#include "hud.h"

static int hud_mode;
static volatile int hud_stop;

static const char *hud_mode_name(int m)
{
    return m == HUD_PANEL ? "panel" : "console";
}

static void hud_console_render(const hud_state_t *s)
{
    if (!s->disc_loaded)
    {
        fwprintf(stdout, L"HUD disc=none client=%ls reads=%llu sectors=%llu\n",
                 s->client_connected ? L"CONNECTED" : L"idle",
                 (unsigned long long)s->reads_served,
                 (unsigned long long)s->sectors_served);
    }
    else
    {
        unsigned pct = s->total_sectors
            ? (unsigned)((s->max_lsn_served * 100ULL) / s->total_sectors)
            : 0;
        fwprintf(stdout, L"HUD disc=%ls %u/%u sectors (%u%%) client=%ls "
                 L"reads=%llu enc=%llu rate=%.2fMB/s eta=%us last=%u+%u\n",
                 s->is_sacd ? L"sacd" : L"disc",
                 (unsigned)s->max_lsn_served, (unsigned)s->total_sectors, pct,
                 s->client_connected ? L"CONNECTED" : L"idle",
                 (unsigned long long)s->reads_served,
                 (unsigned long long)s->encrypted_sectors,
                 s->mbs_per_sec, s->eta_seconds,
                 (unsigned)s->last_lsn, (unsigned)s->last_count);
    }
    fflush(stdout);
}

#ifdef HUD_PANEL_RENDERER
/* the panel renderer core (tools/bx510_sacd_hud.c compiled with
 * -DHUD_IN_DAEMON) — declared here, defined there */
int  hud_panel_init(const char *pool_dev, const char *font_path);
void hud_panel_tick(const hud_state_t *st, double t, unsigned frame);
#endif

static void *hud_thread(void *unused)
{
    (void)unused;
    hud_state_t snap;
    memset(&snap, 0, sizeof snap);
    double t = 0.0;
    unsigned frame = 0;

#ifdef HUD_PANEL_RENDERER
    if (hud_mode == HUD_PANEL)
    {
        const char *pool = getenv("HUD_POOL_DEV");
        const char *font = getenv("HUD_FONT");
        if (hud_panel_init(pool, font) != 0)
        {
            fwprintf(stderr, L"HUD: panel init failed — falling back to console\n");
            hud_mode = HUD_CONSOLE;
        }
        else
        {
            fwprintf(stdout, L"HUD: panel renderer live (pool-mmap, in-daemon)\n");
            fflush(stdout);
        }
    }
#endif

    while (!hud_stop)
    {
        if (hud_state_copy(&snap))
        {
            hud_state_tick(&snap);
            if (hud_mode == HUD_PANEL)
            {
#ifdef HUD_PANEL_RENDERER
                t += 0.5;
                hud_panel_tick(&snap, t, frame++);
#endif
            }
            else
            {
                hud_console_render(&snap);
            }
        }
        sleep(1);
    }
    return NULL;
}

/* returns 0 on success; called from main() after option parsing */
int hud_start(int mode)
{
    pthread_t t;
    hud_mode = mode;
    if (pthread_create(&t, NULL, hud_thread, NULL) != 0)
        return -1;
    pthread_detach(t);
    fwprintf(stdout, L"HUD: started, mode=%hs (in-daemon, one binary)\n",
             hud_mode_name(mode));
    fflush(stdout);
    return 0;
}

void hud_stop_request(void)
{
    hud_stop = 1;
}

#endif /* ENABLE_HUD */
