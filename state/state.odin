package state

import "../components"
import r "../rendering"
import "base:runtime"

import "core:c"

State :: struct {
	input_box: components.Input_Box,
	ctx:       runtime.Context,
}

render :: proc(s: ^State, renderer: ^r.Renderer) {
	components.input_box_render(&s.input_box, renderer)
}

handle_character_callback :: proc(s: ^State, codepoint: rune) {
	components.input_box_handle_char(&s.input_box, codepoint)
}

handle_key_callback :: proc(s: ^State, key, scancode, action, mods: c.int) {
	components.input_box_handle_key(&s.input_box, key, scancode, action, mods)
}
