package learnopengl

import "core:fmt"
import glm "core:math/linalg/glsl"

import gl "vendor:OpenGL"

MAX_BONE_INFLUENCE :: 4

Vertex :: struct {
	position:   glm.vec3,
	normal:     glm.vec3,
	tex_coords: glm.vec2,

	tangent:    glm.vec3,
	bitangent:  glm.vec3,

	m_bone_ids: [MAX_BONE_INFLUENCE]i32,
	m_weights:  [MAX_BONE_INFLUENCE]f32,
}

TextureType :: enum {
	Diffuse,
	Specular,
	Normal,
	Height,
}

Texture :: struct {
	id:   u32,
	type: TextureType,
	path: string,
}

Mesh :: struct {
	vertices: []Vertex,
	indices:  []u32,
	textures: []Texture,

	vao:      u32,
	vbo:      u32,
	ebo:      u32,
}

mesh_create :: proc(vertices: []Vertex, indices: []u32, textures: []Texture) -> (mesh: Mesh) {
	mesh.vertices = vertices
	mesh.indices = indices
	mesh.textures = textures

	mesh_setup(&mesh)

	return mesh
}

mesh_draw :: proc(mesh: ^Mesh, shader: u32) {
	diffuse_num := 1
	specular_num := 1
	normal_num := 1
	height_num := 1

	for i in 0 ..< len(mesh.textures) {
		gl.ActiveTexture(gl.TEXTURE0 + cast(u32)i) // activate the proper texture before binding
		// retrieve texture number (the N in diffuse_textureN)
		name: string
		number: int
		switch mesh.textures[i].type {
		case .Diffuse:
			name = "texture_diffuse"
			number = diffuse_num
			diffuse_num += 1
		case .Specular:
			name = "texture_specular"
			number = specular_num
			specular_num += 1
		case .Normal:
			name = "texture_normal"
			number = normal_num
			normal_num += 1
		case .Height:
			name = "texture_height"
			number = height_num
			height_num += 1
		}

		texture_name := fmt.ctprintf("material.%v%v", name, number)
		gl.Uniform1i(uniform(shader, texture_name), cast(i32)i)
		gl.BindTexture(gl.TEXTURE_2D, mesh.textures[i].id)
	}

	// draw mesh
	gl.BindVertexArray(mesh.vao)
	gl.DrawElements(gl.TRIANGLES, cast(i32)len(mesh.indices), gl.UNSIGNED_INT, nil)

	// clean up
	gl.BindVertexArray(0)
	gl.ActiveTexture(gl.TEXTURE0)
	free_all(context.temp_allocator)
}

@(private = "file")
mesh_setup :: proc(mesh: ^Mesh) {
	gl.GenVertexArrays(1, &mesh.vao)
	gl.GenBuffers(1, &mesh.vbo)
	gl.GenBuffers(1, &mesh.ebo)

	gl.BindVertexArray(mesh.vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(mesh.vertices) * size_of(Vertex),
		&mesh.vertices[0],
		gl.STATIC_DRAW,
	)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(mesh.indices) * size_of(u32),
		&mesh.indices[0],
		gl.STATIC_DRAW,
	)

	// vertex positions
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), 0)
	// vertex normals
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))
	// vertex texture coords
	gl.EnableVertexAttribArray(2)
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tex_coords))
	// vertex tangents
	gl.EnableVertexAttribArray(3)
	gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tangent))
	// vertex bitangents
	gl.EnableVertexAttribArray(4)
	gl.VertexAttribPointer(4, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, bitangent))
	// bone ids
	gl.EnableVertexAttribArray(5)
	gl.VertexAttribIPointer(5, MAX_BONE_INFLUENCE, gl.INT, size_of(Vertex), offset_of(Vertex, m_bone_ids))
	// bone weights
	gl.EnableVertexAttribArray(6)
	gl.VertexAttribPointer(6, MAX_BONE_INFLUENCE, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, m_weights))

	// unbind vao
	gl.BindVertexArray(0)
}
