#ifndef H3D_VOLUMETRICFOG_INCLUDE
#define H3D_VOLUMETRICFOG_INCLUDE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/Extend/Shaders/Utils.hlsl"

// #pragma enable_d3d11_debug_symbols

float4x4 _ClipToWorldMatrix;
float4x4 _PrevWorldToClipMatrix;

Texture3D<float4> _ScatteringLightResult;
sampler sampler_ScatteringLightResult;

float4 _VolumetricFogParams[8];

#define _InvVolumeSize _VolumetricFogParams[0].xyz
#define _SkipHistory _VolumetricFogParams[0].w
#define _GridZParams _VolumetricFogParams[1]
#define _Jitter _VolumetricFogParams[2].xyz
#define _Extinction _VolumetricFogParams[2].w
#define _ForwardScatteringColor _VolumetricFogParams[3].xyz
#define _OutsideIntensity _VolumetricFogParams[3].w
#define _BackwardScatteringColor _VolumetricFogParams[4].xyz
#define _HeightFalloff _VolumetricFogParams[4].w
#define _AmbientLight _VolumetricFogParams[5].xyz
#define _DetailTextureIntensity _VolumetricFogParams[5].w
#define _DetailTexture_Speed _VolumetricFogParams[6].xyz
#define _DetailTexture_Tiling _VolumetricFogParams[6].w
#define _NoiseTexture_Speed _VolumetricFogParams[7].xyz
#define _NoiseTexture_Tiling _VolumetricFogParams[7].w
float EyeDepthToVolumeW(float Depth)
{
    return log2(Depth * _GridZParams.x + _GridZParams.y) * _GridZParams.z;
}

float VolumeWToEyeDepth(float W)
{
    return (exp2(W / _GridZParams.z) - _GridZParams.y) / _GridZParams.x;
}

float NDCZToVolumeW(float z)
{
    #if !UNITY_REVERSED_Z
        z = z * 0.5 + 0.5;
    #endif
    return EyeDepthToVolumeW(LinearEyeDepth(z, _ZBufferParams));
}

float3 NDCToWorldPostion(float3 NDC)
{
    #if UNITY_REVERSED_Z
        NDC.y = -NDC.y;
    #endif
    float4 WorldPos = mul(UNITY_MATRIX_I_VP, float4(NDC, 1));
    WorldPos /= WorldPos.w;
    return WorldPos.xyz;
}


float3 CoordinateToWorldPosition(uint3 Coordinate, float3 Offset)
{
    float3 uvw = (Coordinate + Offset) * _InvVolumeSize.xyz;
    
    // 到相机的距离
    float Depth = VolumeWToEyeDepth(uvw.z);
    float3 NDC = float3(uvw.xy * 2 - 1, EyeToClipDepth(Depth));
    return NDCToWorldPostion(NDC);
}

float3 WorldPoitionToPreUVW(float3 WorldPos)
{
    float4 NDC = mul(_PrevWorldToClipMatrix, float4(WorldPos, 1));
    NDC.xyz /= NDC.w;
    // NDC.w 等于Eye空间下，z的值
    return float3(NDC.xy * 0.5 + 0.5, EyeDepthToVolumeW(NDC.w));
}

float3 ApplyVolumetricFog(float3 color, float3 clipPos)
{
    float4 AccumulatedLighting = float4(0, 0, 0, 1);
#if _VOLUMETRIC_FOG
    float ViewSpaceZ = LinearEyeDepth(clipPos.z, _ZBufferParams);
    float2 uv = clipPos.xy * (_ScreenParams.zw - 1);
    bool UseOutside = false;
    if(_Extinction > 0)
    {
        float3 uvw = float3(uv, EyeDepthToVolumeW(ViewSpaceZ));
        AccumulatedLighting = _ScatteringLightResult.Sample(sampler_ScatteringLightResult, uvw);
        if(uvw.z > 1 && _OutsideIntensity > 0)
        {
            UseOutside = true;
        }
    }
    else if(_OutsideIntensity > 0)
    {
        UseOutside = true;
    }
    if(UseOutside)
    {
        float3 WorldPos = NDCToWorldPostion(float3(uv * 2 - 1, clipPos.z));
        float3 V = normalize(_WorldSpaceCameraPos - WorldPos.xyz);
        float3 L = - _MainLightPosition.xyz;
        float FogDistance = _GridZParams.w;
        float3 LightScattering = _AmbientLight + _MainLightColor * lerp(_ForwardScatteringColor, _BackwardScatteringColor, dot(V, L) * 0.5 + 0.5) * INV_TWO_PI;
        float SigmaT = 0.01f * _OutsideIntensity;
        float Transmittance = exp(-SigmaT * (max(ViewSpaceZ - FogDistance, 0)));
        AccumulatedLighting.rgb += LightScattering.rgb * SigmaT * (1 - Transmittance) / max(SigmaT, 0.00001f) * AccumulatedLighting.w;
        AccumulatedLighting.w *= Transmittance;
    }
#endif
    float3 result = AccumulatedLighting.rgb + AccumulatedLighting.w * color;
    return result;
}

float PhaseFunction(float g, float CosTheta)
{
    float k = 3.0 / (8.0 * PI) * (1.0 - g * g) / (2.0 + g * g);
    return k * (1.0 + CosTheta * CosTheta) / pow(1.0 + g * g - 2.0 * g * CosTheta, 1.5);
}

#endif
