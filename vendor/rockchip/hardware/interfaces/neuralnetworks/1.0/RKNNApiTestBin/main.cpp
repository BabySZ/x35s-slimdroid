#include <rockchip/hardware/neuralnetworks/1.0/IRKNeuralnetworks.h>
#include <log/log.h>
#include <iostream>
#include <android/hidl/allocator/1.0/IAllocator.h>
#include <android/hidl/memory/1.0/IMemory.h>
#include <hidlmemory/mapping.h>

#include <errno.h>
#include "rknn_api_lite.h"

#include <stdint.h>
#include <stdlib.h>
#include <fstream>
#include <algorithm>
#include <queue>
#include <sys/time.h>

using ::android::hidl::allocator::V1_0::IAllocator;
using ::android::hidl::memory::V1_0::IMemory;
using ::android::hardware::hidl_memory;

using namespace std;
using namespace rockchip::hardware::neuralnetworks::V1_0;
using namespace android;

using ::android::hardware::Return;
using ::android::hardware::Void;

/*
// Override default callback here.
struct LocalLoadModelCallback : public ILoadModelCallback {
    Return<void> notify(ErrorStatus status, const Model& model) override {
        sp<IMemory> memory = mapMemory(model.data);
        void *data = memory->getPointer();
        cout << "Override notify...model: " << toString(model) << ":" << toString(memory) << "," << data << "," << *(int *)data << endl;
        return Void();
    }
};
*/
template <class T>
void get_top_n(T* prediction, int prediction_size, size_t num_results,
               float threshold, std::vector<std::pair<float, int>>* top_results,
               bool input_floating) {
  // Will contain top N results in ascending order.
  std::priority_queue<std::pair<float, int>, std::vector<std::pair<float, int>>,
                      std::greater<std::pair<float, int>>>
      top_result_pq;

  const long count = prediction_size;  // NOLINT(runtime/int)
  for (int i = 0; i < count; ++i) {
    float value;
    if (input_floating)
      value = prediction[i];
    else
      value = prediction[i] / 255.0;
    // Only add it if it beats the threshold and has a chance at being in
    // the top N.
    if (value < threshold) {
      continue;
    }

    top_result_pq.push(std::pair<float, int>(value, i));

    // If at capacity, kick the smallest value out.
    if (top_result_pq.size() > num_results) {
      top_result_pq.pop();
    }
  }

  // Copy to output vector and reverse into descending order.
  while (!top_result_pq.empty()) {
    top_results->push_back(top_result_pq.top());
    top_result_pq.pop();
  }
  std::reverse(top_results->begin(), top_results->end());
}

int ReadLabelsFile(const string& file_name,
                            std::vector<string>* result,
                            size_t* found_label_count) {
  std::ifstream file(file_name);
  if (!file) {
    std::cerr << "Labels file " << file_name << " not found\n";
    return -1;
  }
  result->clear();
  string line;
  while (std::getline(file, line)) {
    result->push_back(line);
  }
  *found_label_count = result->size();
  const int padding = 16;
  while (result->size() % padding) {
    result->emplace_back();
  }
  return 0;
}
int getDataSize(string path) {
    int ret = 0;
    FILE *_fp = fopen(path.c_str(), "rb");
    if (_fp == NULL) {
        ALOGE("fopen %s failed, error: %s", path.c_str(), strerror(errno));
        return -1;
    }
    fseek(_fp, 0, SEEK_END);
    ret = ftell(_fp);
    fclose(_fp);
    cout << path.c_str() << "--size:" << ret << endl;
    return ret;
}

int loadData(string path, void *data) {
    int ret = 0;
    FILE *_fp = fopen(path.c_str(), "rb");
    if (_fp == NULL) {
        ALOGE("fopen %s failed, error: %s", path.c_str(), strerror(errno));
        return -1;
    }
    fseek(_fp, 0, SEEK_END);
    ret = ftell(_fp);
    fseek(_fp, 0, SEEK_SET);
    if (ret != fread(data, 1, ret, _fp)) {
        ALOGE("fread failed, error: %s", strerror(errno));
        fclose(_fp);
        return -1;
    }
    fclose(_fp);
    return 0;
}

