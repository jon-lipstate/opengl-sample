package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:os"

GL_MAJOR_VERSION :: 4
GL_MINOR_VERSION :: 6

init_glfw :: proc() -> glfw.WindowHandle {
	if glfw.Init() == 0 {
		os.exit(1)
	}
	window := glfw.CreateWindow(1920, 1080, "OpenGL", nil, nil)
	if window == nil {
		glfw.Terminate()
		os.exit(1)
	}
	glfw.MakeContextCurrent(window)
	gl.load_up_to(GL_MAJOR_VERSION, GL_MINOR_VERSION, glfw.gl_set_proc_address)

	return window
}

destroy_glfw :: proc(window: glfw.WindowHandle) {
	glfw.DestroyWindow(window)
	glfw.Terminate()
}

main :: proc() {
	window := init_glfw()
	defer destroy_glfw(window)

	for !glfw.WindowShouldClose(window) {
		/* Render here */
		gl.Clear(gl.COLOR_BUFFER_BIT)

		glBegin(GL_TRIANGLES)
		glVertex2f(-0.5, -0.5)
		glVertex2f(0.0, 0.5)
		glVertex2f(0.5, -0.5)
		glEnd()

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}
