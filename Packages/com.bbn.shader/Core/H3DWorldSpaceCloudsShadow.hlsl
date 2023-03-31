#ifndef WORLDSPACE_CLOUDS_SHADOW_INCLUDED
#define WORLDSPACE_CLOUDS_SHADOW_INCLUDED
// Cloud Shadow Map
sampler2D _CloudShadowTex;
half4 _CloudShadowTilling; //xy: Tilling zw: Flow Speed
half4 _CloudShadowStrength; //x: Strength //y: Coverage

half GetCloudShadowAtten(float3 worldPos)
{
    half2 sampleCoord = worldPos.xz;
    half2 tilling = _CloudShadowTilling.xy;
    half2 flowOffset= _CloudShadowTilling.zw * _Time.x;
    half strength = _CloudShadowStrength.x;
    half coverage = _CloudShadowStrength.y;

    half shadowTex = tex2Dlod(_CloudShadowTex, float4(sampleCoord * tilling * 0.001h + flowOffset, 0, 1)).r;

    half shadowAtten = smoothstep(0, saturate(1-coverage), shadowTex) * strength * 1.5;
    half shadowFade = GetMainLightShadowFade(worldPos);
    return lerp(1-saturate(shadowAtten), 1, shadowFade);
}
#endif