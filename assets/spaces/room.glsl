#pragma language glsl3

uniform vec3 eye;
uniform vec3 rightAxis;
uniform vec3 upAxis;
uniform vec3 forwardAxis;
uniform vec2 lens;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vec3 delta = vertex_position.xyz - eye;
    vec3 p = vec3(dot(delta, rightAxis), dot(delta, upAxis), dot(delta, forwardAxis));
    // Positive view-space Z, near 0.1 and far 50, depth-tested on the GPU.
    // LÖVE's offscreen canvas has a top-down texture convention.
    return vec4(p.x / lens.x, -p.y / lens.y, 1.004008 * p.z - 0.200401, p.z);
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image atlas, vec2 uv, vec2 screen_coords) {
    return Texel(atlas, uv) * color;
}
#endif
