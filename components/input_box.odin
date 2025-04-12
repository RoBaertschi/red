package components

import "core:fmt"
import "core:unicode/utf8"

import fs "vendor:fontstash"

import r "../rendering"

Base_Component :: struct {
    pos: [2]f32,
    size: [2]f32,
}

Input_Box :: struct {
    using base: Base_Component,

    // TODO: Replace with rope at some point
    content: [dynamic]rune,

    // the cursor position emulates the neovim one
    //1
    // ^ the columns and rows starts at zero
    //
    // The insert cursor is left to the current character
    // abcd
    // ^ Normal cursor here
    //^^ Insert cursor between these two
    //
    // There is also a difference between the last horizontal cursor position and the current one. If you move the
    // cursor down to a line that is shorter than the current one, the horizontal will
    // be retained after going back on a longer line. like this:
    // abcdefg
    //       ^ Cursor is here
    // abc
    //   ^ Cursor is at the end of line
    // abcdefghijklmnop
    //       ^ Cursor goes back to here
    //
    // This only works if the user does no horizontal position change while moving between the lines.
    // The best way to handle this is just to clamp the cursor position while rendering to the line
    cursor_pos: [2]int,
    // Position in the string
    content_pos: int,
}

Input_Box_Desc :: struct {
    pos: [2]f32,
    size: [2]f32,
}

input_box_make :: proc(desc: Input_Box_Desc) -> Input_Box {
    return {
        pos = desc.pos,
        size = desc.size,
        content = make([dynamic]rune),
    }
}

input_box_handle_char :: proc(ib: ^Input_Box, char: rune) {
    append(&ib.content, char)
    ib.cursor_pos.x += 1
    ib.content_pos += 1
}

input_box_render :: proc(ib: ^Input_Box, renderer: ^r.Renderer) {
    content := utf8.runes_to_string(ib.content[:], context.temp_allocator)

    pos : [2]f32 = {30, 70}
    r.text(renderer, content, {30, 70})

    bounds := [4]f32{}
    r.text_bounds(renderer, content[:ib.content_pos], pos, &bounds)

    cursor_draw_pos := bounds[2]
    pos.x = cursor_draw_pos

    _, _, height := r.text_vertical_metrics(renderer)

    r.rectangle(renderer, pos, {20, height}, {1, 1, 1, 1})
}
