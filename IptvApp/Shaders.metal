#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              const device float *vertices [[buffer(0)]]) {
    VertexOut out;

    float2 pos = float2(vertices[vertexID * 4 + 0], vertices[vertexID * 4 + 1]);
    float2 tex = float2(vertices[vertexID * 4 + 2], vertices[vertexID * 4 + 3]);

    out.position = float4(pos, 0, 1);
    out.texCoord = tex;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    return tex.sample(s, in.texCoord);
}
