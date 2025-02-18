*XSGLM = Xuxing Shader Graph Lighting Model*

by 徐行（土星程序猿 @ B站），xux660@hotmail.com，微信：xux660

本库是使用 Shader Graph 自定义光照模型的示例和一些基础设施。

看 XStandardGraph，应该很快就知道怎么使用。

*核心思想是：*

1. 通过 Custom Function 获取灯光参数；
2. 以 Sub-Graph 的形式制作光照模型；
3. 使用 1 获取的参数调用 2，累加所有光的贡献；
4. 使用 unlit graph 直接输出 3 的颜色；


*BasicLMs 目录:*

全称 Basic Light Models。

存放最基础的单一目的的光照模型，
例如漫反射、高光。


*CombinedLMs 目录：*

全称 Combined Light Models。

存放由基础光照模型组合出来的光照模型，
目前有最常用的一种光照模型以及环境光。


*Masters 目录：*

“主节点”，有点类似 Blender 材质编辑器中的 BSDF。
在“主节点”中，获取所有需要的灯光信息，结合光照模型进行光照计算。


*如何使用主节点*

使用 unlit 材质图，把材质的光照模型从 "unlit" 修改为 "XSGLM"，把各种纹理和参数连入“主节点”的输入，
（类似以前把它们连入 Lit 材质 Fragment 的 Base Color 等部分），然后把主节点的输出连到 Fragment 的 Base Color。

在把主节点的输出连入 Base Color 之前，可以对其进行各种处理，如 Filter、ApplyFog 等。

甚至还可以结合多个主节点的输出。


*Editor 目录*

在 Shader Graph 中扩展了一种新的 SubTarget（也就是 Material 类型）——XSGLM，在 Graph Settings 中可以指定。
扩展这个新 SubTarget 的目的是，给 ShaderGraph 添加跟 Lit 一致的 Keywords。
一般的自定义光照模型都是使用 Unlit，其中可能缺乏一些必要的 Keywords，导致阴影、光照之类的效果不对。
