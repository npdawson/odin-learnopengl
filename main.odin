package learnopengl

import "base:runtime"

import "core:fmt"
import glm "core:math/linalg/glsl"

import "vendor:glfw"
import gl "vendor:OpenGL"
import stb "vendor:stb/image"

camera_pos := glm.vec3{0, 0, 3}
camera_front := glm.vec3{0, 0, -1}
camera_up := glm.vec3{0, 1, 0}

delta_time: f64
last_frame: f64

yaw: f64 = -90
pitch: f64
last_x: f64 = 400
last_y: f64 = 300
fov: f32 = 45

first_mouse := true

vertices := [?]f32 {
	-0.5, -0.5, -0.5,  0.0, 0.0,
     0.5, -0.5, -0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 0.0,

    -0.5, -0.5,  0.5,  0.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 1.0,
    -0.5,  0.5,  0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,

    -0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5, -0.5,  1.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5,  0.5,  1.0, 0.0,

     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5,  0.5,  0.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,

    -0.5, -0.5, -0.5,  0.0, 1.0,
     0.5, -0.5, -0.5,  1.0, 1.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
     0.5, -0.5,  0.5,  1.0, 0.0,
    -0.5, -0.5,  0.5,  0.0, 0.0,
    -0.5, -0.5, -0.5,  0.0, 1.0,

    -0.5,  0.5, -0.5,  0.0, 1.0,
     0.5,  0.5, -0.5,  1.0, 1.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
     0.5,  0.5,  0.5,  1.0, 0.0,
    -0.5,  0.5,  0.5,  0.0, 0.0,
    -0.5,  0.5, -0.5,  0.0, 1.0,
}

indices := [?]u32 {
	0, 1, 3, // first triangle
	1, 2, 3, // secode triangle
}

