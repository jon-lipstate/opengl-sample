package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:mem"
import "core:log"
import "core:runtime"
import "core:intrinsics"
import glm "core:math/linalg/glsl"
import imgui "./vendor/odin-imgui"
import imgl "./vendor/odin-imgui/impl/opengl"
import imglfw "./vendor/odin-imgui/impl/glfw"
import "./demos"
import "./renderer"
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
// MAIN
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
main :: proc() {
	context.logger = get_logger()

	if !bool(glfw.Init()) {
		desc, err := glfw.GetError()
		log.error("GLFW init failed:", err, desc)
		return
	}
	defer glfw.Terminate()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.DOUBLEBUFFER, 1)
	glfw.WindowHint(glfw.DEPTH_BITS, 24)
	glfw.WindowHint(glfw.STENCIL_BITS, 8)
	window := glfw.CreateWindow(960, 540, "OpenGL Sample", nil, nil)
	if window == nil {
		desc, err := glfw.GetError()
		log.error("GLFW window creation failed:", err, desc)
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.SetErrorCallback(error_callback)
	glfw.SetKeyCallback(window, key_callback)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1)

	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	gl.ClearColor(0.25, 0.25, 0.25, 1)
	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)

	imgui_state := init_imgui_state(window)
	io := imgui.get_io()
	//
	menu := demos.Demo_Menu{}
	current_demo: demos.Demo = &menu
	menu.current_demo = &current_demo
	defer demos.destroy(current_demo)

	for !glfw.WindowShouldClose(window) {
		gl.ClearColor(0, 0, 0, 1)
		renderer.clear(nil)
		imgui_new_frame()
		imgui.new_frame()
		{
			using demos

			demos.on_update(current_demo, 0.)
			demos.on_render(current_demo)

			imgui.begin("Demos")
			if _, ok := current_demo.(^Demo_Menu); !ok && imgui.button("<-") {
				destroy(current_demo)
				current_demo = &menu
			}
			on_imgui_render(current_demo)
			imgui.end()
		}
		imgui.render()

		imgl.imgui_render(imgui.get_draw_data(), imgui_state.opengl_state)
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
init_glfw :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		os.exit(1)
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.DOUBLEBUFFER, 1)
	glfw.WindowHint(glfw.DEPTH_BITS, 24)
	glfw.WindowHint(glfw.STENCIL_BITS, 8)
	window := glfw.CreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "OpenGL", nil, nil)
	if window == nil {
		glfw.Terminate()
		os.exit(1)
	}
	// odin ignores these..?

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1) // v-sync
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)
	fmt.println(gl.GetString(GL_VERSION))
	fmt.println(gl.GetString(GL_RENDERER))
	return window
}
destroy_glfw :: proc(window: glfw.WindowHandle) {
	glfw.DestroyWindow(window)
	glfw.Terminate()
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

get_logger :: proc() -> log.Logger {
	logger_opts := log.Options{.Level, .Line, .Procedure}
	return log.create_console_logger(opt = logger_opts)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	context = runtime.default_context()

	if action == glfw.PRESS {
		switch key {
		case glfw.KEY_ESCAPE:
			glfw.SetWindowShouldClose(window, true)
		case glfw.KEY_TAB:
			io := imgui.get_io()
			if io.want_capture_keyboard == false {}
		}
	}
}

error_callback :: proc "c" (error: i32, description: cstring) {
	context = runtime.default_context()
	context.logger = get_logger()
	log.error("GLFW error:", error, description)
}
