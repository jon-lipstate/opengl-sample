package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:runtime"
import "core:intrinsics"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

init_glfw :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		os.exit(1)
	}
	window := glfw.CreateWindow(960, 540, "OpenGL", nil, nil)
	if window == nil {
		glfw.Terminate()
		os.exit(1)
	}
	glfw.MakeContextCurrent(window)
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

vertex_shader :: string(#load("./vertex.glsl"))
fragment_shader :: string(#load("./fragment.glsl"))

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

	buf_id: u32
	gl.GenBuffers(1, &buf_id)
	gl.BindBuffer(gl.ARRAY_BUFFER, buf_id)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(f32) * 2, 0) //https://docs.gl/gl4/glVertexAttribPointer
	gl.EnableVertexAttribArray(0)
	gl.BufferData(gl.ARRAY_BUFFER, len(positions) * size_of(f32), transmute([^]f32)raw_data(positions), gl.STATIC_DRAW)

	idx_buf_id: u32
	gl.GenBuffers(1, &idx_buf_id)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, idx_buf_id)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(positions) * size_of(u32), transmute([^]u32)raw_data(indices), gl.STATIC_DRAW)

	shaders := make_shaders()
	gl.UseProgram(shaders)
	// Callback Based Error handling, OpenGL 4.3+ Only
	// gl.DebugMessageCallback(debug_proc_t, nil)

	for !glfw.WindowShouldClose(window) {
		/* Render here */
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// C uses macro, Odin manually wraps fn:
		gl_clear_errors()
		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.INT, nil) // intentional error:gl.UNSIGNED_INT to int
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
