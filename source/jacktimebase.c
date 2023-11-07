#include "libjacktimebase/libjacktimebase.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

static int jack_process(jack_nframes_t nframes, void *arg)
{
    client_userdata_t *cli = (client_userdata_t*)arg;
    jack_position_t pos;
    jack_transport_state_t trans = jack_transport_query(cli->jack_client, &pos);
    memcpy(&(cli->pos), &pos, sizeof(jack_position_t));
    return 0;
}

static void jack_shutdown(void *arg)
{
    fprintf(stderr, "JACK shut down, exiting ...\n");
    exit(1);
}

const float PPQN = 1920.0;

float premul_ticks_bt(float bt)
{
    return 1 / (bt / 4) *  PPQN;
}

static void timebase(jack_transport_state_t state, jack_nframes_t nframes,
    jack_position_t *pos, int new_pos, void *arg)
{
    client_userdata_t *cli = (client_userdata_t*)arg;
    if (new_pos  || cli->userdata.time_reset) {  
        pos->valid = JackPositionBBT;
        pos->beats_per_bar = cli->userdata.time_beats_per_bar;
        pos->beat_type = cli->userdata.time_beat_type;
        pos->ticks_per_beat = premul_ticks_bt(pos->beat_type);
        pos->beats_per_minute = cli->userdata.time_beats_per_minute;
        
        float min = pos->frame / ((double) pos->frame_rate * 60.0);
        float abs_tick = min * pos->beats_per_minute * PPQN;
        float abs_beat = abs_tick / premul_ticks_bt(cli->userdata.time_beat_type);
        
        pos->beat = fmod(abs_beat, pos->beats_per_bar) + 1;
        pos->bar = (abs_beat / pos->beats_per_bar) + 1;
        pos->tick = (int32_t)fmod(abs_tick, premul_ticks_bt(pos->beat_type));
        pos->bar_start_tick = pos->bar * pos->beats_per_bar * premul_ticks_bt(pos->beat_type);
        
        cli->userdata.time_reset = 0;
    } else {
        float ticks_per_buffer = (nframes/((double) pos->frame_rate * 60.0)) * pos->beats_per_minute * PPQN;
        float temp = pos->tick + ticks_per_buffer;
        if (temp < premul_ticks_bt(pos->beat_type))
        {
            pos->tick += ticks_per_buffer;
        } else
        {
            unsigned beats = temp / premul_ticks_bt(pos->beat_type);
            for (unsigned b = 0; b < beats; b++) {
                temp -= premul_ticks_bt(pos->beat_type);
                if (++pos->beat > pos->beats_per_bar) {
                    pos->beat = 1;
                    ++pos->bar;
                    pos->bar_start_tick +=
                    pos->beats_per_bar
                    * premul_ticks_bt(pos->beat_type);
                }
            }
            pos->tick = temp;
        }
    }
}

// struct client_userdata {
//     struct transport_userdata {
//         double last_tick;
//         float time_beats_per_bar;
//         float time_beat_type;
//         double time_ticks_per_beat;
//         double time_beats_per_minute;
//         int time_reset;
//     } userdata;
//     jack_position_t pos;
//     jack_client_t *jack_client;
// };
// typedef struct client_userdata client_userdata_t;

client_userdata_t *client_open(const char* name)
{
    jack_status_t status;
    jack_client_t *client;
    client = jack_client_open(name, JackNullOption, &status);
    if (client == NULL) {
        fprintf (stderr, "jack_client_open() failed, "
        "status = 0x%2.0x\n", status);
        return NULL;
    }
    client_userdata_t *cli = malloc(sizeof(client_userdata_t));
    
    cli->userdata.time_beats_per_bar = 4.0;
    cli->userdata.time_beat_type = 4.0;
    cli->userdata.time_beats_per_minute = 120.0;
    cli->userdata.time_reset = 1;
    
    cli->jack_client = client;
    
    jack_set_process_callback(client, jack_process, cli);
    jack_on_shutdown(client, jack_shutdown, cli);
    
    if (jack_activate(client)) {
        fprintf(stderr, "cannot activate client");
        return NULL;
    }
    
    return cli;
}

int transport_start_timebase(client_userdata_t *client, int conditional)
{   
    int ret;
    if (ret = jack_set_timebase_callback(client->jack_client, conditional, timebase, client) != 0)
        fprintf(stderr, "Unable to take over timebase.\n");
    return ret;
}

void transport_release_timebase(client_userdata_t *client)
{
	jack_release_timebase(client->jack_client);
}

void client_close(client_userdata_t *client)
{
    if (client != NULL)
        jack_client_close(client->jack_client);
}

void transport_play(client_userdata_t *client)
{
    jack_transport_start(client->jack_client);
}

void transport_stop(client_userdata_t *client)
{
    jack_transport_stop(client->jack_client);
}

/* Toggle between play and stop state */
void transport_toggle(client_userdata_t *client)
{
    jack_position_t current;
    jack_transport_state_t transport_state;
    
    transport_state = jack_transport_query (client->jack_client, &current);
    
    switch (transport_state) {
        case JackTransportStopped:
            transport_play(client);
            break;
        case JackTransportRolling:
            transport_stop(client);
            break;
        case JackTransportStarting:
            fprintf(stderr, "state: Starting - no transport toggling");
            break;
        default:
            fprintf(stderr, "unexpected state: no transport toggling");
    }
}

void transport_locate(client_userdata_t *client, jack_nframes_t frame)
{
	jack_transport_locate(client->jack_client, frame);
}

void transport_tb_set_tempo(client_userdata_t *client, float tempo)
{
    client->userdata.time_beats_per_minute = tempo;
    client->userdata.time_reset = 1;
}
