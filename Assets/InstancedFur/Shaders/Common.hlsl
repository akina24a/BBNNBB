#include "Packages/com.bbn.shader/Core/H3DKeywordSwitch.hlsl"


float4 _ColorMapUV;
float4 _ColorMapParams;

TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap);
float4 _ColorMap_TexelSize;

float4 _PlayerSphere;
//XYZ: Position
//W: Radius


//Vertex color channels used as masks
#define AO_MASK input.color.r
#define BEND_MASK input.color.r

#define bakedLightmapUV lightmapUV


//Attributes shared per pass, varyings declared separately per pass
struct Attributes
{
	float4 positionOS   : POSITION;
	float4 color		: COLOR0;
	float3 normalOS     : NORMAL;
	float2 uv           : TEXCOORD0;
	float2 bakedLightmapUV   : TEXCOORD1;
	float2 dynamicLightmapUV  : TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


#include "Wind.hlsl"

//---------------------------------------------------------------//

float ObjectPosRand01() {
	return frac(UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3]);
}




// #define ANGLE_FADE_DITHER_SIZE 0.49

void AlphaClip(float alpha, float cutoff, float3 clipPos, float3 wPos)
{
	alpha -= cutoff;
	clip(alpha);
}



//---------------------------------------------------------------//
//Vertex transformation

struct VertexInputs
{
	float4 positionOS;
	float3 normalOS;
	float3 color;
	float2 uv;

};

VertexInputs GetVertexInputs(Attributes v, float flattenNormals)
{
	VertexInputs i = (VertexInputs)0;
	i.positionOS = v.positionOS;
	i.normalOS = lerp(v.normalOS, float3(0,1,0), flattenNormals);
	i.color =v.color;
	i.uv =v.uv;
	
	return i;
}

//Struct that holds both VertexPositionInputs and VertexNormalInputs
struct VertexOutput {
	//Positions
	float3 positionWS; // World space position
	float3 positionVS; // View space position
	float4 positionCS; // Homogeneous clip space position
	float4 positionNDC;// Homogeneous normalized device coordinates
	float3 viewDir;// Homogeneous normalized device coordinates
	float3 normalWS;
};

VertexOutput GetVertexOutput(uint instanceID,VertexInputs input, float rand, WindSettings s,float mask)
{
	VertexOutput data = (VertexOutput)0;

	half2 uv = _FurProperties[instanceID].uv;
	half3 normal =saturate( _FurProperties[instanceID].normal);
	float scaleMap = (SAMPLE_TEXTURE2D_LOD(_ScaleMap, sampler_ScaleMap,saturate(uv), 0).r* _ScalemapInfluence.y+0.3);
	input.positionOS.y *= scaleMap;
	float4x4 m = _FurProperties[instanceID].mat;
	float3 wPos =  mul(m, input.positionOS);

	float4 windVec = GetWindOffset(input.positionOS.xyz, wPos, rand, s)  * scaleMap; //Less wind on shorter grass


	float dis = distance(_PlayerPos, wPos);
	
	float pushDown = (1 - dis *rcp(_PushRadius)  )* _Strength;
	// float pushDown = saturate((1 - dis *rcp(_PushRadius))  )*input.color.r* _Strength;
	half3 pushDirection=  (wPos - _PlayerPos);

	half3 push = half3(pushDirection.x,wPos.y,pushDirection.z)*pushDown;
	if(_FURBENDING == 1)
	{
		float4 clipPosition = TransformWorldToHClip(wPos);
		clipPosition /= clipPosition.w;
		#if UNITY_UV_STARTS_AT_TOP
		clipPosition.y *= -1;
		#endif
		float2 screenPosition = float2(clipPosition.xy*0.5+0.5); 
		float stepped = SAMPLE_TEXTURE2D_LOD(_FurBendingRT,  sampler_FurBendingRT,screenPosition,0).r;
		float3 bendDir =push;
		bendDir.xz *= 0.5;
		bendDir.y = min(-0.5,bendDir.y);
		wPos = lerp(wPos.xyz,wPos.xyz+ bendDir*wPos.y/-bendDir.y,stepped*0.75);
		
	}
	
	float3 offsets = lerp(windVec.xyz,lerp(0,push , pow(input.color.r,1)),(saturate(1 - dis *rcp(_PushRadius))));

	//Perspective correction
	data.viewDir = normalize(GetCameraPositionWS().xyz - wPos);
	//fix size
	half3 scale = half3(m[0][0],m[1][1],m[2][2]);
	_GravityStrength *= max(max(scale.x,scale.y),scale.z)*scaleMap;
	half3 direction = lerp(0,_FurDirection* _GravityStrength , pow( input.color.r,3));

	wPos.xz += offsets.xz;
	wPos.y -= offsets.y;
	wPos += direction;
	// wPos += offsets1;
	




	data.positionWS = wPos;
	data.positionVS = TransformWorldToView(data.positionWS);
	data.positionCS = TransformWorldToHClip(data.positionWS);                       


	float4 ndc = data.positionCS * 0.5f;
	data.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
	data.positionNDC.zw = data.positionCS.zw;
	data.normalWS =  normal;

	return data;
}

VertexOutput GetShadowVertexOutput(uint instanceID,VertexInputs input, float rand, WindSettings s,float mask)

{
	VertexOutput data = (VertexOutput)0;

	half2 uv = _FurProperties[instanceID].uv;
	half3 normal =saturate( _FurProperties[instanceID].normal);
	float scaleMap = (SAMPLE_TEXTURE2D_LOD(_ScaleMap, sampler_ScaleMap,saturate(uv), 0).r* _ScalemapInfluence.y+0.3);
	input.positionOS.y *= scaleMap;
	float4x4 m = _FurProperties[instanceID].mat;
	float3 wPos =  mul(m, input.positionOS);

	float4 windVec = GetWindOffset(input.positionOS.xyz, wPos, rand, s)  * scaleMap; //Less wind on shorter grass
	float dis = distance(_PlayerPos, wPos);	
	float pushDown = (1 - dis *rcp(_PushRadius)  )* _Strength;
	half3 pushDirection=  (wPos - _PlayerPos);
	half3 push = half3(pushDirection.x,wPos.y,pushDirection.z)*pushDown;
	float3 offsets = lerp(windVec.xyz,lerp(0,push , pow(input.color.r,1)),(saturate(1 - dis *rcp(_PushRadius))));

	//Perspective correction
	data.viewDir = normalize(GetCameraPositionWS().xyz - wPos);
	//fix size
	half3 scale = half3(m[0][0],m[1][1],m[2][2]);
	_GravityStrength *= max(max(scale.x,scale.y),scale.z)*scaleMap;
	half3 direction = lerp(0,_FurDirection* _GravityStrength , pow( input.color.r,3));

	wPos.xz += offsets.xz;
	wPos.y -= offsets.y;
	wPos += direction;

	data.positionWS = wPos;
	data.positionVS = TransformWorldToView(data.positionWS);
	data.positionCS = TransformWorldToHClip(data.positionWS);                       

	float4 ndc = data.positionCS * 0.5f;
	data.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
	data.positionNDC.zw = data.positionCS.zw;
	data.normalWS =  normal;

	return data;
}