package demos
import "core:fmt"
import "core:strings"
import imgui "../vendor/odin-imgui"
import gl "vendor:OpenGL"
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Demo_Menu :: struct {
	current_demo: ^Demo,
}
on_imgui_render__menu :: proc(menu: ^Demo_Menu) {
	for type in Demo_Type {
		str := fmt.tprint(type)
		if imgui.button(str) {
			destroy(menu.current_demo^)
			menu.current_demo^ = gen_demo(type)
		}
	}
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\
Demo :: union {
	^Demo_ClearColor,
	^Demo_Menu,
	^Demo_Texture_2D,
}
Demo_Type :: enum {
	Clear,
	Texture2D,
}
gen_demo :: proc(type: Demo_Type) -> Demo {
	res: Demo
	switch type {
	case .Clear:
		res = gen__clear_color()
	case .Texture2D:
		res = gen__texture_2d()
	}
	return res
}
//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\//\\

destroy :: proc(demo: Demo) {
	if demo == nil do return
	switch d in demo {
	case (^Demo_ClearColor):
		destroy__clear_color(d)
	case (^Demo_Menu):
	//nop
	case (^Demo_Texture_2D):
		destroy__texture_2d(d)
	}
}
on_render :: proc(demo: Demo) {
	if demo == nil do return
	switch d in demo {
	case (^Demo_ClearColor):
		on_render__clear_color(d)
	case (^Demo_Menu):
	//nop
	case (^Demo_Texture_2D):
		on_render__texture_2d(d)
	}

}
on_imgui_render :: proc(demo: Demo) {
	if demo == nil do return
	switch d in demo {
	case (^Demo_ClearColor):
		on_imgui_render__clear_color(d)
	case (^Demo_Menu):
		on_imgui_render__menu(d)
	case (^Demo_Texture_2D):
		on_imgui_render__texture_2d(d)
	}
}
on_update :: proc(demo: Demo, timestep: f32) {
	if demo == nil do return
	switch d in demo {
	case (^Demo_ClearColor):
		on_update__clear_color(d, timestep)
	case (^Demo_Menu):
	case (^Demo_Texture_2D):
		on_update__texture_2d(d, timestep)
	}
}
