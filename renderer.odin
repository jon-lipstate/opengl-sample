package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
vertex_shader :: string(#load("./vertex.glsl"))
fragment_shader :: string(#load("./fragment.glsl"))
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Vertex_Buffer_Element :: struct {
	// EX: gl.FLOAT
	type:          u32,
	count:         i32,
	is_normalized: bool,
}
Vertex_Buffer_Layout :: struct {
	stride:    i32,
	elements:  [dynamic]Vertex_Buffer_Element,
	push_type: proc(this: ^Vertex_Buffer_Layout, type: typeid, count: i32, is_normalized: bool),
}
make_vertex_layout :: proc() -> Vertex_Buffer_Layout {
	layout := Vertex_Buffer_Layout{}
	layout.elements = {} // make([dynamic]Vertex_Buffer_Element,)
	push_type :: proc(this: ^Vertex_Buffer_Layout, type: typeid, count: i32, is_normalized: bool) {
		elm := Vertex_Buffer_Element{0, count, is_normalized}
		switch type {
		case f32:
			elm.type = gl.FLOAT
		case u32:
			elm.type = gl.UNSIGNED_INT
		case i32:
			elm.type = gl.INT
		case u8:
			elm.type = gl.UNSIGNED_BYTE
		}
		this.stride += i32(get_size_of_type(elm.type)) * count
		append_elem(&this.elements, elm)
	}
	layout.push_type = push_type

	return layout
}

Vertex_Buffer :: struct {
	id:     u32,
	//
	bind:   proc(this: ^Vertex_Buffer),
	unbind: proc(this: ^Vertex_Buffer),
	delete: proc(this: ^Vertex_Buffer),
}
make_vertex_buffer :: proc(arr: $T/[]$E) -> Vertex_Buffer {
	vb := Vertex_Buffer{}
	gl.GenBuffers(1, &vb.id)
	gl.BindBuffer(gl.ARRAY_BUFFER, vb.id)
	gl.BufferData(gl.ARRAY_BUFFER, len(arr) * size_of(E), transmute([^]E)raw_data(arr), gl.STATIC_DRAW)

	bind :: proc(this: ^Vertex_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, this.id)
	}
	vb.bind = bind

	unbind :: proc(this: ^Vertex_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	}
	vb.unbind = unbind

	delete :: proc(this: ^Vertex_Buffer) {
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
	bind:   proc(this: ^Index_Buffer),
	unbind: proc(this: ^Index_Buffer),
	delete: proc(this: ^Index_Buffer),
}
make_index_buffer :: proc(arr: []u32) -> Index_Buffer {
	ib := Index_Buffer{}
	ib.count = u32(len(arr))
	gl.GenBuffers(1, &ib.id)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ib.id)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(arr) * size_of(u32), transmute([^]u32)raw_data(arr), gl.STATIC_DRAW)

	bind :: proc(this: ^Index_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, this.id)
	}
	ib.bind = bind

	unbind :: proc(this: ^Index_Buffer) {
		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	}
	ib.unbind = unbind

	delete :: proc(this: ^Index_Buffer) {
		// glgeterror expects vb/ib to have a context, will err loop if free after ctx gone
		id := this.id
		gl.DeleteBuffers(1, &id)
	}
	ib.delete = delete

	return ib
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Vertex_Array :: struct {
	id:         u32,
	//
	add_buffer: proc(this: ^Vertex_Array, buf: ^Vertex_Buffer, layout: ^Vertex_Buffer_Layout),
	bind:       proc(this: ^Vertex_Array),
	unbind:     proc(this: ^Vertex_Array),
	delete:     proc(this: ^Vertex_Array),
}
make_vertex_array :: proc() -> Vertex_Array {
	va := Vertex_Array{}
	gl.GenVertexArrays(1, &va.id)
	//
	delete :: proc(this: ^Vertex_Array) {
		gl.DeleteVertexArrays(1, &this.id)
	}
	va.delete = delete
	bind :: proc(this: ^Vertex_Array) {
		gl.BindVertexArray(this.id)
	}
	va.bind = bind
	unbind :: proc(this: ^Vertex_Array) {
		gl.BindVertexArray(0)
	}
	va.unbind = unbind

	add_buffer :: proc(this: ^Vertex_Array, buf: ^Vertex_Buffer, layout: ^Vertex_Buffer_Layout) {
		this->bind()
		buf->bind()
		offset := 0
		for i: u32 = 0; i < u32(len(layout.elements)); i += 1 {
			elm := layout.elements[i]
			gl.EnableVertexAttribArray(i)
			gl.VertexAttribPointer(i, elm.count, elm.type, elm.is_normalized, layout.stride, uintptr(offset))
			offset += int(elm.count) * get_size_of_type(elm.type)
		}
	}
	va.add_buffer = add_buffer
	return va
}

@(private)
get_size_of_type :: proc(type: u32) -> int {
	switch type {
	case gl.FLOAT, gl.INT, gl.UNSIGNED_INT:
		return 4
	case gl.UNSIGNED_BYTE:
		return 1
	case:
		panic("unsupported type")
	}
}
