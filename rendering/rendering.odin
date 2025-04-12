package rendering

import "core:c"
import "core:math/bits"
import "core:math/linalg"

import sg "sokol:gfx"

import "../shaders"
import tr "text_renderer"

Vertex :: struct #packed {
	position: [3]f32,
	color:    [4]f32,
}

Renderer :: struct {
	trs:       tr.Text_Rendering_State,
	vertices:  [dynamic]Vertex, // allocated
	indices:   [dynamic]u16,
	vbuf:      sg.Buffer,
	vbuf_size: c.size_t, // this tracks the current size of the vertex buffer
	ibuf:      sg.Buffer,
	ibuf_size: c.size_t, // this tracks the current size of the index buffer
	shd:       sg.Shader,
	pip:       sg.Pipeline,
	bnd:       sg.Bindings,
	params:    shaders.Basic_Vs_Params,
}

DEFAULT_BUFFER_SIZE :: 1024

setup :: proc() -> Renderer {
	r := Renderer {
		trs = tr.setup({}),
	}

	r.vertices = make([dynamic]Vertex)
	r.indices = make([dynamic]u16)

	r.vbuf = sg.make_buffer({usage = .DYNAMIC, size = DEFAULT_BUFFER_SIZE * size_of(Vertex)})
	r.vbuf_size = DEFAULT_BUFFER_SIZE

	r.ibuf = sg.make_buffer(
		{type = .INDEXBUFFER, usage = .DYNAMIC, size = DEFAULT_BUFFER_SIZE * size_of(u16)},
	)
	r.ibuf_size = DEFAULT_BUFFER_SIZE

	r.shd = sg.make_shader(shaders.basic_shader_desc(sg.query_backend()))
	r.pip = sg.make_pipeline(
		{
			shader = r.shd,
			layout = {
				attrs = {
					shaders.ATTR_basic_position = {format = .FLOAT3},
					shaders.ATTR_basic_color0 = {format = .FLOAT4},
				},
			},
			index_type = .UINT16,
		},
	)
	r.bnd = {
		vertex_buffers = {0 = r.vbuf},
		index_buffer = r.ibuf,
	}

	return r
}

text :: proc(
	r: ^Renderer,
	text: string,
	pos: [2]f32,
	size: f32 = 36,
	color: [3]f32 = {1, 1, 1},
	blur: f32 = 0,
	spacing: f32 = 0,
) {
	tr.draw_text(&r.trs, text, pos, size, color, blur, spacing)
}

text_bounds :: proc(r: ^Renderer, text: string, pos: [2]f32 = {0, 0}, bounds: ^[4]f32) -> f32 {
	return tr.text_bounds(&r.trs, text, pos, bounds)
}

text_vertical_metrics :: proc(r: ^Renderer) -> (ascender, descender, line_height: f32) {
	return tr.vertical_metrics(&r.trs)
}

triangle :: proc(r: ^Renderer, vertices: [3][3]f32, color: [4]f32) {
	v := [3]Vertex {
		{position = vertices[0], color = color},
		{position = vertices[1], color = color},
		{position = vertices[2], color = color},
	}

	append(&r.vertices, ..v[:])

	assert(len(r.indices) <= bits.U16_MAX)
	indices_len := cast(u16)len(r.indices)
	i := [3]u16{indices_len + 0, indices_len + 1, indices_len + 2}

	append(&r.indices, ..i[:])
}

rectangle :: proc(r: ^Renderer, pos: [2]f32, size: [2]f32, color: [4]f32) {
	assert(len(r.indices) <= bits.U16_MAX)

	v := [4]Vertex {
		{{pos.x, pos.y, 0}, color}, // Top left
		{{pos.x + size.x, pos.y, 0}, color}, // Top right
		{{pos.x, pos.y + size.y, 0}, color}, // Bottom left
		{{pos.x + size.x, pos.y + size.y, 0}, color}, // Bottom right
	}

	append(&r.vertices, ..v[:])

	indices_len := cast(u16)len(r.indices)
	i := [6]u16 {
		// First triangle
		indices_len + 0, // Top left
		indices_len + 1, // Top right
		indices_len + 2, // Bottom left

		// Second triangle
		indices_len + 1, // Top right
		indices_len + 3, // Bottom right
		indices_len + 2, // Bottom left
	}

	append(&r.indices, ..i[:])
}

@(private)
update_buffers :: proc(r: ^Renderer) {
	if r.vbuf_size < len(r.vertices) {
		sg.destroy_buffer(r.vbuf)
		for r.vbuf_size < len(r.vertices) {
			r.vbuf_size *= 2
		}
		r.vbuf = sg.make_buffer({usage = .DYNAMIC, size = r.vbuf_size * size_of(Vertex)})
		r.bnd.vertex_buffers[0] = r.vbuf
	}
	sg.update_buffer(
		r.vbuf,
		{size = len(r.vertices) * size_of(Vertex), ptr = raw_data(r.vertices)},
	)

	if r.ibuf_size < len(r.indices) {
		sg.destroy_buffer(r.ibuf)
		for r.ibuf_size < len(r.indices) {
			r.ibuf_size *= 2
		}
		r.ibuf = sg.make_buffer({type = .INDEXBUFFER, size = r.ibuf_size * size_of(u16)})
		r.bnd.index_buffer = r.ibuf
	}
	sg.update_buffer(r.ibuf, {size = len(r.indices) * size_of(u16), ptr = raw_data(r.indices)})
}

@(private)
update_projection :: proc(r: ^Renderer, width, height: f32) {
	r.params.proj = linalg.matrix_ortho3d(0, width, height, 0, -1, 1)
}

frame :: proc(r: ^Renderer, w, h: int) {
	tr.draw(&r.trs, w, h)

	if len(r.vertices) <= 0 {
		return
	}

	update_buffers(r)
	update_projection(r, f32(w), f32(h))
	sg.apply_pipeline(r.pip)
	sg.apply_bindings(r.bnd)
	sg.apply_uniforms(shaders.UB_basic_vs_params, {ptr = &r.params, size = size_of(r.params)})
	sg.draw(0, c.int(len(r.indices)), 1)

	clear(&r.vertices)
	clear(&r.indices)
}

shutdown :: proc(r: Renderer) {
	delete(r.vertices)
	delete(r.indices)

	tr.shutdown(r.trs)
	sg.destroy_pipeline(r.pip)
	sg.destroy_shader(r.shd)
	sg.destroy_buffer(r.vbuf)
}
