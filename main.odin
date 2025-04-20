package learnopengl

import "base:runtime"

import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:glfw"

vertices := [?]f32{
	-0.5, -0.5, 0.0,
	-0.1, -0.5, 0.0,
	-0.1,  0.5, 0.0,
	 0.1,  0.5, 0.0,
	 0.1, -0.5, 0.0,
	 0.5, -0.5, 0.0,
}

// indices := [?]u32{
// 	0, 1, 3,
// 	1, 2, 3,
// }

vertex_shader_source := "#version 460 core\n" +
						"layout (location = 0) in vec3 aPos;\n" +
						"void main() {\n" +
						"	gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n" +
						"}"

orange_fragment_shader_source := "#version 460 core\n" +
						  "out vec4 FragColor;\n" +
						  "void main() {\n" +
						  "    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n" +
						  "}"

yellow_fragment_shader_source := "#version 460 core\n" +
						  "out vec4 FragColor;\n" +
						  "void main() {\n" +
						  "    FragColor = vec4(1.0f, 1.0f, 0.0f, 1.0f);\n" +
						  "}"

main :: proc() {
	if !glfw.Init() {
		fmt.eprintln("failed to initialize GLFW")
		panic("glfw init error")
	}
	defer glfw.Terminate()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "LearnOpenGL", nil, nil)
	if window == nil {
		fmt.eprintln("failed to create GLFW window")
		glfw.Terminate()
		panic("glfw window error")
	}
	glfw.MakeContextCurrent(window)

	// load OpenGL function pointers, must be done before calling any other gl
	// functions and after the window is made the current context
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	nrAttribs: i32
	gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, &nrAttribs)
	fmt.println("maximum number of vertex attributes supported:", nrAttribs)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetWindowSizeCallback(window, framebuffer_size_callback)
	glfw.SetErrorCallback(error_callback)

	vbos: [2]u32
	gl.GenBuffers(2, &vbos[0])
	defer gl.DeleteBuffers(2, &vbos[0])

	// ebo: u32
	// gl.GenBuffers(1, &ebo)
	// defer gl.DeleteBuffers(1, &ebo)

	vaos: [2]u32
	gl.GenVertexArrays(2, &vaos[0])
	defer gl.DeleteVertexArrays(2, &vaos[0])

	gl.BindVertexArray(vaos[0])
	gl.BindBuffer(gl.ARRAY_BUFFER, vbos[0])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices)/2, &vertices[0], gl.STATIC_DRAW)
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// tell OpenGL how to read the vertex data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	gl.BindVertexArray(vaos[1])
	gl.BindBuffer(gl.ARRAY_BUFFER, vbos[1])
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices)/2, &vertices[len(vertices)/2], gl.STATIC_DRAW)
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// tell OpenGL how to read the vertex data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	vertex_shader, orange_fragment_shader, yellow_fragment_shader: u32
	ok: bool
	vertex_shader, ok = gl.compile_shader_from_source(vertex_shader_source, .VERTEX_SHADER)
	if !ok {
		fmt.eprintln("error compiling vertex shader:")
		info_log: [512]u8
		gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
		fmt.eprintln(info_log)
		panic("vertex shader error")
	}
	orange_fragment_shader, ok = gl.compile_shader_from_source(orange_fragment_shader_source, .FRAGMENT_SHADER)
	if !ok {
		fmt.eprintln("error compiling fragment shader:")
		info_log: [512]u8
		gl.GetShaderInfoLog(orange_fragment_shader, 512, nil, &info_log[0])
		fmt.eprintln(info_log)
		panic("fragment shader error")
	}
	yellow_fragment_shader, ok = gl.compile_shader_from_source(yellow_fragment_shader_source, .FRAGMENT_SHADER)
	if !ok {
		fmt.eprintln("error compiling fragment shader:")
		info_log: [512]u8
		gl.GetShaderInfoLog(yellow_fragment_shader, 512, nil, &info_log[0])
		fmt.eprintln(info_log)
		panic("fragment shader error")
	}

	orange_shader_program := gl.CreateProgram()
	gl.AttachShader(orange_shader_program, vertex_shader)
	gl.AttachShader(orange_shader_program, orange_fragment_shader)
	gl.LinkProgram(orange_shader_program)
	success: i32
	gl.GetProgramiv(orange_shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		fmt.eprintln("error linking shader program:")
		info_log: [512]u8
		gl.GetProgramInfoLog(orange_shader_program, 512, nil, &info_log[0])
		fmt.eprintln(info_log)
		panic("shader program error")
	}

	yellow_shader_program := gl.CreateProgram()
	gl.AttachShader(yellow_shader_program, vertex_shader)
	gl.AttachShader(yellow_shader_program, yellow_fragment_shader)
	gl.LinkProgram(yellow_shader_program)
	gl.GetProgramiv(yellow_shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		fmt.eprintln("error linking shader program:")
		info_log: [512]u8
		gl.GetProgramInfoLog(yellow_shader_program, 512, nil, &info_log[0])
		fmt.eprintln(info_log)
		panic("shader program error")
	}

	// once linked into a program, we can delete the shaders
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(orange_fragment_shader)
	gl.DeleteShader(yellow_fragment_shader)

	// wireframe mode
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	// render loop
	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// clear the buffer
		gl.ClearColor(.2, .3, .3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// draw in the buffer
		gl.UseProgram(orange_shader_program)
		gl.BindVertexArray(vaos[0])
		gl.DrawArrays(gl.TRIANGLES, 0, 3)
		gl.UseProgram(yellow_shader_program)
		gl.BindVertexArray(vaos[1])
		gl.DrawArrays(gl.TRIANGLES, 0, 3)
		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		gl.BindVertexArray(0)
		gl.UseProgram(0)

		// check and call events and swap buffers
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, w, h: i32) {
	gl.Viewport(0, 0, w, h)
}

error_callback :: proc "c" (error: i32, desc: cstring) {
	context = runtime.default_context()
	fmt.eprintln("GLFW error:", desc)
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}
