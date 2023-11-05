local ffi = require "ffi"
ffi.cdef[[
typedef uint64_t jack_unique_t; 
typedef uint64_t jack_time_t;
typedef uint32_t jack_nframes_t;
typedef enum {
    JackPositionBBT      = 0x10,
    JackPositionTimecode = 0x20,
    JackBBTFrameOffset   = 0x40,
    JackAudioVideoRatio  = 0x80,
    JackVideoFrameOffset = 0x100,
    JackTickDouble       = 0x200,
} jack_position_bits_t;
typedef struct {
    jack_unique_t       unique_1;       
    jack_time_t         usecs;          
    jack_nframes_t      frame_rate;     
    jack_nframes_t      frame;          
    jack_position_bits_t valid;         
    int32_t             bar;            
    int32_t             beat;           
    int32_t             tick;           
    double              bar_start_tick;
    float               beats_per_bar;  
    float               beat_type;      
    double              ticks_per_beat;
    double              beats_per_minute;
    double              frame_time;     
    double              next_time;      
    jack_nframes_t      bbt_offset;     
    float               audio_frames_per_video_frame; 
    jack_nframes_t      video_offset;   
    double              tick_double; 
    int32_t             padding[5];
    jack_unique_t       unique_2;
} jack_position_t;
typedef struct {} jack_client_t;
typedef struct {
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
} client_userdata_t;

client_userdata_t* client_open(const char* name);

void client_close(client_userdata_t*);

jack_position_t client_get_position(client_userdata_t *client);

void transport_play(client_userdata_t*);
void transport_stop(client_userdata_t*);
void transport_toggle(client_userdata_t*);
void transport_locate(client_userdata_t *client, jack_nframes_t frame);

int transport_start_timebase(client_userdata_t *client, int conditional);
void transport_release_timebase(client_userdata_t *client);
void transport_tb_set_tempo(client_userdata_t *client, int tempo);

const char* exported_function(void);
const void exported_function2();
]]

local clib = ffi.load("libjacktimebase")
local inspect = require("inspect")

jack_client = {}

function jack_client:new(name)
    local cli = clib.client_open(ffi.new("const char*", name))
    jack_client = {
        client_name = name,
        client_ptr = cli
    }
    self.__index = self
    return setmetatable(jack_client, self)
end

function jack_client:print_name()
    print(self.client_name)
end

function jack_client:toggle()
    clib.transport_toggle(self.client_ptr)
end

function jack_client:play()
    clib.transport_play(self.client_ptr)
end

function jack_client:stop(reset)
    clib.transport_stop(self.client_ptr)
    if reset == true then
        self:locate()
    end
end

function jack_client:locate(frame)
    clib.transport_locate(self.client_ptr, frame ~= nil and frame or 0)
end

function jack_client:close()
    clib.client_close(self.client_ptr)
end

function jack_client:current_position()
    return self.client_ptr.pos
end

function jack_client:start_timebase(conditional)
    return clib.transport_start_timebase(self.client_ptr, conditional == true and 1 or 0)
end

function jack_client:release_timebase()
    return clib.transport_release_timebase(self.client_ptr)
end

function jack_client:set_tempo(tempo)
    return clib.transport_tb_set_tempo(self.client_ptr, tempo)
end

return setmetatable({}, {
    __call = function (tbl, ...)
        return jack_client:new(...)
    end
})