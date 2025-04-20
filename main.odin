package learnopengl

import "base:runtime"

import "core:fmt"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stb "vendor:stb/image"

vertices := [?]f32 {
	// positions         colors       texture coords
	 0.5,  0.5, 0.0,  1.0, 0.0, 0.0,  1.0, 1.0,	// top right
	 0.5, -0.5, 0.0,  0.0, 1.0, 0.0,  1.0, 0.0,	// bottom right
	-0.5, -0.5, 0.0,  0.0, 0.0, 1.0,  0.0, 0.0,	// bottom left
	-0.5,  0.5, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0,	// top left
}

indices := [?]u32 {
	0, 1, 3, // first triangle
	1, 2, 3, // secode triangle
}

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

	gl.Viewport(0, 0, 800, 600)
	glfw.SetWindowSizeCallback(window, framebuffer_size_callback)
	glfw.SetErrorCallback(error_callback)

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)

	ebo: u32
	gl.GenBuffers(1, &ebo)
	defer gl.DeleteBuffers(1, &ebo)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// tell OpenGL how to read the vertex data
	// position data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	// color data
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)
	// texture coords
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 6 * size_of(f32))
	gl.EnableVertexAttribArray(2)

	shader_program, shader_ok := gl.load_shaders("shaders/triangle.vert", "shaders/triangle.frag")
	if !shader_ok {
		msg, shader := gl.get_last_error_message()
		fmt.eprintln(shader, "compile error:", msg)
		panic("failed loading shaders")
	}
	defer gl.DeleteProgram(shader_program)

	// wireframe mode
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	// create a texture in GL
	texture: u32
	gl.GenTextures(1, &texture)
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	// set texture wrap/filter options on currently bound texture object
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	// load image from file, get w, h, and number of color channels
	width, height, n_channels: i32
	data := stb.load("textures/container.jpg", &width, &height, &n_channels, 0)
	if data != nil {
		// load image data into texture
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data)
		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.eprintln("failed to load texture")
	}
	// don't need the image data anymore
	stb.image_free(data)

	// render loop
	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// clear the buffer
		gl.ClearColor(.2, .3, .3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// bind texture
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture)

		// render contatiner
		gl.UseProgram(shader_program)
		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		gl.BindVertexArray(0)

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
