package demos
import gl "vendor:OpenGL"
import imgui "../vendor/odin-imgui"

Demo_ClearColor :: struct {
	using color: [4]f32,
}
gen__clear_color :: proc() -> Demo_ClearColor {
	return Demo_ClearColor{{0.2, 0.3, 0.8, 1.}}
}
destroy__clear_color :: proc(c: ^Demo_ClearColor) {}

on_render__clear_color :: proc(c: ^Demo_ClearColor) {
	gl.ClearColor(c.r, c.g, c.b, c.a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}
on_imgui_render__clear_color :: proc(c: ^Demo_ClearColor) {
	c := transmute([^]f32)&c.color
	imgui.color_edit4("Clear Color", c)
}
on_update__clear_color :: proc(timestep: f32) {}
