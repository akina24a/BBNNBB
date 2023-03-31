#ifndef H3D_DEBUG_HLSL
#define H3D_DEBUG_HLSL

#ifdef DEBUG_TYPE_ALBEDO
    #define DEBUG_PROCESS_ALBEDO(surf) return half4(surf.albedo,1);
#else
    #define DEBUG_PROCESS_ALBEDO(surf) 
#endif

#ifdef DEBUG_TYPE_ALPHA
    #define DEBUG_PROCESS_ALPHA(surf) return surf.alpha;
#else
    #define DEBUG_PROCESS_ALPHA(surf) 
#endif

#ifdef DEBUG_TYPE_NORMAL
    #define DEBUG_PROCESS_NORMAL(surf) return half4(pow((surf.normal + 1)*0.5,2.2), 1);
#else
    #define DEBUG_PROCESS_NORMAL(surf) 
#endif

#ifdef DEBUG_TYPE_METALLIC
    #define DEBUG_PROCESS_METALLIC(surf) return surf.metallic;
#else
    #define DEBUG_PROCESS_METALLIC(surf) 
#endif

#ifdef DEBUG_TYPE_ROUGHNESS
    #define DEBUG_PROCESS_ROUGHNESS(surf) return surf.smoothness;
#else
    #define DEBUG_PROCESS_ROUGHNESS(surf) 
#endif

#ifdef DEBUG_TYPE_EMISSION
    #define DEBUG_PROCESS_EMISSION(surf) return half4(surf.emission,1);
#else
    #define DEBUG_PROCESS_EMISSION(surf) 
#endif


#ifdef DEBUG_TYPE_DIRECTLIGHT
    #define DEBUG_PROCESS_DIRECTLIGHT(color) return half4(color,1);
#else
    #define DEBUG_PROCESS_DIRECTLIGHT(color) 
#endif

#ifdef DEBUG_TYPE_INDIRECTLIGHT
    #define DEBUG_PROCESS_INDIRECTLIGHT(color) return half4(color,1);
#else
    #define DEBUG_PROCESS_INDIRECTLIGHT(color)
#endif


#define DEBUG_PROCESS_SURFACE(surf) DEBUG_PROCESS_ALBEDO(surf) \
    DEBUG_PROCESS_ALPHA(surf) DEBUG_PROCESS_NORMAL(surf) \
    DEBUG_PROCESS_METALLIC(surf) DEBUG_PROCESS_ROUGHNESS(surf) DEBUG_PROCESS_EMISSION(surf)

#endif