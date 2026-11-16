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

#define HUD_STATE_VER      2
#define HUD_LABEL_MAX      64

/* ---- TOC snapshot (v2) ---------------------------------------------------
   The disc console scene (sacd_ui layout merged into the HUD) needs the
   parsed TOC, not just rip progress. The daemon publishes it at DISC_OPEN,
   straight out of the scarletbook handle it already parsed for serving.
   Fixed-size: at most HUD_TOC_TRACKS tracks are stored per area; the real
   total travels in track_count so the scene can say '+N more' honestly. */
#define HUD_TOC_AREAS      2
#define HUD_TOC_TRACKS     8
#define HUD_EVENT_MAX      8
#define HUD_EVENT_TEXT     48

typedef struct hud_track
{
    uint32_t lsn;               /* track_start_lsn[t] */
    uint32_t len;               /* track_length_lsn[t] */
    uint8_t  sm, ss, sf;        /* start time MSF */
    uint8_t  dm, ds, df;        /* duration MSF */
} hud_track_t;

typedef struct hud_area
{
    uint8_t    present;         /* area_toc parsed for this area */
    uint8_t    channels;
    uint8_t    track_count;     /* REAL total (may exceed HUD_TOC_TRACKS) */
    uint32_t   lsn_start, lsn_end;
    hud_track_t track[HUD_TOC_TRACKS];
} hud_area_t;

typedef struct hud_event
{
    time_t   at;                /* wall clock of the transition */
    char     text[HUD_EVENT_TEXT];
} hud_event_t;

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

    /* TOC snapshot (v2, published at DISC_OPEN from the parsed handle) */
    uint8_t  toc_valid;         /* 0 = no parsed TOC to show */
    uint8_t  nareas;
    char     disc_cat[16];      /* disc_catalog_number */
    uint16_t disc_year;         /* master_toc disc_date */
    uint8_t  disc_month;
    uint8_t  disc_day;
    char     album[HUD_LABEL_MAX];
    char     artist[HUD_LABEL_MAX];
    hud_area_t area[HUD_TOC_AREAS];

    /* event ring (newest last; daemon-side transitions only — the renderer
       keeps its own observation ring for per-request chatter) */
    uint8_t  ev_head;           /* next write slot */
    uint8_t  ev_count;          /* valid entries, capped at HUD_EVENT_MAX */
    hud_event_t ev[HUD_EVENT_MAX];

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

/* Append one transition event to the snapshot's ring BEFORE publishing.
 * Call on the copy you are about to publish (connect/disconnect, disc
 * open/close). No-ops when ENABLE_HUD is off. */
void hud_state_event(hud_state_t *s, const char *fmt, ...);

/* The HUD thread's copy helper: snapshot-out under the lock. Returns 0 if
 * no snapshot has been published yet. */
int hud_state_copy(hud_state_t *out);

/* Advance the derived fields (rate, ETA) from the last two published
 * snapshots. Called by the HUD thread on its render tick. */
void hud_state_tick(hud_state_t *inout);

#endif /* HUD_STATE_H */
