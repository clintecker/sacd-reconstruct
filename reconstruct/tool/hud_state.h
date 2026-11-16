/*
 * hud_state.h — the ONE HUD's in-daemon state feed (see docs/HUD.md,
 * "Architecture: where the HUD lives").
 *
 * Doctrine (binding, set by the operator 2026-11-16): there is exactly ONE
 * HUD and its target architecture is BUILT INTO the reconstructed daemon.
 * This header is the seam that makes that possible without perturbing the
 * parity build: the HUD layer is compiled only with -DENABLE_HUD, and the
 * daemon publishes its state through this struct at its existing 1 Hz
 * server_loop heartbeat.
 *
 * The HUD thread (hud.c) reads this snapshot under hud_state_lock. Writers
 * are the daemon's own paths (client_thread request dispatch, server_loop
 * heartbeat). Nothing here allocates; the strings are fixed-length.
 */
#ifndef HUD_STATE_H
#define HUD_STATE_H

#include <stdint.h>
#include <time.h>

#define HUD_STATE_VER      1
#define HUD_LABEL_MAX      64

typedef struct hud_state
{
    uint32_t ver;               /* HUD_STATE_VER */

    /* daemon identity */
    char     version[16];       /* "0.37" */

    /* disc state (from the daemon's own handle, set on DISC_OPEN) */
    int      disc_loaded;       /* 0 = tray empty / never opened */
    int      is_sacd;           /* 0 = non-SACD disc */
    int      is_encrypted;      /* any encrypted range on this disc */
    uint32_t total_sectors;     /* sacd_get_total_sectors() */
    char     disc_label[HUD_LABEL_MAX];   /* album/catalog text, best-effort */

    /* client/session state (from client_thread) */
    int      client_connected;  /* the daemon's single accept slot */
    char     client_peer[64];   /* "127.0.0.1" or the last peer text */

    /* rip progress (accumulated in the DISC_READ dispatch path) */
    uint64_t reads_served;      /* DISC_READ requests answered */
    uint64_t sectors_served;    /* sum of response.result */
    uint64_t encrypted_sectors; /* subset that went through DECRYPT */
    uint32_t last_lsn;          /* last sector_offset served */
    uint32_t last_count;        /* last block_size served */
    uint32_t max_lsn_served;    /* high-water mark = progress against total */

    /* rate (computed by hud_state_tick, not the dispatch path) */
    double   mbs_per_sec;       /* rolling sectors_served delta -> MB/s */
    uint32_t eta_seconds;       /* remaining at current rate, 0 = unknown */

    /* heartbeat */
    time_t   updated_at;        /* last hud_state_tick */
} hud_state_t;

/* Publish a fresh snapshot. Callers: server_loop (1 Hz heartbeat) and the
 * DISC_READ dispatch (progress). Lock-free enough: a single writer at a
 * time under the daemon's existing request serialization; the HUD reader
 * copies under hud_state_lock (a plain pthread_mutex in hud.c). */
void hud_state_publish(const hud_state_t *snapshot);

/* The HUD thread's copy helper: snapshot-out under the lock. Returns 0 if
 * no snapshot has been published yet. */
int hud_state_copy(hud_state_t *out);

/* Advance the derived fields (rate, ETA) from the last two published
 * snapshots. Called by the HUD thread on its render tick. */
void hud_state_tick(hud_state_t *inout);

#endif /* HUD_STATE_H */
