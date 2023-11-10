local ffi = require"ffi"
local app = require"pl.app"
local app_path = app.require_here()
app.require_here("lua")
flags,args = app.parse_args()

local inspect = require"inspect"
local sdl = require"sdl2_ffi"
local gllib = require"gl"
cimguimodule = (flags.cimguimodule ~= nil) and flags.cimguimodule or nil
local ig = require"imgui.sdl"

jacktimebasemodule = (flags.jacktimebasemodule ~= nil) and flags.jacktimebasemodule or nil
local jtb = require"libjacktimebase"

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
    local window = sdl.createWindow("JACK Timebase", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 410, 110, sdl.WINDOW_OPENGL+sdl.WINDOW_RESIZABLE); 
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

local cli = jtb("libjacktimebase")
cli:start_timebase(true)

local beats = ffi.new("int[1]", 4)
local beat_type = ffi.new("int[1]",2)
local tempo = ffi.new("float[1]",120.0)

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
        if (event.type == sdl.KEYUP) and (event.key.keysym.sym == sdl.SDLK_SPACE) then
            cli:toggle()
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
    ig.Text("BBT: " .. string.format("%3d", pos.bar) .. "|" .. string.format("%2d", pos.beat) .. "|" .. string.format("%04d", pos.tick) .. "  " .. string.format("%2d  / %2d", beats[0], math.pow(2, beat_type[0])) .. "\t")
    ig.SameLine()
    ig.SetNextItemWidth(igio.DisplaySize.x/3);
    if (ig.SliderFloat("BPM", tempo, 10.0, 400)) then
        cli:set_tempo(tempo[0])
    end
    
    ig.SetNextItemWidth(igio.DisplaySize.x/4);
    if (ig.InputInt("Beats per bar", beats)) then
        if beats[0] < 1 then beats[0] = 1 end
        if beats[0] > 99 then beats[0] = 99 end
        cli:set_beats_per_bar(beats[0])
    end
    ig.SameLine()
    ig.SetNextItemWidth(igio.DisplaySize.x/4);
    if (ig.SliderInt("Beat type", beat_type, 0, 4, ffi.string(string.format("%d", math.pow(2, beat_type[0]))))) then
        cli:set_beat_type(math.pow(2, beat_type[0]))
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
