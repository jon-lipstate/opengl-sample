package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:runtime"
import "core:intrinsics"
import glm "core:math/linalg/glsl"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 540

init_glfw :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		os.exit(1)
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE) // compat makes vtx buf for you, core does not

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

main :: proc() {
	window := init_glfw()
	defer destroy_glfw(window)

	positions := []f32{100., 100., 0., 0., 300., 100., 1., 0., 300., 300., 1., 1., 100., 300., 0., 1.}
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
	// object move transform
	model := glm.mat4Translate(glm.vec3{200, 200, 0})
	mvp := proj * view * model

	shader := make_shader_program()

	set_uniform_mat4f(&shader, "u_MVP", &mvp)

	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)

	texture := make_texture("./ChernoLogo.png")
	texture->bind()
	set_uniform1i(&shader, "u_Texture", 0)
	// gl.UniformMatrix4fv(get_uniform_location(&shader, "u_MVP"), 1, false, transmute([^]f32)&proj)

	// set_uniform4f(&shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.})

	//clears the state (debug / demo use only...?):
	va->unbind()
	vb->unbind()
	ib->unbind()
	shader->unbind()

	r: f32 = 0.
	add := true
	for !glfw.WindowShouldClose(window) {
		clear(nil)

		step: f32 = 0.005
		r += add ? step : -1 * step
		if r >= 1. {
			r = 1.
			add = false
		} else if r <= 0 {
			r = 0.
			add = true
		}
		// set_uniform4f(&shader, "u_Color", [4]f32{r, 0.3, 0.8, 1.})

		draw(nil, &va, &ib, &shader)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteProgram(shader.id)

}

debug_proc_t :: proc "c" (source: u32, type: u32, id: u32, severity: u32, length: i32, message: cstring, userParam: rawptr) {
	context = runtime.default_context()
	fmt.println("debug_proc_t", source, type, id, severity, length, message, userParam)
}

gl_clear_errors :: proc() {
	for do if gl.GetError() == gl.NO_ERROR do return
}
gl_check_error :: proc() -> (code: u32, ok: bool) {
	err_code := gl.GetError()
	if err_code == gl.NO_ERROR {
		return 0, true
	} else {return err_code, false}
}

dbg_assert :: #force_inline proc(flag: bool) {
	if !flag do intrinsics.debug_trap()
}
