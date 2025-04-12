@header package shaders
@header import "core:math/linalg"
@header import sg "sokol:gfx"
@ctype mat4 linalg.Matrix4f32
@vs basic_vs

layout(binding=0) uniform basic_vs_params {
   mat4 proj;
};

in vec3 position;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = proj * vec4(position, 1.0);
    color = color0;
}
@end

@fs basic_fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program basic basic_vs basic_fs
