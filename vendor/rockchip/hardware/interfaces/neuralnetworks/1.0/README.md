https://source.android.com/devices/architecture/hidl

### 文件说明

- Android.bp
  HAL的声明makefile，写好*.hal文件后，vendor/rockchip/hardware/interfaces/下执行update-makefiles.sh即可生成。
- *.hal
  hidl源文件，修改这些文件以更改接口。
- default/Android.bp 
  使用命令生成：hidl-gen -o vendor/rockchip/hardware/interfaces/neuralnetworks/1.0/default -Landroidbp-impl -rrockchip.hardware:vendor/rockchip/hardware/interfaces -randroid.hidl:system/libhidl/transport rockchip.hardware.neuralnetworks@1.0
- default/*.cpp, *.h
  使用命令生成：hidl-gen -o vendor/rockchip/hardware/interfaces/neuralnetworks/1.0/default -Lc++-impl -rrockchip.hardware:vendor/rockchip/hardware/interfaces -randroid.hidl:system/libhidl/transport rockchip.hardware.neuralnetworks@1.0
  生成后，具体接口的实现需要在这些源文件中添加。HIDL_FETCH这个是service的加载入口，需要自己添加。
- java/*
  使用命令生成：hidl-gen -o vendor/rockchip/hardware/interfaces/neuralnetworks/1.0/java -Ljava -rrockchip.hardware:vendor/rockchip/hardware/interfaces -randroid.hidl:system/libhidl/transport rockchip.hardware.neuralnetworks@1.0
  不需要修改，用于提供接口给Client，基本是做参考，用不上。
- default/service/*
  service的server注册服务，一般不需要修改，如果需要配置优先级等，可以自己修改。
- default/sepolicy/*
  SELinux配置，目前不需要修改，添加逻辑后需要修改对应配置。
- librknnhal_bridge/*
  编译后，生成在system/lib/下，作为Client和app进行通讯。需要把该库添加到linker namespace中，否则搜索不到: echo "librknnhal_bridge.so nopreload" >> /system/etc/public.libraries.txt
  详情: https://android.googlesource.com/platform/ndk/+/master/docs/PlatformApis.md
- nnapi_implementation/*
  提供给App jni链接的静态库，能够调用system/lib/librknnhal_bridge.so中暴露出的接口。
- RKNNHALApp/*
  App demo，写得比较简单，编译jni前，需要把nnapi_implementation.a更新到jni目录(app/src/main/cpp/)中。
- RKNNApiTestBin/*
  Client binary demo，可以直接和client通信，主要用于测试HAL的C++ api。

### 修改接口流程
建议把接口定义成 request/response的模式，这样修改接口时，只需要改request/response的结构定义即可，而不需要整套修改定义。
1. HAL声明文件，接口定义修改
- types.hal: 数据类型及结构体定义
- IRKNeuralnetworks.hal: 接口定义
- ILoadModelCallback.hal: 可以自定义一些回调接口
- 如果新增了hal文件，需要在Android.bp中添加，也可以执行update-makefiles.sh更新（脚本更新可能有些问题，更新完需要检查下）。

2. 更新HAL Server的实现代码 ——— 这里链接接入librknn_api.so
- 新增或修改接口，可以通过文档开头说的命令更新，也可以手动修改。命令更新会覆盖本地文件，请注意备份。
- RKNeuralnetworks.cpp: HAL接口转换到librknn_api接口

3. 更新system/lib/librknnhal_bridge.so
- 这个库是暴露给app使用的，需要配合nnapi_implementation使用。
- HalInterfaces.h: 头文件、命名空间等引入
- RockchipNeuralnetworksBuilder.*: 作为HAL Client的实体类，通过构造函数初始化时，会获取RKNN Service和allocator的实例。App最终会调到这里，把nnapi_implementation的接口转换成HAL Client接口;
- librknnhal_bridge.map.txt: NDK libs，暴露给app的接口
- rknnhal_bridge.*: 直接对接nnapi_implementation，将虚对象"ARKNNHAL"转换成RKNN HAL Client, 以达到App持有Client对象，却不用引入HAL相关头文件及动态库的效果；
- 修改或增加接口时，上述三组文件都需要修改。

4. 更新nnapi_implementation.a给App去链接使用
- 通过dlopen librknnhal_bridge.so实现，没有任何依赖。
- NeuralNetworksTypes.h: 映射函数定义，"函数名_fn"就是dlopen后，获取到的实际函数指针。
- rknn_api.h: 提供给App的接口，App端直接链接librknn_api_android.so后，调用该头文件的接口即可使用HAL。
- nnapi_implementation.cpp: 映射实现，增加接口后，这三个文件都需要修改。


### 工作流程
```
|----------------------------------------------------|
| SystemApp/Bin -- Client | ==> | RKNN HAL -- Server |
|----------------------------------------------------|
```
#### java api
```
|--------------------------------------------------------------------------------------------|
| App | ==> | frameworks api | ==> | frameworks service -- Client | ==> | RKNN HAL -- Server |
|--------------------------------------------------------------------------------------------|
```
#### c/c++ api (App直接作为HAL的Client)
```
|------------------------------------------------------------------------------------------------------------------------------------|
|-------------       Apk        -------------------------|---------------------------------  System  --------------------------------|
|--------------------------------------------------------|---------------------------------------------------------------------------|
| App | ==> | jni | == link ==> | nnapi_implementation.a | == dlopen ==> | librknnhal_bridge.so -- Client | ==> | RKNN HAL -- Server |
|------------------------------------------------------------------------------------------------------------------------------------|
```
### TODO
1. HAL(RKNeuralnetworks.cpp)
- HAL中的prealloc问题，如果需要支持prealloc=false的接口，可以在librknnhal_bridge.so中修改实现；
- HAL中rknnFindDevices需要再修改确认；
- HAL中rknnInputsSet，在支持多个input时，需要再修改确认当前代码逻辑是否存在问题；
- HAL中rknnOutputsGet，问题同上，并且需要确认第一条的prealloc问题，建议在rknnhal_bridge实现，HAL接口这里只考虑prealloc=true的情况；
- HAL中rknnOutputsRelease，和prealloc挂钩，需要确认prealloc=true的情况下，是否还需要调用，如果不需要，则HAL中不需要考虑；
2. rknnhal_bridge(RockchipNeuralnetworksBuilder.cpp)
- rknn_find_devices接口未转换
- rknn_init/init2考虑内存效率，当前memcpy拷贝模型数据可能比较慢，如果可以，建议直接从App端创建共享内存(Ashmem)，或者App端传路径下来直接加载到共享内存中。
- rknn_inputs_set, 需要考虑多个input，检查当前是否存在问题；
- rknn_outputs_get，同上，此外，这里考虑区分prealloc的情况；
- rknn_outputs_release，当前未做实现；

3. 直接从ISP驱动获取Camera预览数据，减少预览数据的多次拷贝
目标流程：
```
|----------------------------------------------------|
|            RKNN HAL               | <==> | ISP |
|        add a callback             |
|      //               \\          |
| for rknn_run | for app to display |
|     ||       |         ||         |
|   output  | ==> |App(draw result) |
|----------------------------------------------------|
```

当前流程：
```
----------------------------------------|
|               Camera Service                       |
|   getService //            \\ binder(fill data)    |
|----------------------------------------------------|
|         App         | <== Camera preview callback  |
|          ||         |------------------------------|
|          ||         | copy(fill data)              |
| preview data(array) |  ======>  |  Ashmem(shared)  |
|---------------------|-----------|------------------|
|                     |                  ||          |
|                     |           |    RKNN HAL      |
|----------------------------------------------------|
```
