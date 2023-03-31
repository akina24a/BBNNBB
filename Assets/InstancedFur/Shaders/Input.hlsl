#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
struct MeshProperties {
    float4x4 mat;
    float3 normal;
    float2 uv;
                
};
TEXTURE2D(_ScaleMap); SAMPLER(sampler_ScaleMap);
TEXTURE2D(_FurBendingRT); SAMPLER(sampler_FurBendingRT);
StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
StructuredBuffer<MeshProperties> _FurProperties;

CBUFFER_START(UnityPerMaterial)
float4 _BaseColor;
float4 _BaseMap_ST;
float4 _HueVariation;
half4 _WindDirection;
half4 _FurDirection;
half _GravityStrength;
half4 _ScalemapInfluence;
half _Cutoff;
half _InnerCutoff;
half _ShadowCutoff;
half _Transparent;
half _InnerTransparent;
half _TranslucencyDirect;
half _TranslucencyIndirect;
half3 _PlayerPos;
half _PushRadius;
half _Strength;

half _OcclusionStrength;

half _NormalFlattening;
half _NormalSpherify;
half _NormalSpherifyMask;



//Wind
half _WindAmbientStrength;
half _WindSpeed;
half _WindVertexRand;
half _WindObjectRand;
half _WindRandStrength;
half _WindSwinging;
half _WindGustStrength;
half _WindGustFreq;



CBUFFER_END
