#ifndef SAMPLE_REFLECTION_PROBES
#define SAMPLE_REFLECTION_PROBES

void URPReflectionProbe_float(float3 positionWS, float3 reflectVector, float3 screenspaceUV, float roughness, out float3 reflection)
{
#ifdef SHADERGRAPH_PREVIEW
    reflection = float3(0,0,0);
#else
    reflection = GlossyEnvironmentReflection(reflectVector, positionWS, roughness, 1.0h, screenspaceUV);
#endif
}

void URPReflectionProbe_half(float3 positionWS, half3 reflectVector, half3 screenspaceUV, half roughness, out half3 reflection)
{
#ifdef SHADERGRAPH_PREVIEW
    reflection = float3(0, 0, 0);
#else
    reflection = GlossyEnvironmentReflection(reflectVector, positionWS, roughness, 1.0h, screenspaceUV);
#endif
}

void XGetBakedGI_float(float3 PositionWS, float3 NormalWS, float3 PositionSS, float2 StaticUV, float2 DynamicUV, out float3 Out)
{
#ifdef SHADERGRAPH_PREVIEW
	Out = float3(0, 0, 0);
#else
	Out = SHADERGRAPH_BAKED_GI(PositionWS, NormalWS, PositionSS, StaticUV, DynamicUV, true);
#endif
}

void XGetBakedGI_half(float3 PositionWS, float3 NormalWS, float3 PositionSS, float2 StaticUV, float2 DynamicUV, out float3 Out)
{
#ifdef SHADERGRAPH_PREVIEW
	Out = float3(0, 0, 0);
#else
	Out = SHADERGRAPH_BAKED_GI(PositionWS, NormalWS, PositionSS, StaticUV, DynamicUV, true);
#endif
}

#endif