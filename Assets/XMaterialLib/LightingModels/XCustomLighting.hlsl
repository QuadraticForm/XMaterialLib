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
    float3 BaseColor, float3 DiffuseColor, float3 F0, float Smoothness,
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
    half3 BaseColor, half3 DiffuseColor, half3 F0, half Smoothness,
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
    float3 BaseColor, float3 DiffuseColor, float3 F0, float Smoothness,
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
    
	XRefLitModel_float(BaseColor, DiffuseColor, F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

void XRefLitModelAddlLights_half(
    half3 BaseColor, half3 DiffuseColor, half3 F0, half Smoothness,
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
    
	XRefLitModel_half(BaseColor, DiffuseColor, F0, Smoothness,
                        WorldPos, WorldNormal, WorldView,
                        light.direction, light.color, light.shadowAttenuation * light.distanceAttenuation,
                        thisLightResult);
    
	Result += thisLightResult;
	
	LIGHT_LOOP_END

#endif
}

//
// Ext Lit
// 按照一些特殊材质的需求，在 Lit 材质的基础上进行一些扩展
//


//
// Crystal，水晶材质
//




#endif