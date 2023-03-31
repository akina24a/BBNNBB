#ifndef H3D_UNLIT_HLSL
#define H3D_UNLIT_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "H3DCommon.hlsl"
#include "H3DDebug.hlsl"

inline void InitVertexPosition(in VertexInput v, inout VertexOutput o)
{
    o.positionCS = TransformObjectToHClip(v.vertex);
}

inline void InitVertexUV(in VertexInput v, inout VertexOutput o)
{
    o.uv.xy = v.uv;
}

inline void InitVertexUV(in VertexInput v, inout VertexOutput o, float4 uv_ST)
{
    o.uv.xy = v.uv * uv_ST.xy + uv_ST.zw;
}

inline void InitVertexNormal(in VertexInput v, inout VertexOutput o)
{
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);
}

inline void InitVertexNormalTangent(in VertexInput v, inout VertexOutput o)
{
    // mikkts space compliant. only normalize when extracting normal at frag.
    o.normalWS = TransformObjectToWorldNormal(v.normalOS);
    half4 tangent;
    tangent.xyz = TransformObjectToWorldDir(v.tangentOS.xyz);
    tangent.w = v.tangentOS.w * GetOddNegativeScale();
    o.tangentWS = tangent;
}

inline void SurfaceClip( H3DSurfaceData surf)
{
    clip( surf.alpha - surf.clipThreshold );
}

half4 GetSurfaceColor (in H3DSurfaceData i)
{
    DEBUG_PROCESS_SURFACE(i)
    // i.color += i.
    return half4(i.albedo, i.alpha);
}

#endif