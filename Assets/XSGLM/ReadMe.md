*XSGLM = Xuxing Shader Graph Lighting Model*

by 徐行（土星程序猿 @ B站），xux660@hotmail.com，微信：xux660

本库是使用 Shader Graph 自定义光照模型的示例和一些基础设施。

看最外层的 ExampleGraph_Basic 和 ExampleGraph_XStdMaster，应该很快就知道怎么使用。

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

存放完整的材质“主节点”，
在“主节点”中，获取所有需要的灯光信息，结合光照模型进行光照计算。
最后，使用 unlit 材质图输出“主节点”的颜色。
