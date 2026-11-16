/* hud.h — the ONE HUD, in-daemon (see hud.c). Compiled only under -DENABLE_HUD. */
#ifndef HUD_H
#define HUD_H
#ifdef ENABLE_HUD
enum { HUD_CONSOLE = 1, HUD_PANEL = 2 };
int  hud_start(int mode);
void hud_stop_request(void);
#endif
#endif
