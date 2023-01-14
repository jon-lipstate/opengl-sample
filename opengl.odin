package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"
import "core:fmt"
import "core:strings"

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
	positions := []f32{-0.4, -0.5, 0.0, 0.5, 0.4, -0.5}
	buf_id: u32
	gl.GenBuffers(1, &buf_id)
	gl.BindBuffer(gl.ARRAY_BUFFER, buf_id)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(f32) * 2, 0) //https://docs.gl/gl4/glVertexAttribPointer
	gl.EnableVertexAttribArray(0)
	gl.BufferData(gl.ARRAY_BUFFER, len(positions) * size_of(f32), transmute([^]f32)raw_data(positions), gl.STATIC_DRAW)

	shaders := make_shaders()
	gl.UseProgram(shaders)

	for !glfw.WindowShouldClose(window) {
		/* Render here */
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawArrays(GL_TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteProgram(shaders)

}