int main() {
    sp<IRKNeuralnetworks> rknn = IRKNeuralnetworks::getService();
    sp<IAllocator> ashmemAllocator = IAllocator::getService("ashmem");
    cout << "getService[vendor.rknn-1-0]:" << ((rknn == NULL)?"Failed!":"Successfully!") << endl;
    cout << "getService[android.ashmem-1-0]:" << ((ashmemAllocator == NULL)?"Failed!":"Successfully!") << endl;
    cout << "initial complete!" << endl;
    //sp<ILoadModelCallback> myCallback = new LocalLoadModelCallback();

    int modelSize = getDataSize("/data/mobilenet_v1-tf.rknn");
    uint64_t rknn_context = 0;
    ashmemAllocator->allocate(modelSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {
            cout << "Allocate Failed!" <<endl;
        } else {
            const struct RKNNModel model = {
                .name = "mobilenet_v1",
                .path = "/data/mobilenet_v1-tf.rknn",
                .modelData = mem,
            };
            sp<IMemory> memory = mapMemory(mem);
            memory->update();
            loadData(model.path, memory->getPointer());
            memory->commit();

            Return<void> ret =  rknn->rknnInit(model, modelSize, RKNN_FLAG_PRIOR_MEDIUM, [&](ErrorStatus status, RKNNContext context) {
                if ((int)status == RKNN_SUCC) {
                    rknn_context = context;
                    cout << "init Successfully." << endl;
                } else {
                    cout << "init Failed" << endl;
                }
            });
            if (!ret.isOk()) {
                    cout << "init failed." << endl;
            } else {
                    cout << "init Successfully." << endl;
            }
        }
    });
    int imgDataSize = getDataSize("/data/dog.bin");
    //int imgDataSize = 224 * 224 * 3;
    ashmemAllocator->allocate(imgDataSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {

        } else {
            sp<IMemory> memory = mapMemory(mem);
            memory->update();
            //memset(memory->getPointer(), 0x11 , imgDataSize);
            loadData("/data/dog.bin", memory->getPointer());
            memory->commit();
            const struct DataLocation buf = {
                .poolIndex = 0,
                .offset = 0,
                .length = static_cast<uint32_t>(imgDataSize),
            };
            vector<RKNNInput> inputs;
            const struct RKNNInput input0 = {
                .index = 0,
                .buf = buf,
                .pass_through = false,
                .type = RKNNTensorType::RKNN_TENSOR_UINT8,
                .fmt = RKNNTensorFormat::RKNN_TENSOR_NHWC,
            };
            inputs.push_back(input0);
            const struct Request request = {
                .n_inputs = static_cast<uint32_t>(inputs.size()),
                .inputs = inputs,
                .pool = mem,
            };
            rknn->rknnInputsSet(rknn_context, request);
        }
    });
    const struct RKNNRunExtend rExt = {
        .frame_id = 0,
    };
    rknn->rknnRun(rknn_context, rExt);
    int resultSize = 10240;
    ashmemAllocator->allocate(resultSize, [&](bool success, const hidl_memory& mem) {
        if (!success) {
        } else {
            sp<IMemory> memory = mapMemory(mem);
            void *resultPool = memory->getPointer();
            const struct DataLocation result = {
                .poolIndex = 0,
                .offset = 0,
                .length = 4004,
            };
            vector<RKNNOutput> outputs;
            const struct RKNNOutput output0 = {
                .want_float = true,
                .is_prealloc = true,
                .buf = result,
            };
            outputs.push_back(output0);
            const struct RKNNOutputExtend gExt = {
                .frame_id = 0,
            };
            const struct Response response = {
                .n_outputs = static_cast<uint32_t>(outputs.size()),
                .outputs = outputs,
                .pool = mem,
            };
            rknn->rknnOutputsGet(rknn_context, response, gExt);
            // FIXME output size
            const size_t num_results = 5;
            const float threshold = 0.001f;

            // hal
            std::vector<std::pair<float, int>> top_results;
            get_top_n<float>((float*)resultPool+(sizeof(float) * result.offset), 1001,
                             num_results, threshold, &top_results, true);
            std::vector<string> labels;
            size_t label_count;
            if (!ReadLabelsFile("/data/labels.txt", &labels, &label_count)) {
                for (const auto& result : top_results) {
                    const float confidence = result.first;
                    const int index = result.second;
                    std::cout << confidence << ": " << index << " " << labels[index] << "\n";
                }
            }
        }
    });
    return 0;
}
