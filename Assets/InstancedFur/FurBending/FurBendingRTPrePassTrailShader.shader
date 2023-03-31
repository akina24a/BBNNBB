Shader "H3D/InstancedFurBendingRTPrePassPS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
    
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            Cull Off
            ZTest Always
//            Blend one zero

            Tags 
            {
                "LightMode" = "FurBending"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half4 color     : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                float3 wPos =  mul(unity_ObjectToWorld,v.vertex).xyz; 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);    
                o.color =(1-v.color);
            
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col =  tex2D(_MainTex,i.uv)*i.color;
                return col;
            }
            ENDCG
        }
    }
}
