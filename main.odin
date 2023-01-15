package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:runtime"
import "core:intrinsics"

GL_MAJOR_VERSION :: 3
GL_MINOR_VERSION :: 3

init_glfw :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		os.exit(1)
	}
	window := glfw.CreateWindow(960, 540, "OpenGL", nil, nil)
	if window == nil {
		glfw.Terminate()
		os.exit(1)
	}
	// odin ignores these..?
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE) // compat makes vtx buf for you, core does not

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

	// make a vertex buffer:
	positions := []f32{-0.4, -0.5, 0., 0., 0.4, -0.5, 1., 0., 0.4, 0.5, 1., 1., -0.4, 0.5, 0., 1.}
	indices := []u32{0, 1, 2, 2, 3, 0}

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	va := make_vertex_array()
	vb := make_vertex_buffer(positions)
	vl := make_vertex_layout()
	vl->push_type(f32, 2, false)
	vl->push_type(f32, 2, false)
	va->add_buffer(&vb, &vl)

	// gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(f32) * 2, 0) //https://docs.gl/gl4/glVertexAttribPointer
	// gl.EnableVertexAttribArray(0)

	ib := make_index_buffer(indices)

	shader := make_shader_program()
	set_uniform4f(&shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.})

	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)

	texture := make_texture("./ChernoLogo.png")
	texture->bind()
	set_uniform1i(&shader, "u_Texture", 0)

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
		set_uniform4f(&shader, "u_Color", [4]f32{r, 0.3, 0.8, 1.})

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
