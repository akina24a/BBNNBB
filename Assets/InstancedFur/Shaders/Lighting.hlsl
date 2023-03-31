
float BlendOverlay(float a, float b)
{
	return (b < 0.5) ? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
}

//RGB overlay
float3 BlendOverlay(float3 a, float3 b)
{
	float3 color;
	color.r = BlendOverlay(a.r, b.r);
	color.g = BlendOverlay(a.g, b.g);
	color.b = BlendOverlay(a.b, b.b);
	return color;
}


//Shading (RGB=hue - A=brightness)
float4 ApplyVertexColor(in float4 vertexPos, in float3 positionWS, in float3 baseColor, in float mask, in float aoAmount,  in float4 hue, in float posOffset)
{
	float4 col = float4(baseColor, 1);
	//Apply ambient occlusion
	float ambientOcclusion = lerp(col.a, col.a * mask, aoAmount);
	col.rgb = lerp( hue.rgb,col.rgb, ambientOcclusion);
	col.rgb *=  ambientOcclusion;
	col.a = mask;
	return col;
}

struct TranslucencyData
{
	float strengthDirect;
	float strengthIndirect;
	Light light;
};

float GetLightHorizonFalloff(float3 dir)
{
	//Fade the effect out as the sun approaches the horizon (75 to 90 degrees)
	half sunAngle = dot(float3(0, 1, 0), dir);
	
	return saturate(sunAngle * 6.666); /* 1.0 over 0.15 = 6.666 */
}

void ApplyTranslucency(inout SurfaceData surfaceData, InputData inputData, TranslucencyData data)
{
	float VdotL = saturate(dot(-inputData.viewDirectionWS, normalize(data.light.direction + (inputData.normalWS/* * data.offset*/))));
	// VdotL = saturate(pow(VdotL, data.exponent));

	//For proper sub-surface scattering, this should be blurred to some extent. But this should ideally be incorporated into the pipeline as a whole.
	float shadowMask = data.light.shadowAttenuation * data.light.distanceAttenuation * surfaceData.occlusion;

	//Fake some subsurface scattering by incorporating the effect into occlusion as well.
	shadowMask = saturate(shadowMask + data.strengthIndirect);

	half angleMask = GetLightHorizonFalloff(data.light.direction);

	//In URP light intensity is pre-multiplied with the color, extract via magnitude of color "vector"
	float lightStrength = length(data.light.color);
	
	float3 tColor = surfaceData.albedo + BlendOverlay(data.light.color, surfaceData.albedo);
	float3 direct = tColor * data.strengthDirect;
	float3 indirect = tColor * data.strengthIndirect;

	surfaceData.emission += lerp(indirect, direct, VdotL) * lightStrength * shadowMask *angleMask  ;
}


half3 ApplyLighting(SurfaceData surfaceData, InputData inputData, TranslucencyData translucency)
{

	ApplyTranslucency(surfaceData, inputData, translucency);
	return UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha).rgb;

}