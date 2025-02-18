// copied from CreateUnlitShaderGraph.cs, and did some name change

using System;
using UnityEditor.ShaderGraph;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGraph
{
    static class CreateXSGLMShaderGraph
    {
        [MenuItem("Assets/Create/Shader Graph/URP/XSGLM Shader Graph", priority = CoreUtils.Priorities.assetsCreateShaderMenuPriority + 1)]
        public static void CreateXSGLMGraph()
        {
            var target = (UniversalTarget)Activator.CreateInstance(typeof(UniversalTarget));
            target.TrySetActiveSubTarget(typeof(UniversalXSGLMSubTarget));

            var blockDescriptors = new[]
            {
                BlockFields.VertexDescription.Position,
                BlockFields.VertexDescription.Normal,
                BlockFields.VertexDescription.Tangent,
                BlockFields.SurfaceDescription.BaseColor,
            };

            GraphUtil.CreateNewGraphWithOutputs(new[] { target }, blockDescriptors);
        }
    }
}
