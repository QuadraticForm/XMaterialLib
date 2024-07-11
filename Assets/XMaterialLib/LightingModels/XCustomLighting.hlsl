#ifndef X_CUSTOM_LIGHTING
#define X_CUSTOM_LIGHTING

#ifndef SHADERGRAPH_PREVIEW

// This function gets additional light data and calculates realtime shadows
Light XGetAddlLight(int pixelLightIndex, float3 worldPosition) {
    // Convert the pixel light index to the light data index
    #if USE_FORWARD_PLUS
        int lightIndex = pixelLightIndex;
    #else
        int lightIndex = GetPerObjectLightIndex(pixelLightIndex);
    #endif
    // Call the URP additional light algorithm. This will not calculate shadows, since we don't pass a shadow mask value
    Light light = GetAdditionalPerObjectLight(lightIndex, worldPosition);
    // Manually set the shadow attenuation by calculating realtime shadows
    light.shadowAttenuation = AdditionalLightRealtimeShadow(lightIndex, worldPosition, light.direction);
    return light;
}

half3 XSpecular(half3 normal, half3 lightDir, half3 viewDir, half smoothness)
{
	BRDFData brdfData;
    
    brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN_SQRT);
	brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
	// brdfData.grazingTerm = saturate(smoothness + reflectivity);
	brdfData.normalizationTerm = brdfData.roughness * half(4.0) + half(2.0);
	brdfData.roughness2MinusOne = brdfData.roughness2 - half(1.0);
    
	return DirectBRDFSpecular(brdfData, normal, lightDir, viewDir);
}

#endif

//
// Ref Lit
// 参照官方的 Lit 实现的光照模型，目标是跟官方 Lit 效果完全一致
// 这个 Lighting Model 应该是所有自定义 Lighting Model 的参考起点
//

void XRefLitModel_float(
    float3 DiffuseColor, float3 F0, float Smoothness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    float3 LightDir, float3 LightColor, float LightAtten,
    out float3 Result)
{
	Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
   
    // TODO, make this PBR
	float NDotL = saturate(dot(WorldNormal, LightDir));
	float3 irradiance = LightColor * LightAtten * NDotL;
	float3 brdf = DiffuseColor;
	
	brdf += F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
	Result = brdf * irradiance;
    
#endif
}

void XRefLitModel_half(
    half3 DiffuseColor, half3 F0, half Smoothness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
#ifndef SHADERGRAPH_PREVIEW

    // TODO, make this PBR
	half NDotL = saturate(dot(WorldNormal, LightDir));
	half3 irradiance = LightColor * LightAtten * NDotL;
	half3 brdf = DiffuseColor;
	
	brdf += F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
	Result = brdf * irradiance;
    
#endif
}


void XRefLitModelAddlLights_float(
    float3 DiffuseColor, float3 F0, float Smoothness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    out float3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPosition;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
    float3 thisLightResult = 0;
    
    #if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
        light.color *= cookieColor;
    #endif
    
	XRefLitModel_float(DiffuseColor, F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

void XRefLitModelAddlLights_half(
    half3 DiffuseColor, half3 F0, half Smoothness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    out half3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPosition;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
        light.color *= cookieColor;
#endif
    
	XRefLitModel_half(DiffuseColor, F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

//
// Refraction Specular
//


void XRefractionSpecular_float(
    float3 F0, float Smoothness, float TrickOffset,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    float3 LightDir, float3 LightColor, float LightAtten,
    out float3 Result)
{
    Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    
    // xx: trick to only consider when light is "behind" surface
    F0 *= saturate(-dot(LightDir, WorldNormal) * 10);
    
    // xx: trick to refract light 
    LightDir = refract(LightDir, WorldNormal, 1 + TrickOffset);
    
    // xx: trick to use normal specular function as refraction specular
    LightDir = reflect(LightDir, WorldNormal);
   
    // TODO, make this PBR
    float NDotL = saturate(dot(WorldNormal, LightDir));
    float3 irradiance = LightColor * LightAtten * NDotL;
	
    float3 brdf = F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
    Result = brdf * irradiance;
    
#endif
}

void XRefractionSpecular_half(
    half3 F0, half Smoothness, half TrickOffset,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
    Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    
    // xx: trick to only consider when light is "behind" surface
    F0 *= saturate(-dot(LightDir, WorldNormal) * 10);
    
    // xx: trick to refract light 
    LightDir = refract(LightDir, WorldNormal, 1 + TrickOffset);
    
    // xx: trick to use normal specular function as refraction specular
    LightDir = reflect(LightDir, WorldNormal);
   
    // TODO, make this PBR
    half NDotL = saturate(dot(WorldNormal, LightDir));
    half3 irradiance = LightColor * LightAtten * NDotL;
	
    half3 brdf = F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
    Result = brdf * irradiance;
    
#endif
}


void XRefractionSpecularAddlLights_float(
    float3 F0, float Smoothness, float TrickOffset,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    out float3 Result)
{
    Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPosition;
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)

    Light light = XGetAddlLight(lightIndex, WorldPos);
    
    float3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
        light.color *= cookieColor;
#endif
    
    XRefractionSpecular_float(F0, Smoothness, TrickOffset,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
    Result += thisLightResult;
	
    LIGHT_LOOP_END

#endif
}

void XRefractionSpecularAddlLights_half(
    half3 F0, half Smoothness, half TrickOffset,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    out half3 Result)
{
    Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPosition;
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)

    Light light = XGetAddlLight(lightIndex, WorldPos);
    
    half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
        light.color *= cookieColor;
#endif
    
    XRefractionSpecular_half(F0, Smoothness, TrickOffset,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
    Result += thisLightResult;
	
    LIGHT_LOOP_END

#endif
}

#endif