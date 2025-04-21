//
//  Shader.metal
//  MetalSample_1_ColorInvert
//
//  Created by 우영학 on 4/20/25.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
  float4 position [[position]];
  float2 texCoord;
};

vertex VertexOut vertexShader(uint vid [[vertex_id]]) {
  float2 pos[4] = { {-1,-1}, {1,-1}, {-1,1}, {1,1} };
  float2 uv[4]  = { {0,1},    {1,1},    {0,0},    {1,0} };
  VertexOut out;
  out.position = float4(pos[vid], 0, 1);
  out.texCoord = uv[vid];
  return out;
}

fragment float4 filterFragment(VertexOut in [[stage_in]], texture2d<float> inTex [[texture(0)]]) {
  constexpr sampler s(address::clamp_to_edge);
  float4 c = inTex.sample(s, in.texCoord);
  return float4(1.0 - c.rgb, c.a);
}
