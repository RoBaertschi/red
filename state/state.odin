package state

import r "../rendering"
import "../components"
import "base:runtime"

State :: struct {
    input_box: components.Input_Box,
    ctx: runtime.Context,
}

render :: proc(s: ^State, renderer: ^r.Renderer) {
    components.input_box_render(&s.input_box, renderer)
}

handle_character_callback :: proc(s: ^State, codepoint: rune) {
    components.input_box_handle_char(&s.input_box, codepoint)
}
