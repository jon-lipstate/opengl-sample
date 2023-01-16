package demos
import gl "vendor:OpenGL"
import "core:mem"
import imgui "../vendor/odin-imgui"
import glm "core:math/linalg/glsl"
import "../renderer"
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Demo_Texture_2D :: struct {
	translation_a: [2]f32,
	translation_b: [2]f32,
	va:            renderer.Vertex_Array,
	vb:            renderer.Vertex_Buffer,
	ib:            renderer.Index_Buffer,
	shader:        renderer.Shader_Program,
	texture:       renderer.Texture,
	projection:    glm.mat4,
	view:          glm.mat4,
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
vertex_shader :: string(#load("../vertex.glsl"))
fragment_shader :: string(#load("../fragment.glsl"))
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
gen__texture_2d :: proc() -> ^Demo_Texture_2D {
	res := cast(^Demo_Texture_2D)mem.alloc(size_of(Demo_Texture_2D))
	positions := []f32{-100., -100., 0., 0., 100., -100., 1., 0., 100., 100., 1., 1., -100., 100., 0., 1.}
	indices := []u32{0, 1, 2, 2, 3, 0}
	res.translation_a = {300, 100}
	res.translation_b = {100, 300}
	// Projection moves into unit-screen space
	res.projection = glm.mat4Ortho3d(0, 960, 0, 540, -1., 1.)
	// Camera
	res.view = glm.mat4Translate(glm.vec3{0, 0, 0})

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	res.va = renderer.make_vertex_array()
	res.vb = renderer.make_vertex_buffer(positions)
	vl := renderer.make_vertex_layout()
	vl->push_type(f32, 2, false)
	vl->push_type(f32, 2, false)
	res.va->add_buffer(&res.vb, &vl)
	res.ib = renderer.make_index_buffer(indices)

	res.shader = renderer.make_shader_program(vertex_shader, fragment_shader)
	// renderer.set_uniform4f(&res.shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.})

	res.texture = renderer.make_texture("./ChernoLogo.png")
	res.texture->bind()
	renderer.set_uniform1i(&res.shader, "u_Texture", 0)

	return res
}
destroy__texture_2d :: proc(c: ^Demo_Texture_2D) {
	gl.DeleteProgram(c.shader.id)
	mem.free(c)
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
on_render__texture_2d :: proc(val: ^Demo_Texture_2D) {
	gl.ClearColor(0.1, 0.1, 0.1, 1.)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	val.shader->bind()
	{
		model := glm.mat4Translate(glm.vec3{val.translation_a.x, val.translation_a.y, 0})
		mvp := val.projection * val.view * model
		renderer.set_uniform_mat4f(&val.shader, "u_MVP", &mvp)
		renderer.draw(nil, &val.va, &val.ib, &val.shader)
	}
	{
		model := glm.mat4Translate(glm.vec3{val.translation_b.x, val.translation_b.y, 0})
		mvp := val.projection * val.view * model
		renderer.set_uniform_mat4f(&val.shader, "u_MVP", &mvp)
		renderer.draw(nil, &val.va, &val.ib, &val.shader)
	}
	// renderer.set_uniform4f(&val.shader, "u_Color", [4]f32{0.2, 0.3, 0.8, 1.}) // replaced with texColor in shader
}
on_imgui_render__texture_2d :: proc(c: ^Demo_Texture_2D) {
	imgui.slider_float2("TA", transmute([^]f32)&c.translation_a, 0, 960)
	imgui.slider_float2("TB", transmute([^]f32)&c.translation_b, 0, 960)
	imgui.text("%.3f ms/f", imgui.get_io().framerate)
}
on_update__texture_2d :: proc(c: ^Demo_Texture_2D, timestep: f32) {}
