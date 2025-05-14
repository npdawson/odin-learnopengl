package learnopengl

import "core:fmt"
import fp "core:path/filepath"
import "core:strings"

import gl "vendor:OpenGL"
import stb "vendor:stb/image"

import ai "assimp"

Model :: struct {
	meshes:			  [dynamic]Mesh,
	textures_loaded:  [dynamic]Texture,
	directory:		  string,
	gamma_correction: bool,
}

textures_skipped := 0
total_textures := 0

model_load :: proc(path: string) -> (model: Model) {
	flags := ai.PostProcessSteps.Triangulate |
			 ai.PostProcessSteps.GenSmoothNormals |
			 ai.PostProcessSteps.FlipUVs |
			 ai.PostProcessSteps.CalcTangentSpace
	scene := ai.import_file(path, cast(u32)flags)
	if scene == nil || scene.mFlags & cast(u32)ai.SceneFlags.INCOMPLETE != 0 || scene.mRootNode == nil {
		fmt.eprintln("assimp error:", ai.get_error_string())
		return
	}
	model.directory = fp.dir(path)
	model.meshes = make_dynamic_array_len_cap([dynamic]Mesh, 0, scene.mNumMeshes)
	process_node(&model, scene.mRootNode, scene)
	fmt.printfln("skipped %v textures out of %v loading model at %v", textures_skipped, total_textures, path)
	return model
}

model_draw :: proc(model: ^Model, shader: u32) {
	for i in 0 ..< len(model.meshes) {
		mesh_draw(&model.meshes[i], shader)
	}
}

@(private="file")
process_node :: proc(model: ^Model, node: ^ai.Node, scene: ^ai.Scene) {
	// process all the node's meshes, if any
	for i in 0..<node.mNumMeshes {
		mesh := scene.mMeshes[node.mMeshes[i]]
		append_elem(&model.meshes, process_mesh(model, mesh, scene))
	}
	// then do the same for each of its children
	for i in 0..<node.mNumChildren {
		process_node(model, node.mChildren[i], scene)
	}
}

@(private="file")
process_mesh :: proc(model: ^Model, mesh: ^ai.Mesh, scene: ^ai.Scene) -> Mesh {
	vertices := make_slice([]Vertex, mesh.mNumVertices)
	for i in 0..<mesh.mNumVertices {
		vertex: Vertex
		vertex.position = mesh.mVertices[i]
		if mesh.mNormals != nil {
			vertex.normal = mesh.mNormals[i]
		}
		if mesh.mTextureCoords[0] != nil {
			vertex.tex_coords = mesh.mTextureCoords[0][i].xy
			vertex.tangent = mesh.mTangents[i]
			vertex.bitangent = mesh.mBitangents[i]
		}
		// TODO: bones?
		vertices[i] = vertex
	}
	indices := make_slice([]u32, mesh.mNumFaces * 3)
	for i in 0..<mesh.mNumFaces {
		face := mesh.mFaces[i]
		for j in 0..<face.mNumIndices {
			indices[3 * i + j] = face.mIndices[j]
		}
	}
	textures := make_dynamic_array([dynamic]Texture)
	if mesh.mMaterialIndex >= 0 {
		material := scene.mMaterials[mesh.mMaterialIndex]
		diffuse_maps := load_material_textures(model, material, .DIFFUSE)
		append_elems(&textures, ..diffuse_maps)
		specular_maps := load_material_textures(model, material, .SPECULAR)
		append_elems(&textures, ..specular_maps)
		normal_maps := load_material_textures(model, material, .NORMALS)
		append_elems(&textures, ..normal_maps)
		height_maps := load_material_textures(model, material, .HEIGHT)
		append_elems(&textures, ..height_maps)
	}
	return mesh_create(vertices, indices, textures[:])
}

@(private="file")
load_material_textures :: proc(
	model: ^Model,
	mat: ^ai.Material,
	type: ai.TextureType,
) -> []Texture {
	texture_count := ai.get_material_textureCount(mat, type)
	total_textures += cast(int)texture_count
	textures := make_slice([]Texture, texture_count)
	for i in 0..<texture_count {
		str: ai.String
		res := ai.get_material_texture(mat, type, i, &str)
		if res != .SUCCESS {
			fmt.eprintln("error getting material texture #", i)
			fmt.eprintln("result:", res)
			panic("ai.get_material_texture did not succeed")
		}
		path := strings.string_from_ptr(raw_data(&str.data), cast(int)str.length)
		skip := false
		for texture in model.textures_loaded {
			if strings.compare(texture.path, path) == 0 {
				textures[i] = texture
				skip = true
				textures_skipped += 1
				break
			}
		}
		if !skip {
			texture: Texture
			texture.id = load_texture_from_dir(path, model.directory)
			switch type {
			case .DIFFUSE:
				texture.type = .Diffuse
			case .SPECULAR:
				texture.type = .Specular
			case .NORMALS:
				texture.type = .Normal
			case .HEIGHT:
				texture.type = .Height
			case .NONE, .AMBIENT, .OPACITY, .UNKNOWN, .EMISSIVE, .LIGHTMAP, .SHININESS, .REFLECTION, .DISPLACEMENT:
				fmt.eprintln("unhandled texture type: ", type)
				panic("unsupported texture type!")
			}
			texture.path = path
			textures[i] = texture
			append_elem(&model.textures_loaded, texture)
		}
	}
	return textures
}

@(private="file")
load_texture_from_dir :: proc(path, dir: string, gamma: bool = false) -> (id: u32) {
	full_path := strings.clone_to_cstring(fp.join({dir, path}, context.temp_allocator), context.temp_allocator)
	defer free_all(context.temp_allocator)

	gl.GenTextures(1, &id)

	width, height, num_components: i32
	data := stb.load(full_path, &width, &height, &num_components, 0)
	defer stb.image_free(data)
	if data != nil {
		format: i32
		switch num_components {
		case 1:
			format = gl.RED
		case 3:
			format = gl.RGB
		case 4:
			format = gl.RGBA
		}
		gl.BindTexture(gl.TEXTURE_2D, id)
		gl.TexImage2D(gl.TEXTURE_2D, 0, format, width, height, 0, u32(format), gl.UNSIGNED_BYTE, data)
		gl.GenerateMipmap(gl.TEXTURE_2D)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	} else {
		fmt.eprintln("failed to load texture at path:", path)
	}

	return id
}
