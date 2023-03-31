#ifndef H3D_LIGHTING_FUNCTIONS_HLSL
#define H3D_LIGHTING_FUNCTIONS_HLSL 

float4 _Debug;
//////////////////////////////引入外部函数///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //*******************************************************************************************************************************************************
    //下面是其他文件中的引用，如果将本文件放入com.h3d.shader/core中并在ShaderFrameWork后面添加本文件索引后再直接引用shaderframework.hlsl
    //如果想把这个文件单独做成一个独立的hlsl库则需要引入Lighting或者URP中的一些实现，但总体计算量应该都不是很大

    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    // TransformWorldToShadowCoord()
    
    ///Packages/com.h3d.shader/Core/H3DLitMobile.hlsl
    // inline float3 BoxProjectedCubemapDirection (float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
    // {
    //     // Do we have a valid reflection probe?
    //     UNITY_BRANCH
    //     if (cubemapCenter.w > 0.0)
    //     {
    //         float3 nrdir = normalize(worldRefl);

    //         #if 1
    //             float3 rbmax = (boxMax.xyz - worldPos) / nrdir;
    //             float3 rbmin = (boxMin.xyz - worldPos) / nrdir;

    //             float3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;

    //         #else // Optimized version
    //             float3 rbmax = (boxMax.xyz - worldPos);
    //             float3 rbmin = (boxMin.xyz - worldPos);

    //             float3 select = step (float3(0,0,0), nrdir);
    //             float3 rbminmax = lerp (rbmax, rbmin, select);
    //             rbminmax /= nrdir;
    //         #endif

    //         float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

    //         worldPos -= cubemapCenter.xyz;
    //         worldRefl = worldPos + nrdir * fa;
    //     }
    //     return worldRefl;
    // }
    // half2 EnvBRDFApproxLazarov(half Roughness, half NoV)
    // {
    //     // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    //     // Adaptation to fit our G term.
    //     const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
    //     const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
    //     half4 r = Roughness * c0 + c1;
    //     half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    //     half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
    //     return AB;
    // } 
    // half GGX_Mobile(half Roughness, float NoH)
    // {
    //     // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    //     float OneMinusNoHSqr = 1.0 - NoH * NoH; 
    //     half a = Roughness * Roughness;
    //     half n = NoH * a;
    //     half p = a / (OneMinusNoHSqr + n * n);
    //     half d = p * p;
    //     // clamp to avoid overlfow in a bright env
    //     return min(d, 2048.0);
    // } 
    // half CalcSpecular(half Roughness, half NoH)
    // {
    //     return (Roughness*0.25 + 0.25) * GGX_Mobile(Roughness, NoH);
    // }
    
    ///trunk-URP/std_res/Shader/Standard/NewStandard/StandardCore/StandardCore.hlsl
    // real3 NormalizeNormalPerPixel(real3 normalWS)
    // { 
    //     #if defined(SHADER_QUALITY_HIGH) || defined(_NORMALMAP)
    //         return normalize(normalWS);
    //     #else
    //         return normalWS;
    //     #endif
    // }

    ///trunk-URP/std_res/Shader/Standard/NewStandard/StandardCore/Lighting.hlsl
    // half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
    // { 
    // #if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    //     half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    //     half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

    // #if !defined(UNITY_USE_NATIVE_HDR)
    //     half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    // #else
    //     half3 irradiance = encodedIrradiance.rbg;
    // #endif

    //     return irradiance * occlusion;
    // #endif // GLOSSY_REFLECTIONS

    //     return _GlossyEnvironmentColor.rgb * occlusion;
    // }
 

    //。。。未引入完

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////获取光照信息////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    Light GetH3DMainLight(float3 worldPos)
    {
        Light mainLight;

        #if SPE && defined(DIRLIGHTMAP_COMBINED) 
            Light ahdLight = (Light)0;
            ahdLight.shadowAttenuation = 1.0;
            ahdLight.distanceAttenuation = 1;

            mainLight = ahdLight;//surf.ahdLight;distanceAttenuation、shadowAttenuation并不影响GI 
        #else 
            float4 shadowCoord = 0;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                //H3DStandardPass.hlsl——11行中在顶点着色器中计算最后调用也是和下面一样，奇怪为啥这样写
                shadowCoord = TransformWorldToShadowCoord(worldPos);//i.shadowCoord;
            #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                shadowCoord = TransformWorldToShadowCoord(worldPos);
            #else
                shadowCoord = float4(0, 0, 0, 0);
            #endif 
            mainLight = GetMainLight(shadowCoord);  
            // MixRealtimeAndBakedGI(mainLight, surf.normal, surf.bakedGI, 0);//bakedGI是在获取主光前调用，这里调用改变了但不影响其他效果
        #endif

        return mainLight;
    } 
    float3 GetBrdfSpecular(float3 worldNormal, float3 viewDir,float perceptualRoughness,float3 albedo,float metallic)
    {   
        // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
        // Adaptation to fit our G term.计算量还行不是很大
        half2 AB = EnvBRDFApproxLazarov(saturate(perceptualRoughness), saturate(dot(worldNormal, viewDir)));
        float3 specular = lerp(kDieletricSpec.rgb, albedo,  metallic);
        
        specular =  specular * AB.x + AB.y;
        
        return specular;
    } 
    float3 GetBrdfDiffuse(float3 albedo,float metallic)
    {
        //// standard dielectric reflectivity coef at incident angle (= 4%) 计算量也不大
        half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
        // brdf.diffuse = lerp(surf.albedo, surf.detail.rgb, surf.detail.a) * brdf.oneMinusReflectivity;
        float3 diffuse =oneMinusReflectivity*albedo;
        return diffuse;
    }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////计算光照模型/////////////////////////////////////////////////////////////////////////////////////////
    // Taken from https://gist.github.com/romainguy/a2e9208f14cae37c579448be99f78f25
    // Modified by Epic Games, Inc. To account for premultiplied light color and code style rules.
    inline half L_GGX_Mobile(half Roughness,float NoH)
    { 
        float OneMinusNoHSqr = 1.0 - NoH* NoH;
        half a = Roughness * Roughness;
        half n = NoH *a;
        half p = a / (OneMinusNoHSqr + n *n);
        half d = p * p;
        // clamp to avoid overlfow in a bright env
        return min(d,2048.0)*(Roughness*0.25 + 0.25);
    }
    inline half L_BlinnPhong(half Roughness,float NoH)
    { 
       return pow(max(0, NoH), max(0.001,Roughness)*1000)*10;
    }


    inline half3 LightingMobile(Light light,half3 worldNormal, half3 viewDir,half perceptualRoughness,half3 albedo,half metallic)
    {
        half3 lightDirectionWS = light.direction;
        
        if (!IsMatchingLightLayer(light.layerMask, GetMeshRenderingLightLayer()))
        {
            light.color =0; 
        }
        half3 lightColor = light.color;
        half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
        
        half NoL = saturate(dot(worldNormal, lightDirectionWS));
        half NoH = saturate(dot(worldNormal, SafeNormalize(lightDirectionWS +  viewDir)));//避免除0
        half3 radiance = lightColor * lightAttenuation * NoL;
        
        half3 specular =GetBrdfSpecular( worldNormal, viewDir,perceptualRoughness,  albedo,  metallic); 
        // #ifdef _GGXMOBILE
              specular = L_GGX_Mobile( perceptualRoughness, NoH)  *  specular;  
        // #else
        //       specular = L_BlinnPhong( perceptualRoughness, NoH)  *  specular; 
        // #endif
        half3 diffuse =GetBrdfDiffuse(albedo,metallic); 
        
        half3 result = radiance * (specular + diffuse);   

        return result;
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 	float3 RotateVector(float3 dir, float3 axis, float angle)
    {
        float sinAng = sin(angle);
        float cosAng = cos(angle);
        float cosAng1 = 1.0 - cosAng;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        float3x3 rotMat = float3x3(x * x + (1.0 - x * x) * cosAng,
            x * y * cosAng1 + z * sinAng,
            x * z * cosAng1 - y * sinAng,

            x * y * cosAng1 - z * sinAng,
            y * y + (1.0 - y * y) * cosAng,
            y * z * cosAng1 + x * sinAng,

            x * z * cosAng1 + y * sinAng,
            y * z * cosAng1 - x * sinAng,
            z * z + (1.0 - z * z) * cosAng);
        return mul(rotMat, dir);
    } 
/////////////////////////////调用光照函数/////////////////////////////////////////////////////////////////////////////////////////
    ///
    //Lighting Map   
    //v2f 结构体中声明 DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
    //需要在顶点中计算下列数据 OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV); OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    //片元程序中 使用 LIGHTMAP_ON 判断使用lightingmap还是顶点球谐
    /// 
    inline half3 IndirectBakedGI(float2 lightmapUV ,float3 vertexSH,float3 worldNormal,float3 albedo,float occlusion,float metallic)//,float3 worldPos)
    { 
        //间接光GI是在获取主光ahd之前计算的，，，，，，所以不用考虑SPE Dirlightmap_combined
        float3 bakedGI=0; 
        Light ahdLight = (Light)0;
        ahdLight.shadowAttenuation = 1.0;
        ahdLight.distanceAttenuation = 1;
        
        #ifdef LIGHTMAP_ON
            //现在关闭AHD功能
            // #if SPE
            //     bakedGI = SampleLightmapEx(lightmapUV, worldNormal,  ahdLight);
            // #else
            bakedGI = SampleLightmap(lightmapUV, worldNormal);
            // #endif
        #else
            bakedGI = SampleSHPixel(vertexSH, worldNormal);
        #endif

        // Light mainLight=GetH3DMainLight(worldPos);
        // float3 normalWS = NormalizeNormalPerPixel(worldNormal);

        // #if SPE && defined(DIRLIGHTMAP_COMBINED)
        // //   mainLight = surf.ahdLight;H3DLitMobile.hlsl 122行获取主光
        // #else
        // MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, 0);
        // #endif
        
        float3 diffuse =GetBrdfDiffuse(albedo,metallic);
        
        half3 indirectDiffuse = bakedGI * occlusion; 
        half3 indirectColor = indirectDiffuse*diffuse;//* brdf.diffuse ; 
        return indirectColor;
    } 
    ///
    //反射探针Reflection Probe
    /// 
    inline half3 IndirectSpecular(float3 viewDir,float3 worldNormal, float3 worldPos,float perceptualRoughness,float3 albedo,float metallic,float occlusion)
    {   
        float3 reflectDir = reflect(-viewDir, worldNormal);
        // reflectDir = saturate(reflectDir); 
        #ifdef UNITY_SPECCUBE_BOX_PROJECTION
            // float blendDistance = unity_SpecCube1_ProbePosition.w;
            // unity_SpecCube0_BoxMin.xyz -= unity_SpecCube1_ProbePosition.xyz;
            // unity_SpecCube0_BoxMax.xyz -= unity_SpecCube1_ProbePosition.xyz;
            // unity_SpecCube0_BoxMin.xz /= float2(1,3);
            // unity_SpecCube0_BoxMax.xz /= float2(1,3);
            // return _Debug.rrr; 
            reflectDir = BoxProjectedCubemapDirection (reflectDir, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
        
        // float4 minbox = unity_SpecCube0_BoxMin;

        // return unity_SpecCube0_BoxMin.rgb;
        // reflectDirect = RotateVector(reflectDir,_Debug.xyz,_Debug.w);

        #endif
             
        float3 specular =GetBrdfSpecular(worldNormal, viewDir,perceptualRoughness,  albedo,  metallic);  
        
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectDir, perceptualRoughness, occlusion);
        half3 indirectColor = 0;//indirectDiffuse * brdf.diffuse;
        indirectColor += indirectSpecular  * specular;
        return indirectColor;
    }
    ///
    //主光照
    ///
    inline half3 DirectMainLighting(float3 worldpos,float3 worldNormal, float3 viewDir,float perceptualRoughness,float3 albedo,float metallic)
    { 
        Light light =GetH3DMainLight(worldpos); 
        half3 result = LightingMobile(light,worldNormal,viewDir,perceptualRoughness,albedo,metallic);
        return result;
    }

    ///
    //额外光照
    // Universal Pipeline keywords
    // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHTS_FORWARD_PLUS
    ///
    inline half3 DirectAdditionLighting(float3 positionWS,float4 positionCS,float3 worldNormal, float3 viewDir,float perceptualRoughness,float3 albedo,float metallic)
    {
        half3 directColor=0;
        InputData input = (InputData)0;
        input.positionWS =positionWS;
        input.positionCS = positionCS;
        ADDITIONAL_LIGHTS_LOOP_BEGIN(input)
            directColor +=LightingMobile(light,worldNormal,viewDir,perceptualRoughness,albedo,metallic);
        ADDITIONAL_LIGHTS_LOOP_END
        
        return directColor;
    }


    inline half3 SimpleAdditionLighting(float3 positionWS,float3 worldNormal, float3 albedo,float4 positionCS)
    { 
        //Add Light
        half3 addColor = real3(0, 0, 0);
        #ifdef _ADDITIONAL_LIGHTS
            int addLightCount = GetAdditionalLightsCount();
            for (int index = 0; index < addLightCount; index++)
                {
                    Light addLight = GetAdditionalLight(index, positionWS);
                    float3 addLightDir = normalize(addLight.direction); 
                    addColor += (dot(worldNormal, addLightDir) * 0.5 + 0.5)*real3(addLight.color)*albedo*addLight.shadowAttenuation*addLight.distanceAttenuation;
                }
        #endif
        
        #ifdef _ADDITIONAL_LIGHTS_FORWARD_PLUS
        uint GridIndex = ComputeLightGridCellIndex(positionCS);
        
        uint lightCount = _NumCulledLightsGrid[GridIndex];
        if(lightCount > 0)
        {
            uint maxLightsPerCluster = _AdditionalLightsCount.z;
            uint maxValueCount = maxLightsPerCluster >> 2;
            UNITY_LOOP
            for (uint i = 0u; i < lightCount; ++i)
            {
                uint step = i >> 2; // i / 4 = step
                uint value = _CulledLightDataGrid[GridIndex * maxValueCount + step];
                uint lightIndex = (value >> (24 - (i - step * 4) * 8)) & 0xFF;
                Light addLight = GetAdditionalPerObjectLight(lightIndex,positionWS);
                float3 addLightDir = normalize(addLight.direction); 
                addColor += (dot(worldNormal, addLightDir) * 0.5 + 0.5)*real3(addLight.color)*albedo*addLight.shadowAttenuation*addLight.distanceAttenuation;
            }
        }
        #endif
    
        return addColor;
    }


 


    inline half3 DirectVertexLightingVert(float3 InPositionWS,float3 InNormalWS)
    { 
        return VertexLighting(InPositionWS, InNormalWS); 
    }
    inline half3 DirectVertexLightingFrag(half3 vertlighting,float3 albedo,float metallic)
    {  
        half3 directColor=0;
        #ifdef _ADDITIONAL_LIGHTS_VERTEX
            float3 diffuse =GetBrdfDiffuse(albedo,metallic);
            directColor += vertlighting * diffuse;
        #endif
        return directColor;
    } 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#endif


//////////////////////////////测试用例////////////////////////////////////////////////////////////////////////////////////////////////////
    // Pass
    // {
    //     HLSLPROGRAM 
    //     // keywords 
    //     #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHTS_FORWARD_PLUS
    //     #pragma multi_compile _ LIGHTMAP_ON 
    //     #include "Packages/com.h3d.shader/Core/ShaderFramework.hlsl"
    //     #include "../../URPInclude/H3DURP.hlsl"
    //     #include "./H3DDefines.hlsl" 
    //     #pragma vertex vert
    //     #pragma fragment frag  
    //     struct appdata
    //     {
    //         float4 vertex : POSITION;
    //         float2 uv : TEXCOORD0;
    //         half3 normal : NORMAL; 
    //         float2 lightmapUV   : TEXCOORD1;
    //     };

    //     struct v2f
    //     {
    //         float4 pos : SV_POSITION; 
    //         float4 uv : TEXCOORD0; 
    //         DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
    //         half3 viewDir : TEXCOORD2;
    //         half3 worldPos : TEXCOORD3; 
    //         half3 worldNormal :NORMAL;  
    //         half3 normalOS:TEXCOORD4;
    //     };

    //     half4 _BasemainColor;
    //     int MODE;
    //     half _GlossScale,_MetallicScale;
            
    //     v2f vert (appdata v)
    //     {
    //         v2f o;
    //         o.pos = UnityObjectToClipPos(v.vertex);
    //         OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
    //         half3 worldNormal = UnityObjectToWorldNormal(v.normal);  
    //         OUTPUT_SH(worldNormal , o.vertexSH);


    //         o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
    //         o.viewDir = normalize(GetCameraPositionWS() - o.worldPos);
    //         o.normalOS = v.normal;

    //         return o;
    //     }


    //     half4 frag (v2f i) : SV_TARGET
    //     { 
    //         half3 worldNormal = UnityObjectToWorldNormal(i.normalOS); 
    //         half3 viewDir =i.viewDir;// normalize(UnityWorldSpaceViewDir(i.worldPos));   

    //         #ifdef LIGHTMAP_ON 
    //         half3 sIndirectBakedGI        = IndirectBakedGI(i.lightmapUV,0,worldNormal,_BasemainColor.rgb,1,_MetallicScale);
    //         #else 
    //         half3 sIndirectBakedGI        = IndirectBakedGI(0,  i.vertexSH,worldNormal,_BasemainColor.rgb,1,_MetallicScale);
    //         #endif 
    //         half3 sIndirectSpecular       = IndirectSpecular( viewDir,worldNormal,i.worldPos,1-_GlossScale,_BasemainColor.rgb,_MetallicScale,1);
    //         half3 sDirectMainLighting     = DirectMainLighting(i.worldPos, worldNormal, viewDir,1-_GlossScale,_BasemainColor.rgb,_MetallicScale);
    //         half3 sDirectAdditionLighting = DirectAdditionLighting(i.worldPos, worldNormal, viewDir,1-_GlossScale,_BasemainColor.rgb,_MetallicScale);
                
    //         if(MODE==0)
    //         return half4(sIndirectBakedGI,1);
    //         else if(MODE==1)
    //         return half4(sIndirectSpecular,1);
    //         else if(MODE==2)
    //         return half4(sDirectMainLighting,1);
    //         else if(MODE==3)
    //         return half4(sDirectAdditionLighting,1);
    //         else
    //         return half4(sIndirectBakedGI+sIndirectSpecular +sDirectMainLighting+sDirectAdditionLighting ,1);
    //     }
    //     ENDHLSL 
    // } 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
