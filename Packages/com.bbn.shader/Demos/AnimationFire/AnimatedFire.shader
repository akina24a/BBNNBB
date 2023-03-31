Shader "Unlit/H3D/AnimatedFire"
{
    Properties
    {
		_Albedo("Albedo", 2D) = "white" {}
		_Normals("Normals", 2D) = "bump" {}
		_Mask("Mask", 2D) = "white" {}
		_Specular("Specular", 2D) = "white" {}
		_TileableFire("TileableFire", 2D) = "white" {}
		_FireIntensity("FireIntensity", Range( 0 , 2)) = 0
		_Smoothness("Smoothness", Float) = 1
		_TileSpeed("TileSpeed", Vector) = (0,0,0,0)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #include "Packages/com.h3d.shader/Core/ShaderFramework.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag
            
            #pragma multi_compile _ DEBUG_TYPE_ALBEDO DEBUG_TYPE_ALPHA DEBUG_TYPE_DEPTH DEBUG_TYPE_NORMAL DEBUG_TYPE_METALLIC DEBUG_TYPE_ROUGHNESS DEBUG_TYPE_EMISSION DEBUG_TYPE_DIRECTLIGHT DEBUG_TYPE_INDIRECTLIGHT
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Albedo_ST;
                half _FireIntensity;
                half _Smoothness;
                half4 _TileSpeed;
            CBUFFER_END
            
            DECLARE_SAMPLE_2D(_Albedo)
            DECLARE_SAMPLE_2D(_Normals)
            DECLARE_SAMPLE_2D(_Mask)
            DECLARE_SAMPLE_2D(_Specular)
            DECLARE_SAMPLE_2D(_TileableFire)
            DECLARE_SAMPLE_2D(_OcclusionMap)

            VertexOutput Vert (const VertexInput v)
            {
                VertexOutput o = (VertexOutput) 0;
                InitVertexPosition(v, o);
                InitVertexUV(v, o, _Albedo_ST);
                InitVertexNormalTangent(v, o);
                half3 posWS = TransformObjectToWorld(v.vertex);
                o.viewDirWS = GetCameraPositionWS() - posWS;
                return o;
            }


            half4 Frag (VertexOutput i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                H3DSurfaceData surf = (H3DSurfaceData) 0;
                
                surf.albedo = SAMPLE_TEXT(_Albedo, i.uv).rgb;
                surf.alpha = 1;
                
                float2 panner16 = _Time.x * _TileSpeed + i.uv;
			    surf.emission = (SAMPLE_TEXT( _Mask, i.uv ) * SAMPLE_TEXT( _TileableFire, panner16 )  * ( _FireIntensity * ( _SinTime.w + 1.5 ) ) ).rgb;
			    surf.specular = SAMPLE_TEXT( _Specular, i.uv ).rgb;
			    surf.smoothness = _Smoothness;

                surf.normalTS = SampleNormal(_Normals, sampler_Normals, i.uv);
                InitNormalMap(i, surf);
                return SurfaceStandardSpecular(surf);
            }
            ENDHLSL
        }
    }
}
