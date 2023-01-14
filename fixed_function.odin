package opengl
import "core:sys/windows"
import "vendor:directx/dxgi"
import "core:c"

/////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
foreign import gl "system:Opengl32.lib"
foreign gl {
	glViewport :: proc(x: i32, y: i32, width: i32, height: i32) ---
	glClearColor :: proc(r: f32, g: f32, b: f32, a: f32) ---
	glClear :: proc(mask: u32) ---
	glGenTextures :: proc(id: int, handle: ^uint) ---
	glBindTexture :: proc(target: uint, texture: ^uint) ---
	glDeleteTextures :: proc(n: int, textures: ^uint) ---
	glTexImage2D :: proc(target: uint, level: int, internalformat: int, width: int, height: int, border: int, format: uint, type: uint, pixels: rawptr) ---
	glTexParameteri :: proc(target: uint, pname: uint, param: int) ---
	glTexEnvi :: proc(target: uint, pname: uint, param: int) ---
	glEnable :: proc(cap: uint) ---
	glDisable :: proc(cap: uint) ---
	glLoadIdentity :: proc() ---
	glEnd :: proc() ---
	glMatrixMode :: proc(mode: uint) ---
	glBegin :: proc(mode: uint) ---
	glTexCoord2f :: proc(s: f32, t: f32) ---
	glVertex2f :: proc(x: f32, y: f32) ---
	glColor4f :: proc(r: f32, g: f32, b: f32, a: f32) ---
	glLoadMatrixf :: proc(m: ^f32) ---
	glGetString :: proc(name: uint) -> ^u8 ---
	glBlendFunc :: proc(sfactor: uint, dfactor: uint) ---
}
HGLRC :: windows.HGLRC
GL_COLOR_BUFFER_BIT :: 16384
GL_TEXTURE_2D :: 0x0DE1
GL_NEAREST :: 0x2600
GL_TEXTURE_MAG_FILTER :: 0x2800
GL_TEXTURE_MIN_FILTER :: 0x2801
GL_TEXTURE_WRAP_S :: 0x2802
GL_TEXTURE_WRAP_T :: 0x2803
GL_CLAMP :: 0x2900
GL_TEXTURE_ENV :: 0x2300
GL_TEXTURE_ENV_MODE :: 0x2200
GL_TEXTURE_ENV_COLOR :: 0x2201
GL_MODULATE :: 0x2100
GL_TEXTURE :: 0x1702
GL_MODELVIEW :: 0x1700
GL_PROJECTION :: 0x1701
GL_TRIANGLES :: 0x0004
GL_RGBA8 :: 0x8058
GL_BGRA_EXT :: 0x80E1
GL_UNSIGNED_BYTE :: 0x1401
GL_VENDOR :: 0x1F00
GL_RENDERER :: 0x1F01
GL_VERSION :: 0x1F02
GL_EXTENSIONS :: 0x1F03
