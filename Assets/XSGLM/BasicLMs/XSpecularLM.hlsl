#ifndef XSPECULAR
#define XSPECULAR

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"

void XSpecular_float(float3 normal, float3 lightDir, float3 viewDir, float smoothness, out float result)
{
	result = 0;

#ifndef SHADERGRAPH_PREVIEW

	BRDFData brdfData;
    
	brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN_SQRT);
	brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
	// brdfData.grazingTerm = saturate(smoothness + reflectivity);
	brdfData.normalizationTerm = brdfData.roughness * float(4.0) + float(2.0);
	brdfData.roughness2MinusOne = brdfData.roughness2 - float(1.0);
    
	result = DirectBRDFSpecular(brdfData, normal, lightDir, viewDir);
	
	result *= saturate(dot(normal, lightDir));
	
#endif

}

void XSpecular_half(half3 normal, half3 lightDir, half3 viewDir, half smoothness, out half result)
{
	result = 0;

#ifndef SHADERGRAPH_PREVIEW

	BRDFData brdfData;
    
    brdfData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
	brdfData.roughness = max(PerceptualRoughnessToRoughness(brdfData.perceptualRoughness), HALF_MIN_SQRT);
	brdfData.roughness2 = max(brdfData.roughness * brdfData.roughness, HALF_MIN);
	// brdfData.grazingTerm = saturate(smoothness + reflectivity);
	brdfData.normalizationTerm = brdfData.roughness * half(4.0) + half(2.0);
	brdfData.roughness2MinusOne = brdfData.roughness2 - half(1.0);
    
	result = DirectBRDFSpecular(brdfData, normal, lightDir, viewDir);
	
	result *= saturate(dot(normal, lightDir));
	
#endif
}

#endif
