/*
 * hud_state.c — the ONE HUD's in-daemon state store (see hud_state.h).
 *
 * Single global snapshot + one mutex. Writers: the daemon's own paths.
 * Reader: the HUD thread. With -DENABLE_HUD undefined this translation
 * unit compiles to nothing and the daemon's parity build is untouched.
 */
#ifdef ENABLE_HUD

#include "hud_state.h"
#include <pthread.h>
#include <string.h>
#include <stdio.h>

static hud_state_t hud_state;
static pthread_mutex_t hud_state_lock = PTHREAD_MUTEX_INITIALIZER;
static int hud_state_ready;

void hud_state_publish(const hud_state_t *snapshot)
{
    pthread_mutex_lock(&hud_state_lock);
    hud_state = *snapshot;
    hud_state_ready = 1;
    pthread_mutex_unlock(&hud_state_lock);
}

int hud_state_copy(hud_state_t *out)
{
    pthread_mutex_lock(&hud_state_lock);
    if (!hud_state_ready)
    {
        pthread_mutex_unlock(&hud_state_lock);
        return 0;
    }
    *out = hud_state;
    pthread_mutex_unlock(&hud_state_lock);
    return 1;
}

/* rate window: compare against the previous tick's counters */
static uint64_t prev_sectors;
static time_t   prev_time;

void hud_state_tick(hud_state_t *s)
{
    time_t now = time(NULL);
    if (prev_time != 0 && now > prev_time)
    {
        double dt = (double)(now - prev_time);
        double mbs = (double)(s->sectors_served - prev_sectors) * 2048.0
                     / (1048576.0 * dt);
        /* smooth lightly so a single burst doesn't spike the readout */
        s->mbs_per_sec = (s->mbs_per_sec * 0.5) + (mbs * 0.5);
        if (s->total_sectors > 0 && s->max_lsn_served < s->total_sectors)
        {
            uint64_t remaining = s->total_sectors - s->max_lsn_served;
            if (mbs > 0.01)
                s->eta_seconds = (uint32_t)((double)remaining * 2048.0
                                            / (mbs * 1048576.0));
        }
    }
    prev_sectors = s->sectors_served;
    prev_time = now;
    s->updated_at = now;
}

#endif /* ENABLE_HUD */
