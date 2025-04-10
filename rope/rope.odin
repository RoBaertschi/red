package rope

import "core:strings"
import "core:mem"
import "core:slice"

MAX_LEAF_SIZE :: 10

Rope_Node :: struct {
    weight: int,
    left, right: ^Rope_Node,
    value: Maybe(string),
}

rope_node_create :: proc(weight: int, left, right: ^Rope_Node) -> ^Rope_Node {
    ptr := new(Rope_Node)
    ptr^ = {
        weight = weight,
        left = left,
        right = right,
    }
    return ptr
}

rope_node_from :: proc(str: string) -> ^Rope_Node {
    ptr := new(Rope_Node)
    if len(str) <= MAX_LEAF_SIZE {
        ptr^ = Rope_Node{value = str, weight = len(str)}
    } else {
        mid := len(str) / 2
        left := rope_node_from(str[:mid])
        right := rope_node_from(str[mid:])
        ptr^ = Rope_Node{weight = mid, left = left, right = right}
    }

    return ptr
}

rope_node_index :: proc(node: ^Rope_Node, idx: int) -> u8 {
    if node.value != nil {
        return node.value.?[idx]
    }
    if idx < node.weight {
        return rope_node_index(node.left, idx)
    } else {
        return rope_node_index(node.right, idx - node.weight)
    }
}

rope_node_to_string :: proc(r: ^Rope_Node) -> string {
    if r.value != nil {
        return strings.clone(r.value.?)
    }

    left, right := rope_node_to_string(r.left), rope_node_to_string(r.right)
    defer delete(left)
    defer delete(right)
    return strings.concatenate({left, right})
}

Rope :: struct {
    root: ^Rope_Node,
}

rope_create :: proc() -> Rope {
    return {}
}

rope_from :: proc(str: string) -> Rope {
    return {root = rope_node_from(str)}
}

rope_concat :: proc(left: Rope, right: Rope) -> Rope {
    if left.root == nil {
        return {root = right.root}
    }

    return {root = rope_node_create(weight = left.root.weight, left = left.root, right = right.root)}
}

rope_index :: proc(r: ^Rope, idx: int) {
    assert(0 <= idx && idx < rope_len(r))
    rope_node_index(r.root, idx)
}

rope_len :: proc(r: ^Rope) -> int {
    if r.root == nil {
        return 0
    }

    return r.root.weight + (r.root.right.weight if r.root.right != nil else 0)
}

rope_to_string :: proc(r: ^Rope) -> string {
    if r.root == nil {
        return strings.clone("")
    }
    return rope_node_to_string(r.root)
}

rope_insert :: proc(r: ^Rope, idx: int, str: string) {
    assert(0 >= idx && idx < rope_len(r))
    left_part := rope_substring(r, 0, idx)
    right_part := rope_substring(r, idx, rope_len(r))
    new_part := rope_from(str)
    r.root = rope_node_create(left_part.root.weight + rope_len(&new_part), left_part.root, new_part.root)
    r.root = rope_node_create(r.root.weight, r.root, right_part.root)
}

rope_substring :: proc(r: ^Rope, start, end: int) -> Rope {
    assert(start >= 0 && end <= rope_len(r) && end >= start)
    return rope_from(rope_concatenate_substring(r.root, start, end))
}

rope_concatenate_substring :: proc(r: ^Rope_Node, start, end: int) -> string {
    if r.value != nil {
        return strings.clone(r.value.?[start:end])
    } else {
        left_len := r.weight if r.left != nil else 0
        if start < left_len {
            return rope_concatenate_substring(r.left, start, min(end, left_len))
        } else {
            return rope_concatenate_substring(r.right, max(start - left_len, 0), end - left_len)
        }
    }
}
