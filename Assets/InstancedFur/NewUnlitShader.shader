Shader "CustomURP/Unlit"
{
	Properties
	{
		_BaseMap("Base Map",2D) = "white"{}
		_BaseColor("Base Color",Color) = (1,1,1,1)
	}
	SubShader
	{
		tags{"RenderPipeline"="UniversalPipeline" "Queue" = "Geometry"}
		
//		Pass
//		{
//			  Name "ForwardLit"
//            Tags{"LightMode" = "UniversalForward"}
//			HLSLPROGRAM
//			#pragma vertex vert
//			#pragma fragment frag
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			
//			struct Attributes
//			{
//				float3 positionOS:POSITION;
//				half2 uv:TEXCOORD0;
//			};
//			
//			struct Varyings
//			{
//				float4 positionHCS:SV_POSITION;
//				half2 uv:TEXCOORD0;
//			};			
//			
//			CBUFFER_START(UnityPerMaterial)				
//				half4 _BaseColor;
//				float4 _BaseMap_ST;
//			CBUFFER_END
//			
//			TEXTURE2D(_BaseMap);
//			SAMPLER(sampler_BaseMap);
//			
//			Varyings vert(Attributes IN)
//			{
//				Varyings o;				
//				o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
//				o.uv = TRANSFORM_TEX(IN.uv,_BaseMap);				
//				return o;
//			}
//			
//			half4 frag(Varyings IN):SV_Target
//			{
//				half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,IN.uv);
//				return half4(0,1,0,1);
//			}
//			ENDHLSL
//		}
//		Pass
//		{
//			 Name "ForwardLit"
//            Tags{"LightMode" = "SRPDefaultUnlit"}
//			HLSLPROGRAM
//			#pragma vertex vert
//			#pragma fragment frag
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			
//			struct Attributes
//			{
//				float3 positionOS:POSITION;
//				half2 uv:TEXCOORD0;
//			};
//			
//			struct Varyings
//			{
//				float4 positionHCS:SV_POSITION;
//				half2 uv:TEXCOORD0;
//			};			
//			
//			CBUFFER_START(UnityPerMaterial)				
//				half4 _BaseColor;
//				float4 _BaseMap_ST;
//			CBUFFER_END
//			
//			TEXTURE2D(_BaseMap);
//			SAMPLER(sampler_BaseMap);
//			
//			Varyings vert(Attributes IN)
//			{
//				Varyings o;				
//				o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
//				o.uv = TRANSFORM_TEX(IN.uv,_BaseMap);				
//				return o;
//			}
//			
//			half4 frag(Varyings IN):SV_Target
//			{
//				half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,IN.uv);
//				return half4(1,0,0,1) ;
//			}
//			ENDHLSL
//		}
//		Pass
//		{
////			 Name "ForwardLit"
//            Tags{"LightMode" = "UniversalForwardOnly"}
//			HLSLPROGRAM
//			#pragma vertex vert
//			#pragma fragment frag
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			
//			struct Attributes
//			{
//				float3 positionOS:POSITION;
//				half2 uv:TEXCOORD0;
//			};
//			
//			struct Varyings
//			{
//				float4 positionHCS:SV_POSITION;
//				half2 uv:TEXCOORD0;
//			};			
//			
//			CBUFFER_START(UnityPerMaterial)				
//				half4 _BaseColor;
//				float4 _BaseMap_ST;
//			CBUFFER_END
//			
//			TEXTURE2D(_BaseMap);
//			SAMPLER(sampler_BaseMap);
//			
//			Varyings vert(Attributes IN)
//			{
//				Varyings o;				
//				o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
//				o.uv = TRANSFORM_TEX(IN.uv,_BaseMap);				
//				return o;
//			}
//			
//			half4 frag(Varyings IN):SV_Target
//			{
//				half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,IN.uv);
//				return half4(0,0,1,1) ;
//			}
//			ENDHLSL
//		}
			Pass
		{
//			 Name "ForwardLit"
            Tags{"LightMode" = "www"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			struct Attributes
			{
				float3 positionOS:POSITION;
				half2 uv:TEXCOORD0;
			};
			
			struct Varyings
			{
				float4 positionHCS:SV_POSITION;
				half2 uv:TEXCOORD0;
			};			
			
			CBUFFER_START(UnityPerMaterial)				
				half4 _BaseColor;
				float4 _BaseMap_ST;
			CBUFFER_END
			
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
			
			Varyings vert(Attributes IN)
			{
				Varyings o;				
				o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				o.uv = TRANSFORM_TEX(IN.uv,_BaseMap);				
				return o;
			}
			
			half4 frag(Varyings IN):SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,IN.uv);
				return half4(1,0,1,1) ;
			}
			ENDHLSL
		}
		Pass
		{
//			 Name "ForwardLit"
            Tags{"LightMode" = "aaa"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			struct Attributes
			{
				float3 positionOS:POSITION;
				half2 uv:TEXCOORD0;
			};
			
			struct Varyings
			{
				float4 positionHCS:SV_POSITION;
				half2 uv:TEXCOORD0;
			};			
			
			CBUFFER_START(UnityPerMaterial)				
				half4 _BaseColor;
				float4 _BaseMap_ST;
			CBUFFER_END
			
			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);
			
			Varyings vert(Attributes IN)
			{
				Varyings o;				
				o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
				o.uv = TRANSFORM_TEX(IN.uv,_BaseMap);				
				return o;
			}
			
			half4 frag(Varyings IN):SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,IN.uv);
				return half4(1,0,0,1) ;
			}
			ENDHLSL
		}
	}
}
