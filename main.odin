package learnopengl

import "base:runtime"

import "core:fmt"
import "core:math/linalg"
import glm "core:math/linalg/glsl"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stb "vendor:stb/image"

delta_time: f64
last_frame: f64

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

last_x: f32 = SCREEN_WIDTH / 2
last_y: f32 = SCREEN_HEIGHT / 2

camera := camera_create(glm.vec3{0, 0, 3})

first_mouse := true

light_pos := glm.vec3{1.2, 1.0, 2.0}

vertices := [?]f32 {
	-0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5, -0.5, -0.5,  0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
     0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5,  0.5, -0.5,  0.0,  0.0, -1.0,
    -0.5, -0.5, -0.5,  0.0,  0.0, -1.0,

    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
     0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5,  0.5,  0.5,  0.0,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0,  0.0, 1.0,

    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0,  0.0,  0.0,
    -0.5, -0.5,  0.5, -1.0,  0.0,  0.0,
    -0.5,  0.5,  0.5, -1.0,  0.0,  0.0,

     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5, -0.5,  1.0,  0.0,  0.0,
     0.5, -0.5,  0.5,  1.0,  0.0,  0.0,
     0.5,  0.5,  0.5,  1.0,  0.0,  0.0,

    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5, -0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
     0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5,  0.5,  0.0, -1.0,  0.0,
    -0.5, -0.5, -0.5,  0.0, -1.0,  0.0,

    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
     0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    -0.5,  0.5, -0.5,  0.0,  1.0,  0.0,
}

main :: proc() {
	glfw.InitHint(glfw.PLATFORM, glfw.PLATFORM_X11)
	if !glfw.Init() {
		fmt.eprintln("failed to initialize GLFW")
		panic("glfw init error")
	}
	defer glfw.Terminate()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 6)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "LearnOpenGL", nil, nil)
	if window == nil {
		fmt.eprintln("failed to create GLFW window")
		glfw.Terminate()
		panic("glfw window error")
	}
	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	glfw.SetErrorCallback(error_callback)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	// load OpenGL function pointers, must be done before calling any other gl
	// functions and after the window is made the current context
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Enable(gl.DEPTH_TEST)

	cube_vao: u32
	gl.GenVertexArrays(1, &cube_vao)
	defer gl.DeleteVertexArrays(1, &cube_vao)

	vbo: u32
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteBuffers(1, &vbo)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW)

	gl.BindVertexArray(cube_vao)
	// tell OpenGL how to read the vertex data
	// position data
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	// normal data
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

	light_vao: u32
	gl.GenVertexArrays(1, &light_vao)
	defer gl.DeleteVertexArrays(1, &light_vao)

	gl.BindVertexArray(light_vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	shader_program, shader_ok := gl.load_shaders("shaders/container.vert.glsl", "shaders/container.frag.glsl")
	if !shader_ok {
		msg, shader := gl.get_last_error_message()
		fmt.eprintln(shader, "compile error:", msg)
		panic("failed loading shaders")
	}
	defer gl.DeleteProgram(shader_program)

	light_shader_program, light_shader_ok := gl.load_shaders("shaders/light.vert.glsl", "shaders/light.frag.glsl")
	if !light_shader_ok {
		msg, shader := gl.get_last_error_message()
		fmt.eprintln(shader, "compile error:", msg)
		panic("failed loading light shaders")
	}
	defer gl.DeleteProgram(light_shader_program)

	// wireframe mode
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	objectColorLoc := gl.GetUniformLocation(shader_program, "objectColor")
	lightColorLoc := gl.GetUniformLocation(shader_program, "lightColor")
	lightPosLoc := gl.GetUniformLocation(shader_program, "lightPos")
	viewPosLoc := gl.GetUniformLocation(shader_program, "viewPos")

	modelLoc := gl.GetUniformLocation(shader_program, "model")
	viewLoc := gl.GetUniformLocation(shader_program, "view")
	projectionLoc := gl.GetUniformLocation(shader_program, "projection")

	lightModelLoc := gl.GetUniformLocation(light_shader_program, "model")
	lightViewLoc := gl.GetUniformLocation(light_shader_program, "view")
	lightProjectionLoc := gl.GetUniformLocation(light_shader_program, "projection")

	// render loop
	for !glfw.WindowShouldClose(window) {
		// delta time
		current_frame := glfw.GetTime()
		delta_time = current_frame - last_frame
		last_frame = current_frame

		// input
		process_input(window)

		// clear the buffer
		gl.ClearColor(.1, .1, .1, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		light_pos.x = cast(f32)glm.cos(current_frame) * 2
		light_pos.y = cast(f32)glm.cos(current_frame) * 2
		light_pos.z = cast(f32)glm.sin(current_frame) * 2

		gl.UseProgram(shader_program)
		gl.Uniform3f(objectColorLoc, 1, 0.5, 0.31)
		gl.Uniform3f(lightColorLoc, 1, 1, 1)
		gl.Uniform3fv(lightPosLoc, 1, raw_data(&light_pos))
		// gl.Uniform3fv(viewPosLoc, 1, raw_data(&camera.pos))

		projection := glm.mat4Perspective(glm.radians(camera.zoom), cast(f32)SCREEN_WIDTH/cast(f32)SCREEN_HEIGHT, 0.1, 100)
		view := camera_view_matrix(&camera)
		gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, raw_data(&projection))
		gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))

		// render boxes
		cube_model := glm.mat4Scale({1, 1, 1})
		gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&cube_model))
		gl.BindVertexArray(cube_vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 36)

		gl.UseProgram(light_shader_program)
		gl.UniformMatrix4fv(lightProjectionLoc, 1, gl.FALSE, raw_data(&projection))
		gl.UniformMatrix4fv(lightViewLoc, 1, gl.FALSE, raw_data(&view))
		gl.BindVertexArray(light_vao)
		model := glm.mat4Translate(light_pos)
		model *= glm.mat4Scale({0.2, 0.2, 0.2})
		gl.UniformMatrix4fv(lightModelLoc, 1, gl.FALSE, raw_data(&model))
		gl.DrawArrays(gl.TRIANGLES, 0, 36)

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
	camera_speed: f32 = 2.5 * f32(delta_time)
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
	if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
		process_keyboard(&camera, .FORWARD, delta_time)
	}
	if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
		process_keyboard(&camera, .BACKWARD, delta_time)
	}
	if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
		process_keyboard(&camera, .LEFT, delta_time)
	}
	if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
		process_keyboard(&camera, .RIGHT, delta_time)
	}
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x_in, y_in: f64) {
	x := cast(f32)x_in
	y := cast(f32)y_in

	if first_mouse {
		last_x = x
		last_y = y
		first_mouse = false
	}

	x_offset := x - last_x
	y_offset := last_y - y
	last_x = x
	last_y = y

	process_mouse(&camera, x_offset, y_offset)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
	process_scroll(&camera, cast(f32)yoffset)
}
