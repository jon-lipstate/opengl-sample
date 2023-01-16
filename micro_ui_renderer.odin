package opengl
import mu "vendor:microui"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:mem"
// THIS WAS ATTEMPT TO PORT MICROUI RENDERER BEFORE I GOT IMGUI WORKING
mu_process_frame :: proc(ctx: ^mu.Context) {
	mu.begin(ctx)
	mu_test_window(ctx)
	mu.end(ctx)
}
mu_render :: proc(ctx: ^mu.Context, mbuf: ^Mu_Render_Buffer) {
	cmd: ^mu.Command
	for mu.next_command(ctx, &cmd) {
		switch var in cmd.variant {
		case ^mu.Command_Jump:
			fmt.println("not impl: Command_Jump")
		case ^mu.Command_Clip:
			fmt.println("not impl: Command_Clip")
		case ^mu.Command_Rect:
			mu_render_rect(mbuf, var.rect, var.color)
		case ^mu.Command_Text:
			mu_render_text(mbuf, var.str, var.pos, var.color)
		case ^mu.Command_Icon:
			mu_render_icon(mbuf, var.id, var.rect, var.color)

		}
	}
}
BUF_SIZE :: 16384
Mu_Render_Buffer :: struct {
	window_width:  i32,
	window_height: i32,
	current_index: int,
	tex_buf:       [BUF_SIZE * 8]f32,
	vert_buf:      [BUF_SIZE * 8]f32,
	color_buf:     [BUF_SIZE * 16]u8,
	index_buf:     [BUF_SIZE * 6]u32,
}
mu_render_rect :: proc(mbuf: ^Mu_Render_Buffer, rect: mu.Rect, color: mu.Color) {
	//push_quad(rect, atlas[ATLAS_WHITE], color);
}
mu_render_text :: proc(mbuf: ^Mu_Render_Buffer, str: string, pos: mu.Vec2, color: mu.Color) {

}
mu_render_icon :: proc(mbuf: ^Mu_Render_Buffer, id: mu.Icon, rect: mu.Rect, color: mu.Color) {

}
push_quad :: proc(mbuf: ^Mu_Render_Buffer, dest: mu.Rect, src: mu.Rect, color: mu.Color) {
	if mbuf.current_index == BUF_SIZE do mu_flush_buf(mbuf)

}

mu_test_window :: proc(ctx: ^mu.Context) {
	if !mu.begin_window(ctx, "Demo Window", mu.Rect{40, 40, 300, 400}) do return
	win := mu.get_current_container(ctx)
	win.rect.w = max(win.rect.w, 240)
	win.rect.h = max(win.rect.h, 300)

	// info
	res := mu.header(ctx, "Window Info")
	if .ACTIVE in res || .SUBMIT in res || .CHANGE in res {
		win = mu.get_current_container(ctx)
		mu.layout_row(ctx, []i32{54, -1}, 2)
		mu.label(ctx, "Position: ")
		pos := fmt.tprintf("%d,%d", win.rect.x, win.rect.y)
		mu.label(ctx, pos)
		mu.label(ctx, "Size: ")
		dim := fmt.tprintf("%d,%d", win.rect.w, win.rect.h)
		mu.label(ctx, dim)
	}

	// labels & buttons

	// tree

	// background color sliders

	mu.end_window(ctx)
}

mu_flush_buf :: proc(mbuf: ^Mu_Render_Buffer) {
	if mbuf.current_index == 0 do return

	gl.Viewport(0, 0, mbuf.window_width, mbuf.window_height)
	glMatrixMode(gl.PROJECTION)
	glPushMatrix()
	glLoadIdentity()
	glOrtho(0, f64(mbuf.window_width), f64(mbuf.window_height), 0, -1, 1) // revresed height..?
	glMatrixMode(gl.MODELVIEW)
	glPushMatrix()
	glLoadIdentity()
	glTexCoordPointer(2, gl.FLOAT, 0, transmute([^]f32)&mbuf.tex_buf)
	glVertexPointer(2, gl.FLOAT, 0, transmute([^]f32)&mbuf.vert_buf)
	glColorPointer(2, gl.UNSIGNED_BYTE, 0, transmute([^]f32)&mbuf.color_buf)
	glDrawElements(gl.TRIANGLES, mbuf.current_index * 6, gl.UNSIGNED_INT, transmute([^]u32)&mbuf.index_buf)

	glMatrixMode(gl.MODELVIEW)
	glPopMatrix()
	glMatrixMode(gl.PROJECTION)
	glPopMatrix()

	mbuf.current_index = 0
}
