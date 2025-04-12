package rendering

import "core:c"
import "core:math/linalg"

import sg "sokol:gfx"

import tr "text_renderer"
import "../shaders"

Vertex :: struct #packed {
    position: [3]f32,
    color: [4]f32,
}

Renderer :: struct {
    trs: tr.Text_Rendering_State,
    vertices: [dynamic]Vertex, // allocated
    buffer: sg.Buffer,
    buffer_size: c.size_t, // this tracks the current size of the buffer
    shd: sg.Shader,
    pip: sg.Pipeline,
    bnd: sg.Bindings,
    params: shaders.Basic_Vs_Params,
}

DEFAULT_BUFFER_SIZE :: 1024

setup :: proc() -> Renderer {
    r := Renderer{trs = tr.setup({})}

    r.buffer = sg.make_buffer({usage = .DYNAMIC, size = DEFAULT_BUFFER_SIZE * size_of(Vertex) })
    r.buffer_size = DEFAULT_BUFFER_SIZE
    r.shd = sg.make_shader(shaders.basic_shader_desc(sg.query_backend()))
    r.pip = sg.make_pipeline({
        shader = r.shd,
        layout = {
            attrs = {
                shaders.ATTR_basic_position = {format = .FLOAT3},
                shaders.ATTR_basic_color0 = {format = .FLOAT4},
            },
        },
    })
    r.bnd = {
        vertex_buffers = {0 = r.buffer},
    }

    return r
}

text :: proc(r: ^Renderer, text: string, pos: [2]f32, size: f32 = 36, color: [3]f32 = {1, 1, 1}, blur: f32 = 0, spacing: f32 = 0) {
    tr.draw_text(
        &r.trs,
        text,
        pos,
        size,
        color,
        blur,
        spacing
    )
}

text_bounds :: proc(r: ^Renderer, text: string, pos: [2]f32 = {0, 0}, bounds: ^[4]f32) -> f32 {
    return tr.text_bounds(&r.trs, text, pos, bounds)
}

text_vertical_metrics :: proc(r: ^Renderer) -> (ascender, descender, line_height: f32) {
    return tr.vertical_metrics(&r.trs)
}

triangle :: proc(r: ^Renderer, vertices: [3][3]f32, color: [4]f32) {
    v := [3]Vertex{
        {position = vertices[0], color = color},
        {position = vertices[1], color = color},
        {position = vertices[2], color = color},
    }

    append(&r.vertices, ..v[:])
}

rectangle :: proc(r: ^Renderer, pos: [2]f32, size: [2]f32, color: [4]f32) {
    triangle(r, {
        {pos.x, pos.y, 0}, // Top left
        {pos.x + size.x, pos.y, 0}, // Top right
        {pos.x, pos.y + size.y, 0}, // Bottom left
    }, color)

    triangle(r, {
        {pos.x + size.x, pos.y, 0}, // Top right
        {pos.x, pos.y + size.y, 0}, // Bottom left
        {pos.x + size.x, pos.y + size.y, 0}, // Bottom right
    }, color)
}

@(private)
update_buffer :: proc(r: ^Renderer) {
    if r.buffer_size < len(r.vertices) {
        sg.destroy_buffer(r.buffer)
        for r.buffer_size < len(r.vertices) {
            r.buffer_size *= 2
        }
        r.buffer = sg.make_buffer({usage = .DYNAMIC, size = r.buffer_size * size_of(Vertex)})
        r.bnd.vertex_buffers[0] = r.buffer
    }
    sg.update_buffer(r.buffer, {size = len(r.vertices) * size_of(Vertex), ptr = raw_data(r.vertices)})
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

    update_buffer(r)
    update_projection(r, f32(w), f32(h))
    sg.apply_pipeline(r.pip)
    sg.apply_bindings(r.bnd)
    sg.apply_uniforms(shaders.UB_basic_vs_params, {ptr = &r.params, size = size_of(r.params)})
    sg.draw(0, c.int(len(r.vertices)), 1)

    clear(&r.vertices)
}

shutdown :: proc(r: Renderer) {
    tr.shutdown(r.trs)
    sg.destroy_pipeline(r.pip)
    sg.destroy_shader(r.shd)
    sg.destroy_buffer(r.buffer)
}
