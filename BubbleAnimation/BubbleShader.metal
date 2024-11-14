#include <metal_stdlib>
using namespace metal;

struct Bubble {
    float2 position;
    float size;
    float4 color;
    float speed;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float size [[point_size]];
};

vertex VertexOut bubbleVertex(const device Bubble* bubbles [[buffer(0)]],
                            uint vid [[vertex_id]]) {
    Bubble bubble = bubbles[vid];
    
    VertexOut out;
    out.position = float4(bubble.position, 0, 1);
    out.color = bubble.color;
    out.size = bubble.size;
    
    return out;
}

fragment float4 bubbleFragment(VertexOut in [[stage_in]],
                             float2 pointCoord [[point_coord]]) {
    float2 coord = pointCoord * 2.0 - 1.0;
    float dist = length(coord);
    
    if (dist > 1.0) {
        discard_fragment();
    }
    
    float alpha = smoothstep(1.0, 0.8, dist);
    return float4(in.color.rgb, in.color.a * alpha);
} 