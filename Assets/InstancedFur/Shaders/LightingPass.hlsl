// #include "Input.hlsl"
#define bakedLightmapUV lightmapUV

struct Varyings
{
	float4 uv                       : TEXCOORD0;
	DECLARE_LIGHTMAP_OR_SH(bakedLightmapUV, vertexSH, 1); //Called staticLightmapUV in URP12+

	float3 positionWS               : TEXCOORD2;
	half3  normalWS                 : TEXCOORD3;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	float4 shadowCoord              : TEXCOORD4; // compute shadow coord per-vertex for the main light
#endif

		
	float4 positionCS               : SV_POSITION;
	float4 color					: COLOR0;
	
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};


Varyings LitPassVertex(Attributes input, uint instanceID: SV_InstanceID)
{
	Varyings output = (Varyings)0;
	
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	float posOffset = ObjectPosRand01();

	WindSettings wind = PopulateWindSettings(_WindAmbientStrength, _WindSpeed, _WindDirection, _WindSwinging, BEND_MASK, _WindObjectRand, _WindVertexRand, _WindRandStrength, _WindGustStrength, _WindGustFreq);
	VertexInputs vertexInputs = GetVertexInputs(input, _NormalFlattening);
	vertexInputs.normalOS = lerp(vertexInputs.normalOS, normalize(vertexInputs.positionOS.xyz), _NormalSpherify * lerp(1, BEND_MASK, _NormalSpherifyMask));
	VertexOutput vertexData = GetVertexOutput(instanceID,vertexInputs, posOffset, wind,AO_MASK);
	output.positionWS = vertexData.positionWS;
	output.normalWS = vertexData.normalWS;
	
	//Vertex color
	output.color = ApplyVertexColor(input.positionOS, vertexData.positionWS.xyz, _BaseColor.rgb, AO_MASK, _OcclusionStrength, _HueVariation, posOffset);

	OUTPUT_LIGHTMAP_UV(input.bakedLightmapUV, unity_LightmapST, output.bakedLightmapUV);
	OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
	output.uv.zw = 0;


#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
	//GetShadowCoord function must be used, in order for normalized screen coords to be calculated (Screen-space shadows)
	output.shadowCoord = GetShadowCoord((VertexPositionInputs)vertexData);
#endif

	output.uv.xy = TRANSFORM_TEX(input.uv, _BaseMap);
	output.positionCS = vertexData.positionCS;

	return output;
}

void ModifySurfaceData(Varyings input, out SurfaceData surfaceData)
{
	float4 albedoAlpha = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
	//Apply hue var and ambient occlusion from vertex stage
	albedoAlpha.rgb = input.color.rgb;
	surfaceData.albedo = saturate(albedoAlpha.rgb );
	//Not using specular setup, free to use this to pass data
	surfaceData.specular = float3(0, 0, 0);
	surfaceData.metallic = 0.0;
	surfaceData.smoothness = 0.0;
	surfaceData.normalTS = float3(0.5, 0.5, 1.0);

	surfaceData.emission = 0.0;
	surfaceData.occlusion = 1.0;
	surfaceData.alpha = albedoAlpha.a;
	//
	#if VERSION_GREATER_EQUAL(10,0)
	surfaceData.clearCoatMask = 0.0h;
	surfaceData.clearCoatSmoothness = 0.0h;
	#endif

}

//This function is a testament to how convoluted cross-compatibility between difference URP versions has become
void PopulateLightingInputData(Varyings input, half3 normalTS, out InputData inputData)
{
	
	inputData = (InputData)0;
	inputData.positionWS = input.positionWS.xyz;

	//Using GetWorldSpaceViewDir returns a constant vector for orthographic camera's, which isn't useful
	half3 viewDirWS = normalize(_WorldSpaceCameraPos - (input.positionWS.xyz));
	
	// half3x3 tangentToWorld = 0;
	inputData.normalWS = input.normalWS;
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	
	inputData.viewDirectionWS = viewDirWS;

	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) //No shadow cascades
	inputData.shadowCoord = input.shadowCoord;
	#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
	inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	#else
	inputData.shadowCoord = float4(0, 0, 0, 0);
	#endif
	inputData.bakedGI = SAMPLE_GI(input.bakedLightmapUV, input.vertexSH, inputData.normalWS);
	
#if VERSION_GREATER_EQUAL(10,0)
	inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
	inputData.shadowMask = SAMPLE_SHADOWMASK(input.bakedLightmapUV);
#endif


}
half4 InnerLightingPassFragment(Varyings input) : SV_Target

{
	
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	SurfaceData surfaceData;
	//Can't use standard function, since including LitInput.hlsl breaks the SRP batcher
	ModifySurfaceData(input, surfaceData);

	AlphaClip(surfaceData.alpha, _InnerCutoff, input.positionCS.xyz, input.positionWS.xyz);


	InputData inputData;
	//Standard URP function barely changes, but adds things like clear coat and detail normals
	PopulateLightingInputData(input, surfaceData.normalTS, inputData);
	Light mainLight = GetMainLight(inputData.shadowCoord);
	TranslucencyData tData = (TranslucencyData)0;
	tData.strengthDirect = _TranslucencyDirect;
	tData.strengthIndirect = _TranslucencyIndirect;

	tData.light = mainLight;
	
	float3 finalColor = ApplyLighting(surfaceData, inputData, tData);

	// return half4(finalColor, surfaceData.alpha);
	return half4(finalColor, (pow(surfaceData.alpha*(1-AO_MASK),_InnerTransparent)));
	return half4(finalColor, lerp(pow(surfaceData.alpha,_InnerTransparent),1,AO_MASK));

}

half4 LightingPassFragment(Varyings input) : SV_Target

{
	
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	SurfaceData surfaceData;
	//Can't use standard function, since including LitInput.hlsl breaks the SRP batcher
	ModifySurfaceData(input, surfaceData);

	AlphaClip(surfaceData.alpha, _Cutoff, input.positionCS.xyz, input.positionWS.xyz);


	InputData inputData; 
	//Standard URP function barely changes, but adds things like clear coat and detail normals
	PopulateLightingInputData(input, surfaceData.normalTS, inputData);
	Light mainLight = GetMainLight(inputData.shadowCoord);
	TranslucencyData tData = (TranslucencyData)0;
	tData.strengthDirect = _TranslucencyDirect;
	tData.strengthIndirect = _TranslucencyIndirect;

	tData.light = mainLight;
	
	float3 finalColor = ApplyLighting(surfaceData, inputData, tData);

	// return half4(finalColor, surfaceData.alpha);
	return half4(finalColor, (pow(surfaceData.alpha*(1-AO_MASK),_Transparent)));
	return half4(finalColor, lerp(pow(surfaceData.alpha,_Transparent),1,AO_MASK));

}