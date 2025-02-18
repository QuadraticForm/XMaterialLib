#ifndef X_CUSTOM_LIGHTING
#define X_CUSTOM_LIGHTING

#ifndef SHADERGRAPH_PREVIEW

// This function gets additional light data and calculates realtime shadows
Light XGetAddlLight(int pixelLightIndex, float3 WorldPos) {
    // Convert the pixel light index to the light data index
    #if USE_FORWARD_PLUS
        int lightIndex = pixelLightIndex;
    #else
        int lightIndex = GetPerObjectLightIndex(pixelLightIndex);
    #endif
    // Call the URP additional light algorithm. This will not calculate shadows, since we don't pass a shadow mask value
    Light light = GetAdditionalPerObjectLight(lightIndex, WorldPos);
    // Manually set the shadow attenuation by calculating realtime shadows
    light.shadowAttenuation = AdditionalLightRealtimeShadow(lightIndex, WorldPos, light.direction);
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

float3 XSpecularEx_float(float3 normal, float3 lightDir, float3 viewDir, float smoothness, float edgePos, float edgeSharpness)
{
	BRDFData brdfData;
    
	brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN_SQRT);
	brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
	// brdfData.grazingTerm = saturate(smoothness + reflectivity);
	brdfData.normalizationTerm = brdfData.roughness * float(4.0) + float(2.0);
	brdfData.roughness2MinusOne = brdfData.roughness2 - float(1.0);
    
	// Ideal reflection direction
	float3 idealReflection = reflect(-lightDir, normal);
    
    // Dot product of view direction and ideal reflection
	float dotViewIdeal = dot(viewDir, idealReflection);
	
	// If inside the cone, make view direction closer to ideal reflection
	
	float lerpFactor = (dotViewIdeal - edgePos) / (1 - edgePos);
	
	lerpFactor = saturate(lerpFactor * edgeSharpness);
    
	viewDir = lerp(viewDir, idealReflection, lerpFactor);
    
	return DirectBRDFSpecular(brdfData, normal, lightDir, viewDir);
}

half3 XSpecularEx_half(half3 normal, half3 lightDir, half3 viewDir, half smoothness, half edgePos, half edgeSharpness)
{
	BRDFData brdfData;
    
	brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN_SQRT);
	brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
	// brdfData.grazingTerm = saturate(smoothness + reflectivity);
	brdfData.normalizationTerm = brdfData.roughness * half(4.0) + half(2.0);
	brdfData.roughness2MinusOne = brdfData.roughness2 - half(1.0);
    
	// Ideal reflection direction
	half3 idealReflection = reflect(-lightDir, normal);
    
    // Dot product of view direction and ideal reflection
	half dotViewIdeal = dot(viewDir, idealReflection);
	
	// If inside the cone, make view direction closer to ideal reflection
	
	half lerpFactor = (dotViewIdeal - edgePos) / (1 - edgePos);
	
	lerpFactor = saturate(lerpFactor * edgeSharpness);
    
	viewDir = lerp(viewDir, idealReflection, lerpFactor);
    
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
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
    float3 thisLightResult = 0;
    
    #if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
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
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
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
// Ex Lit
// 参照官方的 Lit 实现的光照模型，目标是跟官方 Lit 效果完全一致
// 这个 Lighting Model 应该是所有自定义 Lighting Model 的参考起点
//

void XExLitModel_float(
    float3 DiffuseColor, float3 F0, float Smoothness,
	float SpecularEdgePos, float SpecularEdgeSharpness,
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
	
	brdf += F0 * XSpecularEx_float(WorldNormal, LightDir, WorldView, Smoothness, SpecularEdgePos, SpecularEdgeSharpness);
    
	Result = brdf * irradiance;
    
#endif
}

void XExLitModel_half(
    half3 DiffuseColor, half3 F0, half Smoothness,
	half SpecularEdgePos, half SpecularEdgeSharpness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
#ifndef SHADERGRAPH_PREVIEW

    // TODO, make this PBR
	half NDotL = saturate(dot(WorldNormal, LightDir));
	half3 irradiance = LightColor * LightAtten * NDotL;
	half3 brdf = DiffuseColor;
	
	brdf += F0 * XSpecularEx_half(WorldNormal, LightDir, WorldView, Smoothness, SpecularEdgePos, SpecularEdgeSharpness);
    
	Result = brdf * irradiance;
    
#endif
}