cube_positions := [?]glm.vec3 {
	glm.vec3{0, 0, 0},
	glm.vec3{2, 5, -15},
	glm.vec3{-1.5, -2.2, -2.5},
	glm.vec3{-3.8, -2.0, -12.3},
    glm.vec3{ 2.4, -0.4, -3.5},
    glm.vec3{-1.7,  3.0, -7.5},
    glm.vec3{ 1.3, -2.0, -2.5},
    glm.vec3{ 1.5,  2.0, -2.5},
    glm.vec3{ 1.5,  0.2, -1.5},
    glm.vec3{-1.3,  1.0, -1.5},
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

	glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

	// load OpenGL function pointers, must be done before calling any other gl
	// functions and after the window is made the current context
	gl.load_up_to(4, 6, glfw.gl_set_proc_address)

	gl.Viewport(0, 0, 800, 600)
	gl.Enable(gl.DEPTH_TEST)
	glfw.SetWindowSizeCallback(window, framebuffer_size_callback)
	glfw.SetErrorCallback(error_callback)
	glfw.SetCursorPosCallback(window, mouse_callback)
	glfw.SetScrollCallback(window, scroll_callback)

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
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)
	// color data
	// gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), 3 * size_of(f32))
	// gl.EnableVertexAttribArray(1)
	// texture coords
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * size_of(f32), 3 * size_of(f32))
	gl.EnableVertexAttribArray(1)

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
	texture1: u32
	gl.GenTextures(1, &texture1)
	gl.BindTexture(gl.TEXTURE_2D, texture1)
	// set texture wrap/filter options on currently bound texture object
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	// load image from file, get w, h, and number of color channels
	width, height, n_channels: i32
	stb.set_flip_vertically_on_load(1)
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

	// load a 2nd texture
	texture2: u32
	gl.GenTextures(1, &texture2)
	gl.BindTexture(gl.TEXTURE_2D, texture2)
	// set texture wrap/filter options on currently bound texture object
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	// load image from file, get w, h, and number of color channels
	data = stb.load("textures/awesomeface.png", &width, &height, &n_channels, 0)
	if data != nil {
		// load image data into texture
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.eprintln("failed to load texture")
	}
	// don't need the image data anymore
	stb.image_free(data)

	gl.UseProgram(shader_program)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture1"), 0)
	gl.Uniform1i(gl.GetUniformLocation(shader_program, "texture2"), 1)
	// transLoc := gl.GetUniformLocation(shader_program, "transform")

	// model: local -> world coords
	// model := glm.mat4Rotate({1.0, 0.0, 0.0}, glm.radians_f32(-55))
	// view: world -> view coords
	// view := glm.mat4Translate({0, 0, -3})
	// view *= glm.mat4Rotate({1.0, 0.0, 0.0}, glm.radians_f32(25))
	// projection: view -> clip coords
	// projection := glm.mat4Perspective(glm.radians(fov), 800/600, 0.1, 100)
	modelLoc := gl.GetUniformLocation(shader_program, "model")
	// gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))
	viewLoc := gl.GetUniformLocation(shader_program, "view")
	// gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))
	projectionLoc := gl.GetUniformLocation(shader_program, "projection")

	// render loop
	for !glfw.WindowShouldClose(window) {
		// input
		process_input(window)

		// delta time
		current_frame := glfw.GetTime()
		delta_time = current_frame - last_frame
		last_frame = current_frame

		// clear the buffer
		gl.ClearColor(.2, .3, .3, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		// bind texture
		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture1)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, texture2)

		gl.UseProgram(shader_program)

		t := f32(glfw.GetTime())

		projection := glm.mat4Perspective(glm.radians(fov), 800/600, 0.1, 100)
		gl.UniformMatrix4fv(projectionLoc, 1, gl.FALSE, raw_data(&projection))
		view := glm.mat4LookAt(camera_pos,
							   camera_pos + camera_front,
							   camera_up)
		gl.UniformMatrix4fv(viewLoc, 1, gl.FALSE, raw_data(&view))

		// render boxes
		gl.BindVertexArray(vao)
		for i in 0..<10 {
			model := glm.mat4Translate(cube_positions[i])
			angle := 20 * f32(i)
			if i % 3 == 0 {
				model *= glm.mat4Rotate(glm.vec3{0.5, 1.0, 0.0}, glm.radians_f32(50 + angle) * t)
			} else {
				model *= glm.mat4Rotate(glm.vec3{1, 0.3, 0.5}, glm.radians_f32(angle))
			}
			gl.UniformMatrix4fv(modelLoc, 1, gl.FALSE, raw_data(&model))

			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}

		// sint := glm.sin(t)
		// trans2 := glm.mat4Translate({-0.5, 0.5, 0.0})
		// trans2 *= glm.mat4Scale({sint, sint, sint})
		// gl.UniformMatrix4fv(transLoc, 1, gl.FALSE, raw_data(&trans2))
		// gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

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
	player_right := glm.normalize(glm.cross(camera_up, camera_front))
	player_front := glm.normalize(glm.cross(player_right, camera_up))
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
	if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
		camera_pos += camera_speed * player_front
	}
	if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
		camera_pos -= camera_speed * player_front
	}
	if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
		camera_pos -= glm.normalize(glm.cross(camera_front, camera_up)) * camera_speed
	}
	if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
		camera_pos += glm.normalize(glm.cross(camera_front, camera_up)) * camera_speed
	}
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x, y: f64) {
	if first_mouse {
		last_x = x
		last_y = y
		first_mouse = false
	}

	x_offset := x - last_x
	y_offset := last_y - y
	last_x = x
	last_y = y

	sensitivity := 0.1
	x_offset *= sensitivity
	y_offset *= sensitivity

	yaw += x_offset
	pitch += y_offset

	if pitch > 89 { pitch = 89 }
	else if pitch < -89 { pitch = -89 }

	direction: glm.vec3
	direction.x = cast(f32)(glm.cos(glm.radians(yaw)) * glm.cos(glm.radians(pitch)))
	direction.y = cast(f32)glm.sin(glm.radians(pitch))
	direction.z = cast(f32)(glm.sin(glm.radians(yaw)) * glm.cos(glm.radians(pitch)))
	camera_front = glm.normalize(direction)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
	fov -= cast(f32)yoffset
	if fov < 1 { fov = 1 }
	else if fov > 45 { fov = 45 }
}
