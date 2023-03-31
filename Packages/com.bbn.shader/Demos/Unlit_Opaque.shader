Shader "H3D/Example/Unlit_Opaque"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor ("MainColor", Color) = (1,1,1,1)
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex UnlitVertex
            #pragma fragment UnlitFragment
            
            #pragma multi_compile _ DEBUG_TYPE_ALBEDO DEBUG_TYPE_ALPHA DEBUG_TYPE_DEPTH DEBUG_TYPE_NORMAL DEBUG_TYPE_METALLIC DEBUG_TYPE_ROUGHNESS DEBUG_TYPE_EMISSION DEBUG_TYPE_DIRECTLIGHT DEBUG_TYPE_INDIRECTLIGHT
            
            #define H3D_USE_NORMAL
            #define H3D_USE_NORMAL_TANGENT

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _MainColor;
            CBUFFER_END
            
            #include "../Core/ShaderFramework.hlsl"

            VertexOutput UnlitVertex (VertexInput v)
            {
                VertexOutput o = (VertexOutput) 0;
                InitVertexPosition(v, o);
                // InitVertexUV(v, o);
                InitVertexUV(v, o, _MainTex_ST);
                InitVertexNormal(v, o);
                // InitVertexNormalTangent(v, o);
                return o;
            }
            half4 UnlitFragment (VertexOutput i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                col *= _MainColor;

                H3DSurfaceData o = (H3DSurfaceData)0;
                
                o.albedo = col.rgb;
                o.alpha = col.a;
                o.position = i.positionCS;
                o.normal = i.normalWS;
                
                return GetSurfaceColor(o);
            }
            ENDHLSL
        }
    }
}
