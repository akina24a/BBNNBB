Shader "H3D/Example/Lit_Standard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("MainColor", Color) = (1,1,1,1)
        
        _BumpScale("Scale", Float) = 1.0
        [NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        [NoScaleOffset]_MetallicMap("MetallicMap", 2D) = "white" {}
        
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        [NoScaleOffset]_SmoothnessMap("Smoothness Map", 2D) = "white" {}
        
        _EmissionColor("Emission", Color) = (0,0,0)
        [NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}
        
        _Occlusion("Occlusion", Range(0.0, 1.0)) = 1.0
        [NoScaleOffset]_OcclusionMap("Occlusion Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            
            #pragma multi_compile _ DEBUG_TYPE_ALBEDO DEBUG_TYPE_ALPHA DEBUG_TYPE_DEPTH DEBUG_TYPE_NORMAL DEBUG_TYPE_METALLIC DEBUG_TYPE_ROUGHNESS DEBUG_TYPE_EMISSION DEBUG_TYPE_DIRECTLIGHT DEBUG_TYPE_INDIRECTLIGHT 
            
            #include "../Core/ShaderFramework.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _MainColor;
                half4 _EmissionColor;
                half _Smoothness;
                half _Metallic;
                half _BumpScale;
                half _Occlusion;
            CBUFFER_END
            
            DECLARE_SAMPLE_2D(_MainTex)
            DECLARE_SAMPLE_2D(_BumpMap)
            DECLARE_SAMPLE_2D(_MetallicMap)
            DECLARE_SAMPLE_2D(_SmoothnessMap)
            DECLARE_SAMPLE_2D(_EmissionMap)
            DECLARE_SAMPLE_2D(_OcclusionMap)

            VertexOutput Vert (const VertexInput v)
            {
                VertexOutput o = (VertexOutput) 0;
                InitVertexPosition(v, o);
                InitVertexUV(v, o, _MainTex_ST);
                // InitVertexNormal(v, o);
                InitVertexNormalTangent(v, o);

                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH);
                
                half3 posWS = TransformObjectToWorld(v.vertex);
                half3 vertexLight = VertexLighting(posWS, o.normalWS);
                half fogFactor = ComputeFogFactor(o.positionCS);
                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                o.viewDirWS = GetCameraPositionWS() - posWS;
                
                return o;
            }
            
            half4 Frag (VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                
                H3DSurfaceData surf = (H3DSurfaceData) 0;
                
                half4 color = SAMPLE_TEXT(_MainTex, i.uv) * _MainColor;
                surf.albedo = color.rgb;
                surf.alpha = color.a;
                surf.metallic = SAMPLE_TEXT(_MetallicMap, i.uv).r * _Metallic;
                surf.smoothness = SAMPLE_TEXT(_SmoothnessMap, i.uv).r * _Smoothness;
                surf.emission = SAMPLE_TEXT(_EmissionMap, i.uv).rgb * _EmissionColor;
                surf.occlusion = SAMPLE_TEXT(_OcclusionMap, i.uv).r * _Occlusion;
                surf.normalTS = SampleNormal(_BumpMap, sampler_BumpMap, i.uv, _BumpScale);
                InitNormalMap(i, surf);
                InitInputData(i, surf);
                // InputData input;
                // InitializeInputData(i, normalTS, input);
                return SurfaceStandard(surf);
            }
            ENDHLSL
        }
    }
}