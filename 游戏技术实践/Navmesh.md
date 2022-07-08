NavMesh Modifier

NavMesh Agent

NavMesh Surface

**NavMeshModifierVolume**

**NavMeshLink**

**NavMeshSourceTag**

[http://events.jianshu.io/p/d44fd7d4863f](http://events.jianshu.io/p/d44fd7d4863f)


# unity中NavMesh的静态生成与动态加载,以及踩坑与爬坑

[![](https://upload.jianshu.io/users/upload_avatars/19645488/036f75aa-5d09-402f-8632-0daa58ba23a2.jpg?imageMogr2/auto-orient/strip|imageView2/1/w/96/h/96/format/webp)](http://events.jianshu.io/u/01450ce9ecbf)[vectorZ](http://events.jianshu.io/u/01450ce9ecbf)关注

0.0982022.04.27 19:27:24字数 1,291阅读 632

## unity 导航数据的静态生成与动态加载

本文主要描述了如何使用更加方便的  **高级NavMesh构建工具** ，用以静态烘培&动态更新网格数据，还包括其中遇到的一些坑与爬坑指南。不包含一些基础知识描述，基础知识请看下面官方文档。

导航功能为unity内置功能，基础知识与具体各个组件功能与使用可见官方文档：
[https://docs.unity.cn/cn/2020.3/Manual/Navigation.html](https://links.jianshu.com/go?to=https%3A%2F%2Fdocs.unity.cn%2Fcn%2F2020.3%2FManual%2FNavigation.html)。

高级NavMesh构建工具未内置在官方包内，需要从github导入使用。github仓库地址：
[https://github.com/Unity-Technologies/NavMeshComponents](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2FUnity-Technologies%2FNavMeshComponents)。

### 1. 高级navmesh构建工具

工具包内主要包含这四个组件：

* **NavMeshSurface** – 用于为一种代理类型构建和启用 NavMesh 表面。
* **NavMeshModifier** – 根据变换层次影响 NavMesh 区域类型的数据生成。
* **NavMeshModifierVolume** – 基于体积影响 NavMesh 区域类型的数据生成。
* **NavMeshLink** – 为一种Agent连接相同或不同的 NavMesh 表面。

除了上面的组件外，工具包内包含的Example工程内也有一些脚本可以方便我们使用，例如后面会说到的navmesh动态更新使用到的 **NavMeshSourceTag** 。
另外由于该工具包是完全开源的，遇到任何问题都可以断点debug和直接修改源码来解决；

### 2. 静态烘培navmesh数据

使用 ***NavMeshSurface*** 组件进行静态烘培。

![](http://upload-images.jianshu.io/upload_images/19645488-eeb3f7f38a025dd1.png?imageMogr2/auto-orient/strip|imageView2/2/w/416/format/webp)

NavmeshSerface.png

* AgentType: 选择代理类型；
* CollectObjects: 可选择通过体积生成或子节点生成；
* IncludeLayers：包含的Layer；
* UseGeometry：通过mesh还是collider去确认生成的范围；
* DefaultArea：选择默认的区域类型；
* OverrideVoxelSize（体素大小）和OverrideTileSize（区块大小）算是导航组件中常有的属性，后面会详细介绍；

最下面的Clear按钮用来清理已生成的navmesh数据；Bake用来烘焙，点击后会在同一文件夹下生成。

![](http://upload-images.jianshu.io/upload_images/19645488-9852471af3965147.png?imageMogr2/auto-orient/strip|imageView2/2/w/521/format/webp)

场景中的NavMeshSurface组件生成了导航数据

> **爬坑指南** ：
>
> 点击Bake按钮生成数据成功后，打开Navigation面板会在场景中显示已经烘焙好的导航网格。
>
> ![](http://upload-images.jianshu.io/upload_images/19645488-3c5df1753409b8ee.png?imageMogr2/auto-orient/strip|imageView2/2/w/561/format/webp)
>
> 失败和成功的情况下，场景中的显示
>
> 但很多时候由于某些操作不正确或者工具本身问题，无法正常生成数据。如果生成后场景中没有显示导航网格，那么需要检查下是否有以下情况：
>
> 1. NavMeshSurface组件的节点是否是在场景中。预制体中烘培的数据会生成在Assets根目录下，且如果场景中引用了预制体也无法生效。并且因为场景中和预制体中都可以烘焙数据，且数据在不同目录，如果开发者不熟悉，管理不妥，则非常可能造成数据冗余；
> 2. clear按钮偶尔会无法删除掉旧的烘焙数据，再次生成时会生成了重复的副本，所以需要检查不要生成过多重复导航数据，或者自行修改保存逻辑，强制删除备份；
> 3. 在没有以上问题的前提下，如果出现无法烘焙出数据的情况，则切换下CollectObjects选项就可以了。应该是刷新机制有问题；

### 3. 动态加载navmesh数据

游戏进入时导航网格数据初始化很慢，在进入游戏时加载较大的网格数据时，普通配置的手机上甚至会出现卡住十几秒的情况。

跟着场景一次性加载较大的网格数据，除了初始化慢与占用内存外，有时候还不能很好满足业务需求。所以将较大的网格按功能分割成小块，在使用时再动态更新网格数据，也是一个必不可少的处理方式。

动态更新navmesh数据可以参考高级构建工具里的 ***NavMeshSourceTag*** 的使用，其主要逻辑分为：

1. 挂载NavMeshSourceTag组件的节点初始化时会把该节点记录在NavMeshSourceTags中；
2. NavMeshSourceTag.Collect() 将记录的所有Tags处理为官方接口使用的NavMeshBuildSource类。

在实际的项目中，我将上面代码里的 **s.area = 0;** 替换为根据NavMeshSourceTag组件内新加一个变量Area，这样在组件节点上自定义，动态更新生成不同Areas的导航数据；

![](http://upload-images.jianshu.io/upload_images/19645488-447b453a298ab2e1.png?imageMogr2/auto-orient/strip|imageView2/2/w/898/format/webp)

给官方脚本添加选择Area的功能

3. 手动调用RefreshNavMesh(),具体逻辑见代码与注释

> **爬坑指南** ：
>
> 游戏运行中，如果动态更新发现场景中没有生成导航数据，则需要检查以下部分：
>
> 1. 上面步骤3的代码中，bounds范围是否包含需要动态更新的节点；
> 2. 异步更新不会立即更新，需要一定的时间处理；
>
