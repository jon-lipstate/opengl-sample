package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:strings"
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
compile_shader :: proc(type: u32, src: string) -> u32 {
	id := gl.CreateShader(type)
	cstr := strings.clone_to_cstring(src, context.temp_allocator)
	gl.ShaderSource(id, 1, &cstr, nil)
	gl.CompileShader(id)

	res: i32
	gl.GetShaderiv(id, gl.COMPILE_STATUS, &res)
	if res == 0 {
		length: i32
		gl.GetShaderiv(id, gl.INFO_LOG_LENGTH, &length)
		buf := make([]u8, length * size_of(u8))
		defer delete(buf)
		gl.GetShaderInfoLog(id, length, &length, raw_data(buf))
		shader_type := "VERTEX_SHADER"
		if type == gl.FRAGMENT_SHADER {
			shader_type = "FRAGMENT_SHADER"
		}
		fmt.println("FAILED TO COMPILE SHADER:", shader_type)
		fmt.println(buf)
		gl.DeleteShader(id)
		return 0
	}

	return id
}

make_shaders :: proc() -> u32 {
	program := gl.CreateProgram()
	vs := compile_shader(gl.VERTEX_SHADER, vertex_shader)
	fs := compile_shader(gl.FRAGMENT_SHADER, fragment_shader)
	gl.AttachShader(program, vs)
	gl.AttachShader(program, fs)
	gl.LinkProgram(program)
	gl.ValidateProgram(program)

	gl.DeleteShader(vs)
	gl.DeleteShader(fs)

	return program
}

main :: proc() {
	window := init_glfw()
	defer destroy_glfw(window)

	// make a vertex buffer:
	positions := []f32{-0.4, -0.5, 0.4, -0.5, 0.4, 0.5, -0.4, 0.5}
	indices := []u32{0, 1, 2, 2, 3, 0}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vb := make_vertex_buffer(positions)

	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(f32) * 2, 0) //https://docs.gl/gl4/glVertexAttribPointer
	gl.EnableVertexAttribArray(0)

	ib := make_index_buffer(indices)

	shaders := make_shaders()
	gl.UseProgram(shaders)

	location := gl.GetUniformLocation(shaders, "u_Color")
	assert(location != -1) // -1 is it is removed
	gl.Uniform4f(location, 0.2, 0.3, 0.8, 1.)

	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)

	//clears the state:
	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
	gl.UseProgram(0)

	r: f32 = 0.
	add := true
	for !glfw.WindowShouldClose(window) {
		/* Render here */
		gl.Clear(gl.COLOR_BUFFER_BIT)

		step: f32 = 0.005
		r += add ? step : -1 * step
		if r >= 1. {
			r = 1.
			add = false
		} else if r <= 0 {
			r = 0.
			add = true
		}
		gl.UseProgram(shaders)
		gl.Uniform4f(location, r, 0.3, 0.8, 1.)
		gl.BindVertexArray(vao)
		ib->bind()

		// C uses macro, Odin manually wraps fn:
		gl_clear_errors()
		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)
		err_code, ok := gl_check_error()
		dbg_assert(ok)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteProgram(shaders)

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
