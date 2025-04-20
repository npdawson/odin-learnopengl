package learnopengl

import "base:runtime"

import "core:fmt"
import "core:math"

import gl "vendor:OpenGL"
import "vendor:glfw"

vertices := [?]f32{
	// positions         colors
	 0.5, -0.5, 0.0,  1.0, 0.0, 0.0,	// bottom right
	-0.5, -0.5, 0.0,  0.0, 1.0, 0.0,	// bottom left
	 0.0,  0.5, 0.0,  0.0, 0.0, 1.0,	// top
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

	vbo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)

	// ebo: u32
	// gl.GenBuffers(1, &ebo)
	// defer gl.DeleteBuffers(1, &ebo)

	vao: u32
	gl.GenVertexArrays(1, &vao)
	defer gl.DeleteVertexArrays(1, &vao)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)
	// gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	// gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// tell OpenGL how to read the vertex data
	// position data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	// color data
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	shader_program, shader_ok := gl.load_shaders("shaders/triangle.vert", "shaders/triangle.frag")
	if !shader_ok {
		panic("failed loading shaders")
	}
	defer gl.DeleteProgram(shader_program)

	// wireframe mode
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	// render loop
	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// clear the buffer
		gl.ClearColor(.2, .3, .3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// activate the shader
		gl.UseProgram(shader_program)

		// calculate shader color
		timeValue := glfw.GetTime()
		greenValue := math.sin(timeValue) / 2 + 0.5
		vertexColorLoc := gl.GetUniformLocation(shader_program, "ourColor")
		gl.Uniform4f(vertexColorLoc, 0, f32(greenValue), 0, 1)

		// draw in the buffer
		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

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
