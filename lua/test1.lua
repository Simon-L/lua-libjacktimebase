local app = require"pl.app"
local nocurses = require("nocurses")

app.require_here()
local jtb = require"libjacktimebase"

local cli = jtb("libjacktimebase")
-- cli:print_name()
cli:stop(true)
cli:play()
cli:start_timebase(true)
local last_beat = 0
local last_bar = 0
local w, h = nocurses.gettermsize()
print""
print""
print""

repeat
    local pos = cli:current_position()
    if (pos.beat ~= last_beat) or (pos.bar ~= last_bar) then
        nocurses.clrline()
        nocurses.gotoxy(0,h-2)
        print("Bar:", pos.bar, "Beat:", pos.beat .. "/" .. pos.beats_per_bar, "Beat type:", pos.beat_type, "BPM:", pos.beats_per_minute)
    end
    last_bar = pos.bar
    last_beat = pos.beat
    q = nocurses.getch(0.1)
until q ~= nil

cli:release_timebase()
cli:stop()
cli:close()

