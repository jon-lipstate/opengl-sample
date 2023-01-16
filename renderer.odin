package opengl
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:strings"
import "core:intrinsics"
import "core:runtime"
import "core:os"
import "core:fmt"
import "vendor:stb/image"
import glm "core:math/linalg/glsl"

//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
vertex_shader :: string(#load("./vertex.glsl"))
fragment_shader :: string(#load("./fragment.glsl"))
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
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
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
// TODO: move fn ptrs to overloads (eg delete::proc{del_vtx,...})
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
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Shader_Program :: struct {
	id:        u32,
	locations: map[string]i32,
	bind:      proc(this: ^Shader_Program),
	unbind:    proc(this: ^Shader_Program),
}
make_shader_program :: proc() -> Shader_Program {
	sp := Shader_Program{}
	sp.locations = {}
	sp.id = gl.CreateProgram()
	vs := compile_shader(gl.VERTEX_SHADER, vertex_shader)
	fs := compile_shader(gl.FRAGMENT_SHADER, fragment_shader)
	gl.AttachShader(sp.id, vs)
	gl.AttachShader(sp.id, fs)
	gl.LinkProgram(sp.id)
	gl.ValidateProgram(sp.id)

	gl.DeleteShader(vs)
	gl.DeleteShader(fs)

	bind :: proc(sp: ^Shader_Program) {
		gl.UseProgram(sp.id)
	}
	unbind :: proc(sp: ^Shader_Program) {
		gl.UseProgram(0)
	}
	sp.bind = bind
	sp.unbind = unbind

	sp->bind()

	return sp
}
set_uniform1i :: proc(sp: ^Shader_Program, name: string, v: i32) {
	loc := get_uniform_location(sp, name)
	gl.Uniform1i(loc, v)
}
set_uniform1f :: proc(sp: ^Shader_Program, name: string, v: f32) {
	loc := get_uniform_location(sp, name)
	gl.Uniform1f(loc, v)
}
set_uniform4f :: proc(sp: ^Shader_Program, name: string, v: [4]f32) {
	loc := get_uniform_location(sp, name)
	gl.Uniform4f(loc, v.x, v.y, v.z, v.w)
}
set_uniform_mat4f :: proc(sp: ^Shader_Program, name: string, mat: ^glm.mat4) {
	loc := get_uniform_location(sp, name)
	m := transmute([^]f32)mat

	// for i := 0; i < 16; i += 1 {
	// 	if i % 4 == 0 do fmt.printf("\n")
	// 	fmt.printf("%.2f ", m[i])
	// }
	// fmt.println("\n")

	gl.UniformMatrix4fv(loc, 1, false, m)
}
get_uniform_location :: proc(sp: ^Shader_Program, name: string) -> i32 {
	loc, ok := sp.locations[name]

	if !ok {
		cstr := strings.clone_to_cstring(name, context.temp_allocator)
		loc = gl.GetUniformLocation(sp.id, cstr)
		if loc == -1 {
			fmt.println("Location not assigned (-1)", name)
		} else {
			sp.locations[name] = loc
		}
	}
	// for k, v in sp.locations {
	// 	fmt.println(k, v)
	// }
	return loc
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
		fmt.println(string(buf))
		gl.DeleteShader(id)
		intrinsics.debug_trap()
		return 0
	}

	return id
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Renderer :: struct {}

draw :: proc(renderer: ^Renderer, va: ^Vertex_Array, ib: ^Index_Buffer, shader: ^Shader_Program) {
	shader->bind()
	va->bind()
	ib->bind()
	// C uses macro, Odin manually wraps fn:
	gl_clear_errors()
	gl.DrawElements(gl.TRIANGLES, i32(ib.count), gl.UNSIGNED_INT, nil)
	err_code, ok := gl_check_error()
	dbg_assert(ok)
}
clear :: proc(renderer: ^Renderer) {
	gl.Clear(gl.COLOR_BUFFER_BIT)

}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Texture :: struct {
	id:     u32,
	path:   string,
	buf:    [^]u8,
	width:  i32,
	height: i32,
	bpp:    i32, //bits per pixel
	// slot:   i32, // why no add??
	bind:   proc(this: ^Texture, slot: u32 = 0),
	unbind: proc(this: ^Texture),
	delete: proc(this: ^Texture),
}
make_texture :: proc(path: string) -> Texture {
	tex := Texture{}
	tex.path = path

	image.set_flip_vertically_on_load(1)
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	tex.buf = image.load(cstr, &tex.width, &tex.height, &tex.bpp, 4)

	gl.GenTextures(1, &tex.id)
	gl.BindTexture(gl.TEXTURE_2D, tex.id)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, tex.width, tex.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, tex.buf)
	//
	unbind :: proc(this: ^Texture) {
		gl.BindTexture(gl.TEXTURE_2D, 0)
	}
	bind :: proc(this: ^Texture, slot: u32 = 0) {
		gl.ActiveTexture(gl.TEXTURE0 + slot)
		gl.BindTexture(gl.TEXTURE_2D, this.id)
	}
	delete :: proc(this: ^Texture) {
		gl.DeleteTextures(1, &this.id)
	}
	tex.unbind = unbind
	tex.bind = bind
	//
	tex->unbind()
	// if tex.buf != nil {
	// 	image.image_free(tex.buf)
	// }
	return tex
}
