SHADERS=triangle.glsl.odin text.glsl.odin basic.glsl.odin
SHDC=../deps/sokol-tools-bin/bin/linux/sokol-shdc

all: $(SHADERS)

%.glsl.odin: %.glsl
	$(SHDC) --input $< --output $@ --slang glsl430:hlsl5:metal_macos --format sokol_odin