void XExLitModelAddlLights_float(
    float3 DiffuseColor, float3 F0, float Smoothness,
	float SpecularEdgePos, float SpecularEdgeSharpness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    out float3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	float3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
	XExLitModel_float(DiffuseColor, F0, Smoothness,
						SpecularEdgePos, SpecularEdgeSharpness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

void XExLitModelAddlLights_half(
    half3 DiffuseColor, half3 F0, half Smoothness,
	half SpecularEdgePos, half SpecularEdgeSharpness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    out half3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
	XExLitModel_half(DiffuseColor, F0, Smoothness,
						SpecularEdgePos, SpecularEdgeSharpness,
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
    float3 F0, float Smoothness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    float3 LightDir, float3 LightColor, float LightAtten,
    out float3 Result)
{
    Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    
    // xx: trick to only consider when light is "behind" surface
    F0 *= saturate(-dot(LightDir, WorldNormal) * 10);
    
    // xx: trick to use normal specular function as refraction specular
	WorldNormal = -WorldNormal;
	WorldView = reflect(WorldView, WorldNormal);
   
    // TODO, make this PBR
    float NDotL = saturate(dot(WorldNormal, LightDir));
    float3 irradiance = LightColor * LightAtten * NDotL;
	
    float3 brdf = F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
    Result = brdf * irradiance;
    
#endif
}

void XRefractionSpecular_half(
    half3 F0, half Smoothness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
    Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    
    // xx: trick to only consider when light is "behind" surface
	F0 *= saturate(-dot(LightDir, WorldNormal) * 10);
    
    // xx: trick to use normal specular function as refraction specular
	WorldNormal = -WorldNormal;
	WorldView = reflect(WorldView, WorldNormal);
   
    // TODO, make this PBR
    half NDotL = saturate(dot(WorldNormal, LightDir));
    half3 irradiance = LightColor * LightAtten * NDotL;
	
    half3 brdf = F0 * XSpecular(WorldNormal, LightDir, WorldView, Smoothness);
    
    Result = brdf * irradiance;
    
#endif
}


void XRefractionSpecularAddlLights_float(
    float3 F0, float Smoothness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    out float3 Result)
{
    Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)

    Light light = XGetAddlLight(lightIndex, WorldPos);
    
    float3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
    XRefractionSpecular_float(F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
    Result += thisLightResult;
	
    LIGHT_LOOP_END

#endif
}

void XRefractionSpecularAddlLights_half(
    half3 F0, half Smoothness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    out half3 Result)
{
    Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
    uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

    LIGHT_LOOP_BEGIN(pixelLightCount)

    Light light = XGetAddlLight(lightIndex, WorldPos);
    
    half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
    XRefractionSpecular_half(F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
    Result += thisLightResult;
	
    LIGHT_LOOP_END

#endif
}


// 
// scattering
//

// FT Means Fake Thickness
void XScattering_float(
    float3 FTNormal, 
    float3 AbsorptionColor, float AbsorptionRate,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    float3 LightDir, float3 LightColor, float LightAtten,
    out float3 Result)
{
	Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW

    // Fake Thickness Dot
    
	float thickness = saturate(-dot(FTNormal, LightDir) * 0.5f + 0.5);
    
	float3 absorption = pow(AbsorptionColor, max(AbsorptionRate * thickness, 0.001)); // thickness 就是光行进的距离，也就是 distance
    
	Result = LightColor * LightAtten * absorption;
    
#endif
}

void XScattering_half(
    half3 FTNormal,
    half3 AbsorptionColor, half AbsorptionRate,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
	Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW

    // Fake Thickness Dot
    
	half thickness = saturate(-dot(FTNormal, LightDir) * 0.5f + 0.5);
    
	half3 absorption = pow(AbsorptionColor, max(AbsorptionRate * thickness, 0.001)); // thickness 就是光行进的距离，也就是 distance
    
	Result = LightColor * LightAtten * absorption;
    
#endif
}


void XScatteringAddlLights_float(
    float3 FTNormal,
    float3 AbsorptionColor, half AbsorptionRate,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    out float3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	float3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
	XScattering_float(FTNormal,
                        AbsorptionColor, AbsorptionRate, 
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

void XScatteringAddlLights_half(
    half3 FTNormal,
    half3 AbsorptionColor, half AbsorptionRate,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    out half3 Result)
{
	Result = 0;

#ifndef SHADERGRAPH_PREVIEW
    
	uint pixelLightCount = GetAdditionalLightsCount();

#if USE_FORWARD_PLUS
    // for Foward+ LIGHT_LOOP_BEGIN macro uses inputData.normalizedScreenSpaceUV and inputData.positionWS
    InputData inputData = (InputData)0;
    half4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPos));
    inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
    inputData.positionWS = WorldPos;
#endif

	LIGHT_LOOP_BEGIN(pixelLightCount)

	Light light = XGetAddlLight(lightIndex, WorldPos);
    
	half3 thisLightResult = 0;
    
#if defined(_LIGHT_COOKIES)
        half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPos);
        light.color *= cookieColor;
#endif
    
	XScattering_half(FTNormal,
                        AbsorptionColor, AbsorptionRate,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

#endif