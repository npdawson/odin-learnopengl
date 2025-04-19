package learnopengl

import "base:runtime"

import "core:fmt"

import gl "vendor:OpenGL"
import "vendor:glfw"

main :: proc() {
	if !glfw.Init() {
		fmt.eprintln("failed to initialize GLFW")
	}
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(800, 600, "LearnOpenGL", nil, nil)
	if window == nil {
		fmt.eprintln("failed to create GLFW window")
		glfw.Terminate()
		return
	}
	glfw.MakeContextCurrent(window)

	// load OpenGL function pointers, must be done before calling any other gl
	// functions and after the window is made the current context
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	glfw.SetWindowSizeCallback(window, framebuffer_size_callback)
	glfw.SetErrorCallback(error_callback)

	// render loop
	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// rendering commands here
		gl.ClearColor(.2, .3, .3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// check and call events and swap buffers
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	glfw.Terminate()
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
