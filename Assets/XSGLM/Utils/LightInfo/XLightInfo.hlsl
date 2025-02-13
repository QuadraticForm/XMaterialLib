#ifndef XSGLM
#define XSGLM

// This function gets additional light data and calculates realtime shadows
void XGetAddlLight_float(int pixelLightIndex, float3 WorldPos, 
	out bool valid, out float3 lightDirection, out float3 lightColor, out float lightAtten)
{
	lightDirection = 0;
	lightColor = 0;
	lightAtten = 0;
	valid = false;

#ifndef SHADERGRAPH_PREVIEW

	int addlLightCount = GetAdditionalLightsCount();

	if (pixelLightIndex >= addlLightCount)
		return;

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
	
	lightDirection = light.direction;
	lightColor = light.color;
	lightAtten = light.shadowAttenuation * light.distanceAttenuation;
	valid = true;
	
#endif
}

void XGetAddlLight_half(int pixelLightIndex, half3 WorldPos, 
	out bool valid, out half3 lightDirection, out half3 lightColor, out half lightAtten)
{
	lightDirection = 0;
	lightColor = 0;
	lightAtten = 0;
	valid = false;

#ifndef SHADERGRAPH_PREVIEW

	int addlLightCount = GetAdditionalLightsCount();

	if (pixelLightIndex >= addlLightCount)
		return;

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
	
	lightDirection = light.direction;
	lightColor = light.color;
	lightAtten = light.shadowAttenuation * light.distanceAttenuation;
	valid = true;
	
#endif
}

void XGetMainLight_float(float3 worldPos, out float3 direction, out float3 color, out float shadowAtten)
{
#ifdef SHADERGRAPH_PREVIEW
    direction = normalize(float3(-0.5,0.5,-0.5));
    color = float3(1,1,1);
    shadowAtten = 1;
#else
	float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
	Light mainLight = GetMainLight(shadowCoord);
	direction = mainLight.direction;
	color = mainLight.color;
	shadowAtten = mainLight.shadowAttenuation;
#endif
}

void XGetMainLight_half(half3 worldPos, out half3 direction, out half3 color, out half shadowAtten)
{
#ifdef SHADERGRAPH_PREVIEW
    direction = normalize(half3(-0.5,0.5,0.5));
    color = half3(1,1,1);
    shadowAtten = 1;
#else
	half4 shadowCoord = TransformWorldToShadowCoord(worldPos);
	Light mainLight = GetMainLight(shadowCoord);
	direction = mainLight.direction;
	color = mainLight.color;
	shadowAtten = mainLight.shadowAttenuation;
#endif
}

#endif