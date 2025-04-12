package main

import "core:c"
import "base:runtime"

import "vendor:glfw"
import st "state"

import sg "sokol:gfx"

Glfw_Desc :: struct {
	width:           c.int,
	height:          c.int,
	title:           cstring,
	sample_count:    c.int,
	no_depth_buffer: bool,
	version_major:   c.int,
	version_minor:   c.int,
    state:           st.State,
}

@(private = "file")
Glfw_State :: struct {
	sample_count:    c.int,
	no_depth_buffer: bool,
	version_major:   c.int,
	version_minor:   c.int,
	window:          glfw.WindowHandle,
    state:           st.State,
}

state := Glfw_State{}

Glfw_Status :: enum {
    Ok,
    Init_Failed,
    Create_Window_Failed,
}

glfw_init :: proc(desc: Glfw_Desc) -> (status: Glfw_Status, err_desc: string, glfw_code: i32) {
	assert(desc.width > 0)
	assert(desc.height > 0)
	assert(desc.title != nil)
	glfw_def :: proc(val: c.int, def: c.int) -> c.int {
		if val == 0 {
			return def
		} else {
			return val
		}
	}

	desc_def := desc

	desc_def.sample_count       = glfw_def(desc_def.sample_count, 1)
	desc_def.version_major      = glfw_def(desc_def.version_major, 4)
	desc_def.version_minor      = glfw_def(desc_def.version_minor, 3)
	state.sample_count          = desc_def.sample_count
	state.no_depth_buffer       = desc_def.no_depth_buffer
	state.version_major         = desc_def.version_major
	state.version_minor         = desc_def.version_minor
    state.state                 = desc_def.state

	if !glfw.Init() {
        return .Init_Failed, glfw.GetError()
    }
	glfw.WindowHint(glfw.COCOA_RETINA_FRAMEBUFFER, false)
	if (desc_def.no_depth_buffer) {
		glfw.WindowHint(glfw.DEPTH_BITS, false)
		glfw.WindowHint(glfw.STENCIL_BITS, false)
	}

	sample_count := cast(c.int)0
	if desc_def.sample_count != 1 {
		sample_count = desc_def.sample_count
	}

	glfw.WindowHint(glfw.SAMPLES, sample_count)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, desc_def.version_major)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, desc_def.version_minor)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, true)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	state.window = glfw.CreateWindow(desc_def.width, desc_def.height, desc_def.title, nil, nil)
    if state.window == nil {
        glfw.Terminate()
        return .Create_Window_Failed, glfw.GetError()
    }

	glfw.MakeContextCurrent(state.window)
	glfw.SwapInterval(1)

    glfw.SetWindowUserPointer(state.window, &state.state)
    glfw.SetCharCallback(state.window, glfw_character_callback)

    return
}

glfw_state :: proc() -> ^st.State {
    return &state.state
}

@(private="file")
glfw_character_callback :: proc "c" (window: glfw.WindowHandle, cope: rune) {
    context = runtime.default_context()
    state := cast(^st.State) glfw.GetWindowUserPointer(window)
    st.handle_character_callback(state, cope)
}

glfw_shutdown :: proc() {
    glfw.DestroyWindow(state.window)
    glfw.Terminate()
}

glfw_width :: proc() -> c.int {
	width, _: c.int = glfw.GetFramebufferSize(state.window)
	return width
}

glfw_height :: proc() -> c.int {
	_, height: c.int = glfw.GetFramebufferSize(state.window)
	return height
}

glfw_size :: proc() -> (c.int, c.int) {
    return glfw.GetFramebufferSize(state.window)
}

glfw_size_int :: proc() -> (int, int) {
    w, h := glfw.GetFramebufferSize(state.window)
    return int(w), int(h)
}

glfw_environment :: proc() -> sg.Environment {
	return {
		defaults = {
			color_format = .RGBA8,
			depth_format = .NONE if state.no_depth_buffer else .DEPTH_STENCIL,
			sample_count = state.sample_count,
		},
	}
}

glfw_swapchain :: proc() -> sg.Swapchain {
	width, height: c.int = glfw.GetFramebufferSize(state.window)

	return {
		width = width,
		height = height,
		sample_count = state.sample_count,
		color_format = .RGBA8,
		depth_format = .NONE if state.no_depth_buffer else .DEPTH_STENCIL,
		gl = {

			// TODO(robin): Add Metal support

			// we just assume here that the GL framebuffer is always 0
			framebuffer = 0,
		},
	}
}

glfw_window :: proc() -> glfw.WindowHandle {
	return state.window
}
