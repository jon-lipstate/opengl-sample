package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
vertex_shader :: string(#load("./vertex.glsl"))
fragment_shader :: string(#load("./fragment.glsl"))
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Vertex_Buffer :: struct {
	id:     u32,
	//
	bind:   proc(this: Vertex_Buffer),
	unbind: proc(this: Vertex_Buffer),
	delete: proc(this: Vertex_Buffer),
}
make_vertex_buffer :: proc(arr: $T/[]$E) -> Vertex_Buffer {
	vb := Vertex_Buffer{}
	gl.GenBuffers(1, &vb.id)
	gl.BindBuffer(gl.ARRAY_BUFFER, vb.id)
	gl.BufferData(gl.ARRAY_BUFFER, len(arr) * size_of(E), transmute([^]E)raw_data(arr), gl.STATIC_DRAW)

	bind :: proc(this: Vertex_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, this.id)
	}
	vb.bind = bind

	unbind :: proc(this: Vertex_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	}
	vb.unbind = unbind

	delete :: proc(this: Vertex_Buffer) {
		id := this.id
		gl.DeleteBuffers(1, &id)
	}
	vb.delete = delete

	return vb
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Index_Buffer :: struct {
	id:     u32,
	count:  u32,
	//
	bind:   proc(this: Index_Buffer),
	unbind: proc(this: Index_Buffer),
	delete: proc(this: Index_Buffer),
}
make_index_buffer :: proc(arr: []u32) -> Index_Buffer {
	ib := Index_Buffer{}
	ib.count = u32(len(arr))
	gl.GenBuffers(1, &ib.id)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ib.id)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(arr) * size_of(u32), transmute([^]u32)raw_data(arr), gl.STATIC_DRAW)

	bind :: proc(this: Index_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, this.id)
	}
	ib.bind = bind

	unbind :: proc(this: Index_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	}
	ib.unbind = unbind

	delete :: proc(this: Index_Buffer) {
		// glgeterror expects vb/ib to have a context, will err loop if free after ctx gone
		id := this.id
		gl.DeleteBuffers(1, &id)
	}
	ib.delete = delete

	return ib
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
