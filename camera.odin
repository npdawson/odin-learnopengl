package learnopengl

import glm "core:math/linalg/glsl"

Camera_Movement :: enum {
	FORWARD,
	BACKWARD,
	LEFT,
	RIGHT,
}

YAW :: -90
PITCH :: 0
SPEED :: 2.5
SENSITIVITY :: 0.1
ZOOM :: 45

Camera :: struct {
	pos:               glm.vec3,
	front:             glm.vec3,
	up:                glm.vec3,
	right:             glm.vec3,
	world_up:          glm.vec3,
	yaw:               f32,
	pitch:             f32,
	movement_speed:    f32,
	mouse_sensitivity: f32,
	zoom:              f32,
}

camera_create :: proc(
	pos: glm.vec3 = {0, 0, 0},
	up: glm.vec3 = {0, 1, 0},
	yaw: f32 = YAW,
	pitch: f32 = PITCH,
) -> (
	cam: Camera,
) {
	cam.pos = pos
	cam.front = {0, 0, -1}
	cam.world_up = up
	cam.yaw = yaw
	cam.pitch = pitch
	cam.movement_speed = SPEED
	cam.mouse_sensitivity = SENSITIVITY
	cam.zoom = ZOOM

	update_camera_vectors(&cam)

	return cam
}

camera_view_matrix :: proc(cam: ^Camera) -> glm.mat4 {
	return glm.mat4LookAt(cam.pos, cam.pos + cam.front, cam.up)
}

process_keyboard :: proc(cam: ^Camera, dir: Camera_Movement, delta_t: f64) {
	velocity := cam.movement_speed * cast(f32)delta_t
	switch dir {
	case .FORWARD:
		cam.pos += cam.front * velocity
	case .BACKWARD:
		cam.pos -= cam.front * velocity
	case .LEFT:
		cam.pos -= cam.right * velocity
	case .RIGHT:
		cam.pos += cam.right * velocity
	}
}

process_mouse :: proc "c" (cam: ^Camera, xoffset, yoffset: f32, constrainPitch: bool = true) {
	cam.yaw   += xoffset * cam.mouse_sensitivity
	cam.pitch += yoffset * cam.mouse_sensitivity

	if constrainPitch {
		if cam.pitch > 89 { cam.pitch = 89 }
		else if cam.pitch < -89 { cam.pitch = -89 }
	}

	update_camera_vectors(cam)
}

process_scroll :: proc "c" (cam: ^Camera, yoffset: f32) {
	cam.zoom -= yoffset
	if cam.zoom < 1 { cam.zoom = 1 }
	else if cam.zoom > 45 { cam.zoom = 45 }
}

@(private = "file")
update_camera_vectors :: proc "c" (cam: ^Camera) {
	front: glm.vec3
	front.x = glm.cos(glm.radians(cam.yaw)) * glm.cos(glm.radians(cam.pitch))
	front.y = glm.sin(glm.radians(cam.pitch))
	front.z = glm.sin(glm.radians(cam.yaw)) * glm.cos(glm.radians(cam.pitch))
	cam.front = glm.normalize(front)
	cam.right = glm.normalize(glm.cross(cam.front, cam.world_up))
	cam.up = glm.normalize(glm.cross(cam.right, cam.front))
}
