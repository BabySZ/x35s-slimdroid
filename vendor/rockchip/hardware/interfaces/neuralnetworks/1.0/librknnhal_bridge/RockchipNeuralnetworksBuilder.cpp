#include <cutils/properties.h>
#include "RockchipNeuralnetworksBuilder.h"

using ::android::hidl::allocator::V1_0::IAllocator;
using ::android::hidl::memory::V1_0::IMemory;
using ::android::hardware::hidl_memory;

using namespace std;
using namespace rockchip::hardware::neuralnetworks::V1_0;
using namespace android;

using ::android::hardware::Return;
using ::android::hardware::Void;
static bool g_debug_pro = 0;

#define CHECK() \
    if (g_debug_pro) ALOGE("%s", __func__)

#define allocateAsh(size, ...) \
    if (!size) { ALOGE("%s: size can't be 0!!!", __func__); \
        return -1; \
    } \
    _kAllocInterface->allocate(size, __VA_ARGS__)

static RKNNQueryCmd to_rknn_hal(rknn_query_cmd cmd) {
    switch (cmd) {
        case RKNN_QUERY_IN_OUT_NUM:
            return RKNNQueryCmd::RKNN_QUERY_IN_OUT_NUM;
        case RKNN_QUERY_INPUT_ATTR:
            return RKNNQueryCmd::RKNN_QUERY_INPUT_ATTR;
        case RKNN_QUERY_OUTPUT_ATTR:
            return RKNNQueryCmd::RKNN_QUERY_OUTPUT_ATTR;
        case RKNN_QUERY_PERF_DETAIL:
            return RKNNQueryCmd::RKNN_QUERY_PERF_DETAIL;
        case RKNN_QUERY_PERF_RUN:
            return RKNNQueryCmd::RKNN_QUERY_PERF_RUN;
        case RKNN_QUERY_SDK_VERSION:
            return RKNNQueryCmd::RKNN_QUERY_SDK_VERSION;
        default:
            return RKNNQueryCmd::RKNN_QUERY_CMD_MAX;
    }
}

static RKNNTensorType to_rknn_hal(rknn_tensor_type type) {
    switch (type)
    {
    case RKNN_TENSOR_FLOAT32:
        return RKNNTensorType::RKNN_TENSOR_FLOAT32;
    case RKNN_TENSOR_FLOAT16:
        return RKNNTensorType::RKNN_TENSOR_FLOAT16;
    case RKNN_TENSOR_INT8:
        return RKNNTensorType::RKNN_TENSOR_INT8;
    case RKNN_TENSOR_UINT8:
        return RKNNTensorType::RKNN_TENSOR_UINT8;
    case RKNN_TENSOR_INT16:
        return RKNNTensorType::RKNN_TENSOR_INT16;
    default:
        return RKNNTensorType::RKNNTensorType_MAX;
    }
}

static RKNNTensorFormat to_rknn_hal(rknn_tensor_format fmt) {
    switch (fmt) {
        case RKNN_TENSOR_NCHW:
            return RKNNTensorFormat::RKNN_TENSOR_NCHW;
        case RKNN_TENSOR_NHWC:
            return RKNNTensorFormat::RKNN_TENSOR_NHWC;
        default:
            return RKNNTensorFormat::RKNNTensorFormat_MAX;
    }
}

