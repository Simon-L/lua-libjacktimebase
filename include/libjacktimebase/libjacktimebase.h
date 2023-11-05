#pragma once

#include <jack/jack.h>
#include <jack/transport.h>

#include "libjacktimebase/libjacktimebase_export.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Time and tempo variables.  These are global to the entire,
* transport timeline.  There is no attempt to keep a true tempo map.
* The default time signature is: "march time", 4/4, 120bpm
*/

LIBJACKTIMEBASE_EXPORT struct client_userdata {
    struct transport_userdata {
        double last_tick;
        float time_beats_per_bar;
        float time_beat_type;
        double time_ticks_per_beat;
        double time_beats_per_minute;
        int time_reset;
    } userdata;
    jack_position_t pos;
    jack_client_t *jack_client;
};
typedef struct client_userdata client_userdata_t;

LIBJACKTIMEBASE_EXPORT client_userdata_t *client_open(const char* name);
LIBJACKTIMEBASE_EXPORT void client_close(client_userdata_t *client);
LIBJACKTIMEBASE_EXPORT void transport_play(client_userdata_t *client);
LIBJACKTIMEBASE_EXPORT void transport_stop(client_userdata_t *client);
LIBJACKTIMEBASE_EXPORT void transport_toggle(client_userdata_t *client);
LIBJACKTIMEBASE_EXPORT void transport_locate(client_userdata_t *client, jack_nframes_t frame);
LIBJACKTIMEBASE_EXPORT int transport_start_timebase(client_userdata_t *client, int conditional);
LIBJACKTIMEBASE_EXPORT void transport_release_timebase(client_userdata_t *client);
LIBJACKTIMEBASE_EXPORT void transport_tb_set_tempo(client_userdata_t *client, int tempo);

#ifdef __cplusplus
}  // extern "C"
#endif
