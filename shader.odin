package learnopengl

import gl "vendor:OpenGL"

import "core:fmt"

shader_create :: proc(vert_path, frag_path: string) -> u32 {
	shader_program, shader_ok := gl.load_shaders(vert_path, frag_path)
	if !shader_ok {
		msg, shader := gl.get_last_error_message()
		fmt.eprintln(shader, "compile error:", msg)
		panic("failed loading shaders")
	}
	return shader_program
}
