
#include <metal_stdlib>
using namespace metal;

// CAMERA SHADERS
// --------------

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

vertex TextureMappingVertex vertex_camera_main(unsigned int vertex_id [[ vertex_id ]]) {
    float4x4 renderedCoordinates = float4x4(float4( -1.0, -1.0, 0.0, 1.0 ),
                                            float4(  1.0, -1.0, 0.0, 1.0 ),
                                            float4( -1.0,  1.0, 0.0, 1.0 ),
                                            float4(  1.0,  1.0, 0.0, 1.0 ));

    float4x2 textureCoordinates = float4x2(float2( 0.0, 1.0 ),
                                           float2( 1.0, 1.0 ),
                                           float2( 0.0, 0.0 ),
                                           float2( 1.0, 0.0 ));
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

fragment half4 fragment_camera_main(TextureMappingVertex mappingVertex [[ stage_in ]],
                                    texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    return half4(texture.sample(s, mappingVertex.textureCoordinate));
    
    if (mappingVertex.textureCoordinate.y > 0.8) {
        half c = floor(10 * mappingVertex.textureCoordinate.x) / 10;
        return half4(c, c, c, 1.0);
    }
    
    half d = texture.sample(s, mappingVertex.textureCoordinate).r;
    return half4(d, d, d, 1.0);
}

// GRAPHICS SHADERS
// ----------------

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float2 texCoords;
    float2 camCoords;
};

struct Light {
    float3 worldPosition;
    float3 color;
};

struct VertexUniforms {
    float4x4 viewProjectionMatrix;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

#define LightCount 3

struct FragmentUniforms {
    float3 cameraWorldPosition;
    float3 ambientLightColor;
    float3 specularColor;
    float specularPower;
    Light lights[LightCount];
    float bob_z;
};

vertex VertexOut vertex_main(VertexIn vertexIn [[stage_in]],
                             constant VertexUniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    float4 worldPosition = uniforms.modelMatrix * float4(vertexIn.position, 1);
    vertexOut.position = uniforms.viewProjectionMatrix * worldPosition;

    vertexOut.worldPosition = worldPosition.xyz;
    vertexOut.worldNormal = uniforms.normalMatrix * vertexIn.normal;
    vertexOut.texCoords = vertexIn.texCoords;
    vertexOut.camCoords = (float2(0.5, -0.5) * (vertexOut.position.xy / vertexOut.position.w)) + float2(0.5, 0.5);

    return vertexOut;
}

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]],
                              constant FragmentUniforms &uniforms [[buffer(0)]],
                              texture2d<float, access::sample> imageTexture [[texture(0)]],
                              texture2d<float, access::sample> depthTexture [[texture(1)]],
                              texture2d<float, access::sample> baseColorTexture [[texture(2)]],
                              sampler textureSampler [[sampler(0)]])
{
    float worldDepth = depthTexture.sample(textureSampler, fragmentIn.camCoords).r;
    float scaledDepth = clamp(3 * worldDepth, 0, 1);
    float depth = floor(10 * scaledDepth) / 10;
    // range 0 to 1
    float bob_z = uniforms.bob_z;
    
    float3 baseColor;

    if (depth > bob_z) {
        baseColor = baseColorTexture.sample(textureSampler, fragmentIn.camCoords).rgb;
    } else {
        baseColor = imageTexture.sample(textureSampler, fragmentIn.camCoords).rgb;
        return float4(baseColor, 1.0);
    }
    
    float3 specularColor = uniforms.specularColor;
    
    float3 N = normalize(fragmentIn.worldNormal);
    float3 V = normalize(uniforms.cameraWorldPosition - fragmentIn.worldPosition);

    float3 finalColor(0, 0, 0);
    for (int i = 0; i < LightCount; ++i) {
        float3 L = normalize(uniforms.lights[i].worldPosition - fragmentIn.worldPosition.xyz);
        float3 diffuseIntensity = saturate(dot(N, L));
        float3 H = normalize(L + V);
        float specularBase = saturate(dot(N, H));
        float specularIntensity = powr(specularBase, uniforms.specularPower);
        float3 lightColor = uniforms.lights[i].color;
        finalColor += uniforms.ambientLightColor * baseColor +
                      diffuseIntensity * lightColor * baseColor +
                      specularIntensity * lightColor * specularColor;
    }

    return float4(finalColor, 1);
}
