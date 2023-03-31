#ifndef H3D_COMMEN_HLSL
#define H3D_COMMEN_HLSL
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct VertexInput
{
    float4 vertex       : POSITION;
    float3 normalOS      : NORMAL;
    float4 tangentOS     : TANGENT;
    
    float2 uv : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    float2 lightmapUV1 : TEXCOORD2;
    float2 uv1 : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct UnityTessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct InternalTessInterp_appdata_full {
    float4 vertex : INTERNALTESSPOS;
    float4 tangentOS : TANGENT;
    float3 normalOS : NORMAL;
    float4 uv : TEXCOORD0;
    float4 lightmapUV : TEXCOORD1;
    float4 lightmapUV1 : TEXCOORD2;
    float4 uv1 : TEXCOORD3;
    float4 color : COLOR;
};

struct appdata_tess{
    float4 vertex : POSITION;
    float4 tangentOS : TANGENT;
    float3 normalOS : NORMAL;
    float4 uv : TEXCOORD0;
    float4 lightmapUV : TEXCOORD1;
    float4 lightmapUV1 : TEXCOORD2;
    float4 uv1 : TEXCOORD3;
};


struct VertexOutput
{
    float4 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

// #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
// #endif

    float3 normalWS                 : TEXCOORD3;
    // #ifdef _NORMALMAP
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
    // #endif
    float3 viewDirWS                : TEXCOORD5;

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

    float4 positionCS               : SV_POSITION;
    float3 viewDirTS                : TEXCOORD8;
    float4 positionNDC              : TEXCOORD9;
    float3 lightTan                 : TEXCOORD10;
    float2 maskUv                   : TEXCOORD11;
    float4 detailUv                 : TEXCOORD12;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct H3DSurfaceData
{
    float3 position;
    
    half3 albedo;
    half3 emission;
    half4 detail;
    half4 detailMSOMap;
    
    half metallic;
    half smoothness;
    half occlusion;
    //表面深度
    float depth;
    half3 specular;
    
    half alpha;
    half clipThreshold;
 
    half3 normal;
    half3 viewDir;
    half3 normalTS;
    
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
    half4   svPostion;
    half4   screenPosition;
    float4  shadowCoord;
    float4  furShadowCoord;
    half4   shadowMask;
    half    planeRefelct;

    Light ahdLight;
    
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS;
#endif
};

struct H3DBRDF
{
    half3 diffuse; 
    half3 specular;
    half3 reflectDir;
    
    half oneMinusReflectivity; 
    half perceptualRoughness; 
    half roughness; 
    half roughness2;
    
    half grazingTerm;
};

#endif