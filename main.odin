package main

import "base:runtime"
import slog "sokol:log"
import sg "sokol:gfx"
import sglue "sokol:glue"
import "vendor:glfw"
import st "state"

import "core:fmt"

import "shaders"
import r "rendering"

main :: proc() {
    status, desc, code := glfw_init({ title = "red", width = 800, height = 600 })

    if status != .Ok {
        fmt.printfln("glfw backend failed %v, code: %v, desc: %q", status, desc, code)
        return
    }

    defer glfw_shutdown()

    sg.setup({
        environment = glfw_environment(),
        logger = { func = slog.func },
    })
    defer sg.shutdown()

    vertices := [?]f32{
        // positions         // colors
         0.0,  0.5, 0.5,     1.0, 0.0, 0.0, 1.0,
         0.5, -0.5, 0.5,     0.0, 1.0, 0.0, 1.0,
        -0.5, -0.5, 0.5,     0.0, 0.0, 1.0, 1.0
    };

    buffer := sg.make_buffer({
        data = {
            ptr = &vertices,
            size = size_of(vertices),
        }
    })
    defer sg.destroy_buffer(buffer)

    shd := sg.make_shader(shaders.triangle_shader_desc(sg.query_backend()))
    defer sg.destroy_shader(shd)

    pip := sg.make_pipeline({
        shader = shd,
        layout = {
            attrs = {
                shaders.ATTR_triangle_position = { format = .FLOAT3 },
                shaders.ATTR_triangle_color0 = { format = .FLOAT4 },
            },
        },
    })
    defer sg.destroy_pipeline(pip)

    bind := sg.Bindings{
        vertex_buffers = {
            0 = buffer,
        },
    }

    renderer := r.setup()
    defer r.shutdown(renderer)

    for !glfw.WindowShouldClose(glfw_window()) {
        {
            sg.begin_pass({ swapchain = glfw_swapchain(), action = { colors = { 0 = { load_action = .CLEAR, clear_value = { 0.2, 0.2, 0.2, 1 } } } } })
            defer sg.end_pass()

            r.text(&renderer, "Hello World", {30, 30})
            r.frame(&renderer, glfw_size_int())

            st.render(glfw_state(), &renderer)
        }
        sg.commit()
        glfw.SwapBuffers(glfw_window())
        glfw.PollEvents()

        free_all(context.temp_allocator)
    }
}
