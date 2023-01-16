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
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540
SHOW_DEMO_WINDOW := true
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

	imgui_state := init_imgui_state(window)
	io := imgui.get_io()
	//
	//
	positions := []f32{10., 10., 0., 0., 300., 10., 1., 0., 300., 300., 1., 1., 10., 300., 0., 1.}
	indices := []u32{0, 1, 2, 2, 3, 0}

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	va := make_vertex_array()
	vb := make_vertex_buffer(positions)
	vl := make_vertex_layout()
	vl->push_type(f32, 2, false)
	vl->push_type(f32, 2, false)
	va->add_buffer(&vb, &vl)
	ib := make_index_buffer(indices)
	// Projection moves into unit-screen space
	proj := glm.mat4Ortho3d(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT, -1., 1.)
	// Camera 
	view := glm.mat4Translate(glm.vec3{-100, 0, 0}) // move camera to left 100px
	shader := make_shader_program()
	set_uniform4f(&shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.})

	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)
	texture := make_texture("./ChernoLogo.png")
	texture->bind()
	set_uniform1i(&shader, "u_Texture", 0)

	va->unbind() //clears the state (debug / demo use only...?):
	vb->unbind()
	ib->unbind()
	shader->unbind()
	//
	//
	x: f32 = 200
	y: f32 = 200
	for !glfw.WindowShouldClose(window) {
		clear(nil)
		imgui_new_frame()
		imgui.new_frame()
		{
			slider_window(&x, &y)
		}
		imgui.render()

		// gl.Viewport(0, 0, i32(io.display_size.x), i32(io.display_size.y))
		// gl.Scissor(0, 0, i32(io.display_size.x), i32(io.display_size.y))
		model := glm.mat4Translate(glm.vec3{x, y, 0})
		mvp := proj * view * model
		shader->bind()
		// // set_uniform4f(&shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.}) // replaced with texColor in shader
		set_uniform_mat4f(&shader, "u_MVP", &mvp)
		draw(nil, &va, &ib, &shader)
		imgl.imgui_render(imgui.get_draw_data(), imgui_state.opengl_state)
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteProgram(shader.id)
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
			if io.want_capture_keyboard == false {
				SHOW_DEMO_WINDOW = true
			}
		}
	}
}

error_callback :: proc "c" (error: i32, description: cstring) {
	context = runtime.default_context()
	context.logger = get_logger()
	log.error("GLFW error:", error, description)
}

dbg_assert :: #force_inline proc(flag: bool) {
	if !flag do intrinsics.debug_trap()
}
