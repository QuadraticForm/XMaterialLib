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

half3 XSpecular(half NDotL, half3 lightDir, half3 normal, half3 viewDir, half smoothness)
{
	float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
	half NdotH = saturate(dot(normal, halfVec));
	return pow(NdotH, smoothness) * NDotL;
}

#endif

void XAddAddlLights_float(float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView,
    float MainDiffuse, float3 MainSpecular, float3 MainColor,
    out float Diffuse, out float3 Specular, out float3 Color) {

    Diffuse = MainDiffuse;
    Specular = MainSpecular;
    Color = MainColor * (MainDiffuse + MainSpecular);

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
        Light light = XGetAddlLight(lightIndex, WorldPosition);
        float NdotL = saturate(dot(WorldNormal, light.direction));
        float atten = light.distanceAttenuation * light.shadowAttenuation;
        float thisDiffuse = atten * NdotL;
	float3 thisSpecular = 0;
	//XSpecular(thisDiffuse, light.direction, WorldNormal, WorldView, 1, Smoothness);
        Diffuse += thisDiffuse;
        Specular += thisSpecular;
        #if defined(_LIGHT_COOKIES)
            float3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
            light.color *= cookieColor
        #endif
        Color += light.color * (thisDiffuse + thisSpecular);
    LIGHT_LOOP_END
    float total = Diffuse + dot(Specular, float3(0.333, 0.333, 0.333));
    Color = total <= 0 ? MainColor : Color / total;
#endif
}

void XAddAddlLights_half(half Smoothness, half3 WorldPosition, half3 WorldNormal, half3 WorldView,
    half MainDiffuse, half3 MainSpecular, half3 MainColor,
    out half Diffuse, out half3 Specular, out half3 Color) {

    Diffuse = MainDiffuse;
    Specular = MainSpecular;
    Color = MainColor * (MainDiffuse + MainSpecular);

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
        Light light = XGetAddlLight(lightIndex, WorldPosition);
        half NdotL = saturate(dot(WorldNormal, light.direction));
        half atten = light.distanceAttenuation * light.shadowAttenuation;
        half thisDiffuse = atten * NdotL;
	half3 thisSpecular = 0;
	//XSpecular(thisDiffuse * light.color, light.direction, WorldNormal, WorldView, 1, Smoothness);
        Diffuse += thisDiffuse;
        Specular += thisSpecular;
        #if defined(_LIGHT_COOKIES)
            half3 cookieColor = SampleAdditionalLightCookie(lightIndex, WorldPosition);
            light.color *= cookieColor
        #endif
        Color += light.color * (thisDiffuse + thisSpecular);
    LIGHT_LOOP_END
    //needs to be float to avoid precision issues
    float total = Diffuse + dot(Specular, half3(0.333, 0.333, 0.333));
    Color = total <= 0 ? MainColor : Color / total;
#endif
}

void XExtLitModel_float(
    float3 BaseColor, float3 DiffuseColor, float3 F0, float Smoothness,
    float3 WorldPos, float3 WorldNormal, float3 WorldView,
    float3 LightDir, float3 LightColor, float LightAtten,
    out float3 Result)
{
    // TODO, make this PBR
	float NDotL = saturate(dot(WorldNormal, LightDir));
	float3 diffuse = NDotL * DiffuseColor;
	Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    // TODO, make this PBR
	float3 specular = F0 * XSpecular(NDotL, LightDir, WorldNormal, WorldView, Smoothness);
    
	Result = (diffuse + specular) * LightColor * LightAtten;
#endif
}

void XExtLitModel_half(
    half3 BaseColor, half3 DiffuseColor, half3 F0, half Smoothness,
    half3 WorldPos, half3 WorldNormal, half3 WorldView,
    half3 LightDir, half3 LightColor, half LightAtten,
    out half3 Result)
{
    // TODO, make this PBR
    half NDotL = saturate(dot(WorldNormal, LightDir));
    half3 diffuse = NDotL * DiffuseColor;
    Result = 0;
    
#ifndef SHADERGRAPH_PREVIEW
    // TODO, make this PBR
    half3 specular = F0 * XSpecular(NDotL, LightDir, WorldNormal, WorldView, Smoothness);
    
    Result = (diffuse + specular) * LightColor * LightAtten;
#endif
}

#endif