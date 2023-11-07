local ffi = require"ffi"
local app = require"pl.app"
local app_path = app.require_here()
app.require_here("lua")

local inspect = require"inspect"
local sdl = require"sdl2_ffi"
local gllib = require"gl"
local ig = require"imgui.sdl"


gllib.set_loader(sdl)
local gl, glc, glu, glext = gllib.libraries()

function sdl_init(flags)
    if (sdl.init(flags) ~= 0) then
        print(string.format("Error: %s\n", sdl.getError()));
        return -1;
    end
    return 0
end

function sdl_setup()
    sdl.gL_SetAttribute(sdl.GL_CONTEXT_PROFILE_MASK, sdl.GL_CONTEXT_PROFILE_CORE);
    sdl.gL_SetAttribute(sdl.GL_DOUBLEBUFFER, 1);
    sdl.gL_SetAttribute(sdl.GL_DEPTH_SIZE, 24);
    sdl.gL_SetAttribute(sdl.GL_STENCIL_SIZE, 8);
    sdl.gL_SetAttribute(sdl.GL_CONTEXT_MAJOR_VERSION, 3);
    sdl.gL_SetAttribute(sdl.GL_CONTEXT_MINOR_VERSION, 1);
    local current = ffi.new("SDL_DisplayMode[1]")
    sdl.getCurrentDisplayMode(0, current);
    local window = sdl.createWindow("JACK Timebase", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 400, 150, sdl.WINDOW_OPENGL+sdl.WINDOW_RESIZABLE); 
    local gl_context = sdl.gL_CreateContext(window);
    sdl.gL_SetSwapInterval(1); -- Enable vsync
    return window, gl_context
end

function imgui_init()
    local ig_Impl = ig.Imgui_Impl_SDL_opengl3()
    ig_Impl:Init(window, gl_context)
    return ig_Impl
end

sdl_init(sdl.INIT_VIDEO+sdl.INIT_TIMER)
window, gl_context = sdl_setup()
sdl.SetWindowBordered(window, sdl.SDL_FALSE)
ig_Impl = imgui_init()

local igio = ig.GetIO()
-- ig.ImPlot_CreateContext()

local jtb = require"libjacktimebase"
local cli = jtb("libjacktimebase")
cli:start_timebase(true)

local beats = ffi.new("int[1]", 4)
local beat_type = ffi.new("int[1]",4)

local done = false;
local showdemo = ffi.new("bool[1]",false)
while (not done) do
    
    --SDL_Event 
    local event = ffi.new"SDL_Event"
    while (sdl.pollEvent(event) ~=0) do
        ig.lib.ImGui_ImplSDL2_ProcessEvent(event);
        if (event.type == sdl.KEYUP) and (event.key.keysym.sym == sdl.SDLK_ESCAPE) then
            done = true;
        end
        if (event.type == sdl.QUIT) then
            done = true;
        end
        if (event.type == sdl.WINDOWEVENT and event.window.event == sdl.WINDOWEVENT_CLOSE and event.window.windowID == sdl.getWindowID(window)) then
            done = true;
        end
    end
    
    --standard rendering
    sdl.gL_MakeCurrent(window, gl_context);
    gl.glViewport(0, 0, igio.DisplaySize.x, igio.DisplaySize.y);
    gl.glClear(glc.GL_COLOR_BUFFER_BIT)
    
    ig_Impl:NewFrame()
    
    -- ImGui    
    ig.SetNextWindowPos(ig.ImVec2(0,0))
    ig.SetNextWindowSize(ig.ImVec2(igio.DisplaySize.x, igio.DisplaySize.y))
    ig.Begin("JACK Timebase", nil, ig.lib.ImGuiWindowFlags_NoTitleBar+ig.lib.ImGuiWindowFlags_NoCollapse+ig.lib.ImGuiWindowFlags_NoResize+ig.lib.ImGuiWindowFlags_NoMove)
    
    -- ig.Checkbox("Show demo window", showdemo)
    -- if showdemo[0] == true then
    --     ig.ShowDemoWindow(showdemo)
    -- end
    
    local pos = cli:current_position()
    ig.Text(string.format("%3d", pos.bar) .. "|" .. string.format("%2d", pos.beat) .. "|" .. string.format("%04d", pos.tick) .. "\tTime signature: " .. pos.beats_per_bar .. "/" .. pos.beat_type)
    
    if (ig.InputInt("Beats per bar", beats)) then
        cli:set_beats_per_bar(beats[0])
    end
    
    if (ig.RadioButton("Whole", beat_type[0] == 1)) then
        beat_type[0] = 1
        cli:set_beat_type(beat_type[0])
    end
    ig.SameLine()
    if (ig.RadioButton("Half", beat_type[0] == 2)) then
        beat_type[0] = 2
        cli:set_beat_type(beat_type[0])
    end
    ig.SameLine()
    if (ig.RadioButton("Quarter", beat_type[0] == 4)) then
        beat_type[0] = 4
        cli:set_beat_type(beat_type[0])
    end
    ig.SameLine()
    if (ig.RadioButton("8th", beat_type[0] == 8)) then
        beat_type[0] = 8
        cli:set_beat_type(beat_type[0])
    end
    ig.SameLine()
    if (ig.RadioButton("16th", beat_type[0] == 16)) then
        beat_type[0] = 16
        cli:set_beat_type(beat_type[0])
    end
    
    if (ig.Button("Play")) then
        cli:play()
    end
    ig.SameLine()
    if (ig.Button("Pause")) then
        cli:stop()
    end
    ig.SameLine()
    if (ig.Button("Stop")) then
        cli:stop(true)
    end
    
    
    if (ig.Button("Quit")) then
        done = true
    end
    
    ig.End()
    
    --standard rendering
    ig_Impl:Render()
    sdl.gL_SwapWindow(window);
end

cli:release_timebase()
cli:stop()
cli:close()

-- Cleanup
ig_Impl:destroy()

sdl.gL_DeleteContext(gl_context);
sdl.destroyWindow(window);
sdl.quit();
