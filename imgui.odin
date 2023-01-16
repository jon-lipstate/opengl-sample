package opengl
import "vendor:glfw"
import "core:fmt"
import "core:strings"
import "core:runtime"
import imgui "./vendor/odin-imgui"
import imgl "./vendor/odin-imgui/impl/opengl"
import imglfw "./vendor/odin-imgui/impl/glfw"

Imgui_State :: struct {
	opengl_state: imgl.OpenGL_State,
}
init_imgui_state :: proc(window: glfw.WindowHandle) -> Imgui_State {
	res := Imgui_State{}

	imgui.create_context()
	imgui.style_colors_dark()

	imglfw.setup_state(window, true)
	imgl.setup_state(&res.opengl_state)

	return res
}
imgui_new_frame :: proc() {
	imglfw.update_display_size()
	imglfw.update_mouse()
	imglfw.update_dt()
}

slider_window :: proc(a: ^[2]f32, b: ^[2]f32) {
	imgui.set_next_window_pos(imgui.Vec2{WINDOW_WIDTH - 250, 10})
	imgui.set_next_window_bg_alpha(0.2)
	overlay_flags: imgui.Window_Flags = .NoDecoration | .AlwaysAutoResize | .NoSavedSettings | .NoFocusOnAppearing | .NoNav
	imgui.begin("Translation", nil, overlay_flags)

	imgui.slider_float2("TA", transmute([^]f32)a, 0, WINDOW_WIDTH)
	imgui.slider_float2("TB", transmute([^]f32)b, 0, WINDOW_HEIGHT)
	imgui.end()
}

info_overlay :: proc() {
	imgui.set_next_window_pos(imgui.Vec2{10, 10})
	imgui.set_next_window_bg_alpha(0.2)
	overlay_flags: imgui.Window_Flags = .NoDecoration | .AlwaysAutoResize | .NoSavedSettings | .NoFocusOnAppearing | .NoNav | .NoMove
	imgui.begin("Info", nil, overlay_flags)
	imgui.text_unformatted("Press Esc to close the application")
	imgui.text_unformatted("Press Tab to show demo window")
	imgui.end()
}

text_test_window :: proc() {
	imgui.begin("Text test")
	imgui.text("NORMAL TEXT: {}", 1)
	imgui.text_colored(imgui.Vec4{1, 0, 0, 1}, "COLORED TEXT: {}", 2)
	imgui.text_disabled("DISABLED TEXT: {}", 3)
	imgui.text_unformatted("UNFORMATTED TEXT")
	imgui.text_wrapped("WRAPPED TEXT: {}", 4)
	imgui.end()
}

input_text_test_window :: proc() {
	imgui.begin("Input text test")
	@(static)
	buf: [256]u8
	@(static)
	ok := false
	imgui.input_text("Test input", buf[:])
	imgui.input_text("Test password input", buf[:], .Password)
	if imgui.input_text("Test returns true input", buf[:], .EnterReturnsTrue) {
		ok = !ok
	}
	imgui.checkbox("OK?", &ok)
	imgui.text_wrapped("Buf content: %s", string(buf[:]))
	imgui.end()
}

misc_test_window :: proc() {
	imgui.begin("Misc tests")
	pos := imgui.get_window_pos()
	size := imgui.get_window_size()
	imgui.text("pos: {}", pos)
	imgui.text("size: {}", size)
	imgui.end()
}

combo_test_window :: proc() {
	imgui.begin("Combo tests")
	@(static)
	items := []string{"1", "2", "3"}
	@(static)
	curr_1 := i32(0)
	@(static)
	curr_2 := i32(1)
	@(static)
	curr_3 := i32(2)
	if imgui.begin_combo("begin combo", items[curr_1]) {
		for item, idx in items {
			is_selected := idx == int(curr_1)
			if imgui.selectable(item, is_selected) {
				curr_1 = i32(idx)
			}

			if is_selected {
				imgui.set_item_default_focus()
			}
		}
		defer imgui.end_combo()
	}

	imgui.combo_str_arr("combo str arr", &curr_2, items)

	item_getter: imgui.Items_Getter_Proc : proc "c" (data: rawptr, idx: i32, out_text: ^cstring) -> bool {
		context = runtime.default_context()
		items := (cast(^[]string)data)
		out_text^ = strings.clone_to_cstring(items[idx], context.temp_allocator)
		return true
	}

	imgui.combo_fn_bool_ptr("combo fn ptr", &curr_3, item_getter, &items, i32(len(items)))

	imgui.end()
}