namespace rockchip {
namespace nn {

RockchipNeuralnetworksBuilder::RockchipNeuralnetworksBuilder() {
    _kRKNNInterface = IRKNeuralnetworks::getService();
    if (_kRKNNInterface == NULL) {
        ALOGE("Failed to getService: IRKNeuralnetworks[vendor.rknn-1-0]!");
    }
    _kAllocInterface = IAllocator::getService("ashmem");
    if (_kAllocInterface == NULL) {
        ALOGE("Failed to getService: IAllocator[android.ashmem-1-0]!");
    }

    ALOGE("Successfully initial.");
}

int RockchipNeuralnetworksBuilder::rknn_find_devices(rknn_devices_id* pdevs) {
    CHECK();
    Return<void> ret = _kRKNNInterface->rknnFindDevices([&](ErrorStatus status, RKNNDeviceID devices) {
        if ((int)status == RKNN_SUCC) {
            pdevs->n_devices = devices.n_devices;
            for(int i=0; i<devices.n_devices; i++) {
                memcpy(pdevs->types[i], devices.types[i].c_str(), strlen(devices.types[i].c_str()));
                memcpy(pdevs->ids[i], devices.ids[i].c_str(), strlen(devices.ids[i].c_str()));
            }
        } else {
            ALOGE("Failed to rknnFindDevices!\n");
        }
    });
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_init(rknn_context* context, void *pData, uint32_t size, uint32_t flag) {
    CHECK();
    int ret_code = 0;
    g_debug_pro = property_get_bool("persist.vendor.rknndebug", false);
    allocateAsh(size, [&](bool success, const hidl_memory& mem) {
        if (!success) {
            ALOGE("Allocate memory failed!");
        } else {
            const struct RKNNModel model = {
                //.name = "mobilenet_v1",
                //.path = "/data/mobilenet_v1-tf.rknn",
                .modelData = mem,
            };
            sp<IMemory> memory = mapMemory(mem);
            memory->update();
            memcpy(memory->getPointer(), pData, size);
            memory->commit();

            Return<void> ret =  _kRKNNInterface->rknnInit(model, size, flag, [&](ErrorStatus status, RKNNContext rContext) {
                if ((int)status == RKNN_SUCC) {
                    *context = rContext;
                    ALOGE("Client init Successfully!");
                } else {
                    ALOGE("Client init failed!");
                }
            });
            if (!ret.isOk()) {
                ALOGE("Ret Failed!");
                ret_code = -1;
            } else {
                ALOGE("Ret Successfully!");
            }
        }
    });
    return ret_code;
}

int RockchipNeuralnetworksBuilder::rknn_init2(rknn_context* context, void *pData, uint32_t size, uint32_t flag, rknn_init_extend* extend) {
    CHECK();
    allocateAsh(size, [&](bool success, const hidl_memory& mem) {
        if (!success) {
            ALOGE("Allocate memory failed!");
        } else {
            const struct RKNNModel model = {
                //.name = "mobilenet_v1",
                //.path = "/data/mobilenet_v1-tf.rknn",
                .modelData = mem,
            };
            sp<IMemory> memory = mapMemory(mem);
            memory->update();
            memcpy(memory->getPointer(), pData, size);
            memory->commit();
            std::string str_device_id(extend->device_id);
            const struct RKNNInitExtend ext {
                .device_id = str_device_id,
            };
            Return<void> ret =  _kRKNNInterface->rknnInit2(model, size, flag, ext, [&](ErrorStatus status, RKNNContext rContext) {
                if ((int)status == RKNN_SUCC) {
                    *context = rContext;
                    ALOGE("Client init Successfully!");
                } else {
                    ALOGE("Client init failed!");
                }
            });
            if (!ret.isOk()) {
                ALOGE("Ret Failed!");
            } else {
                ALOGE("Ret Successfully!");
            }
        }
    });
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_destroy(rknn_context context) {
    CHECK();
    _kRKNNInterface->rknnDestory(context);
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_query(rknn_context context, rknn_query_cmd cmd, void* info, uint32_t size) {
    CHECK();
    allocateAsh(size, [&](bool success, const hidl_memory& mem) {
        if (!success) {
            ALOGE("Allocate memory failed!");
        } else {
            sp<IMemory> pMem = mapMemory(mem);
            pMem->update();
            memcpy(pMem->getPointer(), info, size);
            pMem->commit();
            _kRKNNInterface->rknnQuery(context, to_rknn_hal(cmd), mem, size);
            memcpy(info, pMem->getPointer(), size);
        }
    });
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_inputs_set(rknn_context context, uint32_t n_inputs, rknn_input inputs[]) {
    CHECK();
    int poolSize = 0;
    for (int i = 0; i < n_inputs; i++) {
        poolSize += inputs[i].size;
    }
    allocateAsh(poolSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {

        } else {
            vector<RKNNInput> input_array;
            sp<IMemory> memory = mapMemory(mem);
            memory->update();
            for (uint32_t i = 0; i < n_inputs; i++) {
                // map memory
                uint32_t cur_offset = 0;
                for (uint32_t j = 0; j < i; j++) {
                    cur_offset += inputs[j].size;
                }

                memcpy(memory->getPointer(), inputs[i].buf, inputs[i].size);
                const struct DataLocation buf = {
                    .poolIndex = static_cast<uint32_t>(i),
                    .offset = cur_offset,
                    .length = static_cast<uint32_t>(inputs[i].size),
                };
                const struct RKNNInput input0 = {
                    .index = inputs[i].index,
                    .buf = buf,
                    .pass_through = false,
                    .type = to_rknn_hal(inputs[i].type),
                    .fmt = to_rknn_hal(inputs[i].fmt),
                };
                input_array.push_back(input0);
            }
            memory->commit();
            const struct Request request = {
                .n_inputs = static_cast<uint32_t>(input_array.size()),
                .inputs = input_array,
                .pool = mem,
            };
            Return<ErrorStatus> ret = _kRKNNInterface->rknnInputsSet(context, request);
            if (!ret.isOk()) {
                ALOGE("rknnInputsSet error!");
            }
        }
    });
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_run(rknn_context context, rknn_run_extend* extend) {
    CHECK();
    const struct RKNNRunExtend rExt = {
        .frame_id = extend?extend->frame_id:0,
    };
    Return<ErrorStatus> ret = _kRKNNInterface->rknnRun(context, rExt);
    if (ret.isOk()) {
        return 0;
    } else {
        ALOGE("run error!");
        return -1;
    }
}

int RockchipNeuralnetworksBuilder::rknn_outputs_get(rknn_context context, uint32_t n_outputs, rknn_output outputs[], rknn_output_extend* extend) {
    CHECK();
    int poolSize = 0;
    for (int i = 0; i < n_outputs; i++) {
        if (!outputs[i].is_prealloc) {
            ALOGE("error: %s: outputs[].is_prealloc must be true!!!", __func__);
            return 0;
        }
        poolSize += outputs[i].is_prealloc?outputs[i].size:0;
    }

    allocateAsh(poolSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {
        } else {
            sp<IMemory> memory = mapMemory(mem);
            vector<RKNNOutput> output_array;
            // map memory
            for (uint32_t i = 0; i < n_outputs; i++) {
                uint32_t cur_offset = 0;
                for (uint32_t j = 0; j < i; j++) {
                    cur_offset += outputs[j].size;
                }
                const struct DataLocation result = {
                    .poolIndex = i,
                    .offset = cur_offset,
                    .length = outputs[i].size,
                };
                const struct RKNNOutput output0 = {
                    .want_float = true,
                    .is_prealloc = true,
                    .buf = result,
                };
                output_array.push_back(output0);
            }
            const struct RKNNOutputExtend gExt = {
                .frame_id = extend? extend->frame_id:0,
            };
            const struct Response response = {
                .n_outputs = static_cast<uint32_t>(output_array.size()),
                .outputs = output_array,
                .pool = mem,
            };
            Return<ErrorStatus> ret = _kRKNNInterface->rknnOutputsGet(context, response, gExt);
            if (!ret.isOk()) {
                ALOGE("rknnInputsSet error!");
            }
            void *resultPool = memory->getPointer();
            for (uint32_t i = 0; i < n_outputs; i++) {
                uint32_t cur_offset = 0;
                for (uint32_t j = 0; j < i; j++) {
                    cur_offset += outputs[j].size;
                }
                memcpy(outputs[i].buf, (char *)resultPool + cur_offset, outputs[i].size);
            }
        }
    });
    return 0;
}

int RockchipNeuralnetworksBuilder::rknn_outputs_release(rknn_context context, uint32_t n_outputs, rknn_output outputs[]) {
    CHECK();
    int poolSize = 0;
    for (int i = 0; i < n_outputs; i++) {
        if (!outputs[i].is_prealloc) {
            ALOGE("error: %s outputs[].is_prealloc must be true!!!", __func__);
            return 0;
        }
        poolSize += outputs[i].is_prealloc?outputs[i].size:0;
    }

    allocateAsh(poolSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {
        } else {
            sp<IMemory> memory = mapMemory(mem);
            vector<RKNNOutput> output_array;
            // map memory
            for (uint32_t i = 0; i < n_outputs; i++) {
                uint32_t cur_offset = 0;
                for (uint32_t j = 0; j < i; j++) {
                    cur_offset += outputs[j].size;
                }
                const struct DataLocation result = {
                    .poolIndex = i,
                    .offset = cur_offset,
                    .length = outputs[i].size,
                };
                const struct RKNNOutput output0 = {
                    .want_float = true,
                    .is_prealloc = true,
                    .buf = result,
                };
                output_array.push_back(output0);
            }
            const struct Response response = {
                .n_outputs = static_cast<uint32_t>(output_array.size()),
                .outputs = output_array,
                .pool = mem,
            };

            _kRKNNInterface->rknnOutputsRelease(context, response);
        }
    });
    return 0;
}

}
}
