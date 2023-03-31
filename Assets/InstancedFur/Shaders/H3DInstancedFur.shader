Shader "H3D/InstancedFur"
{
	Properties
	{
		[MainTexture] _BaseMap("Albedo", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_InnerCutoff("Inner Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_ShadowCutoff("Shadow Cutoff", Range(0.0, 1.0)) = 0.5
		[MaterialEnum(Both,0,Front,1,Back,2)] _Cull("Render faces", Float) = 0

		//[Header(Shading)]
		[MainColor] _BaseColor("Color", Color) = (0.49, 0.89, 0.12, 1.0)
		_HueVariation("Hue Variation (Alpha = Intensity)", Color) = (1, 0.63, 0, 0.15)

		_OcclusionStrength("Ambient Occlusion", Range(0.0, 1.0)) = 0.25
		_Transparent("Transparent", Range(0.0, 10.0)) =2.0
		_InnerTransparent("InnerTransparent", Range(0.0, 10.0)) =2.0
		_TranslucencyDirect("Translucency (Direct)", Range(0.0, 1.0)) = 1
		_TranslucencyIndirect("Translucency (Indirect)", Range(0.0, 1.0)) = 0.0
		_TranslucencyFalloff("Translucency Falloff", Range(1.0, 8.0)) = 4.0
		_TranslucencyOffset("Translucency Offset", Range(0.0, 1.0)) = 0.0

		
		_NormalFlattening("Normal Flattening",Range(0.0, 1.0)) = 1.0
		_NormalSpherify("Normal Spherifying",Range(0.0, 1.0)) = 0.0
		_NormalSpherifyMask("Normal Spherifying (tip mask)",Range(0.0, 1.0)) = 0.0

		_FurDirection("Direction", vector) = (1,0,0,0)
		_GravityStrength("Gravity Strength", Range(0.0, 1.0)) = 0.2
		_PushRadius("_PushRadius", Range(0.0, 5.0)) = 0.2
		_Strength("Strength", Range(0.0, 10.0)) = 0.2
		
		//[Header(Wind)]
		_WindAmbientStrength("Ambient Strength", Range(0.0, 1.0)) = 0.2
		_WindSpeed("Speed", Range(0.0, 10.0)) = 3.0
		_WindDirection("Direction", vector) = (1,0,0,0)
		
		_WindVertexRand("Vertex randomization", Range(0.0, 1.0)) = 0.6
		_WindObjectRand("Object randomization", Range(0.0, 1.0)) = 0.5
		_WindRandStrength("Random per-object strength", Range(0.0, 1.0)) = 0.5
		_WindSwinging("Swinging", Range(0.0, 1.0)) = 0.15
		_WindGustStrength("Gusting strength", Range(0.0, 1.0)) = 0.2
		_WindGustFreq("Gusting frequency", Range(0.0, 10.0)) = 4
		[NoScaleOffset] _WindMap("Wind map", 2D) = "black" {}
		_ScaleMap("Scale map", 2D) = "white" {}
		_ScalemapInfluence("Scale influence", vector) = (0,1,0,0)

		[ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	
	}

	SubShader
	{
		Tags{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"RenderPipeline" = "UniversalPipeline"
		}
		
		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
		#pragma multi_compile_instancing
		ENDHLSL

		Pass
		{
			Name "ForwardLit"
			Tags{ "LightMode" = "UniversalForward" "Queue"= "Transparent" }

			Blend SrcAlpha OneMinusSrcAlpha
			Cull front
			ZWrite on
			ZTest Less

			HLSLPROGRAM


			// #pragma shader_feature_local_fragment  
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF	
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

			
			#pragma vertex LitPassVertex
			#pragma fragment InnerLightingPassFragment
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			#include "Input.hlsl"
			#include "Common.hlsl"
			#include "Lighting.hlsl"
			#include "LightingPass.hlsl"
			ENDHLSL
		}
	Pass
		{
			Name "ForwardLit"
			Tags{ "LightMode" = "SRPDefaultUnlit" "Queue"= "Transparent" }

			Blend SrcAlpha OneMinusSrcAlpha
			Cull off
			ZWrite off
			ZTest Less
            
			HLSLPROGRAM
			// #pragma shader_feature_local_fragment  
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT


			#pragma vertex LitPassVertex
			#pragma fragment LightingPassFragment
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			#include "Input.hlsl"
			#include "Common.hlsl"
			#include "Lighting.hlsl"
			#include "LightingPass.hlsl"
			ENDHLSL
		}
	Pass
	{
		Name "ShadowCaster"
		Tags{"LightMode" = "ShadowCaster"}

		ZWrite On
		ZTest LEqual
		Cull[_Cull]

		HLSLPROGRAM

		#pragma vertex ShadowPassVertex
		#pragma fragment ShadowPassFragment

		#include "Input.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"	
		#include "Common.hlsl"
		#include "ShadowPass.hlsl"
		ENDHLSL
	}
		

	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
	CustomEditor "H3d.InstancedFur.MaterialUI"
}
