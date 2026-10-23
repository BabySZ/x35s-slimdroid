#include <jni.h>
#include <string>
#include <errno.h>
#include "nnapi_implementation.h"
#include <android/log.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <stdint.h>
#include <stdlib.h>
#include <queue>
#include <fstream>
#define TAG "RKNNApp-JNI"
#define JNI_LOG(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

using namespace std;
static const NnApi* nnapi;
static rknn_context context;

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
        JNI_LOG("fopen %s failed, error: %s", path.c_str(), strerror(errno));
        return -1;
    }
    fseek(_fp, 0, SEEK_END);
    ret = ftell(_fp);
    fclose(_fp);
    JNI_LOG("%s -- size: %d", path.c_str(), ret);
    return ret;
}

int loadData(string path, void *data) {
    int ret = 0;
    FILE *_fp = fopen(path.c_str(), "rb");
    if (_fp == NULL) {
        JNI_LOG("fopen %s failed, error: %s", path.c_str(), strerror(errno));
        return -1;
    }
    fseek(_fp, 0, SEEK_END);
    ret = ftell(_fp);
    fseek(_fp, 0, SEEK_SET);
    if (ret != fread(data, 1, ret, _fp)) {
        JNI_LOG("fread failed, error: %s", strerror(errno));
        fclose(_fp);
        return -1;
    }
    fclose(_fp);
    return 0;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_rockchip_rknntest_MainActivity_init(JNIEnv *env, jobject thiz) {
    // TODO: implement init()
    nnapi = NnApiImplementation();
    if (nnapi && nnapi->nnapi_exists) {
        ARKNNHAL *hal;
        nnapi->ARKNN_client_create(&hal);
        if (hal) {
            std::string modelPath = "/data/mobilenet_v1-tf.rknn";
            int modelSize = getDataSize(modelPath);
            void *modelData = malloc(modelSize);
            loadData(modelPath, modelData);
            nnapi->ARKNN_init(hal, &context, modelData, modelSize, RKNN_FLAG_PRIOR_MEDIUM);

            std::string dataPath = "/data/dog.bin";
            int dataSize = getDataSize(dataPath);
            void *pData = malloc(dataSize);
            loadData(dataPath, pData);
            rknn_input inputs[1];
            inputs[0].index = 0;
            inputs[0].buf = pData;
            inputs[0].size = dataSize;
            inputs[0].pass_through = false;
            inputs[0].type = RKNN_TENSOR_UINT8;
            inputs[0].fmt = RKNN_TENSOR_NHWC;
            nnapi->ARKNN_inputs_set(hal, context, 1, inputs);

            nnapi->ARKNN_run(hal, context, nullptr);

            rknn_output outputs[1];
            outputs[0].want_float = true;
            outputs[0].is_prealloc = false;
            nnapi->ARKNN_outputs_get(hal, context, 1, outputs, nullptr);
            if (!outputs[0].buf) {
                return env->NewStringUTF("Get result failed!");
            }

            std::vector<std::pair<float, int>> top_results;
            get_top_n<float>((float *)outputs[0].buf, 1001,
                             5, 0.001f, &top_results, true);
            std::vector<string> labels;
            size_t label_count;
            float finalIdx = -0.1f;
            if (!ReadLabelsFile("/data/labels.txt", &labels, &label_count)) {
                for (const auto& result : top_results) {
                    const float confidence = result.first;
                    const int index = result.second;
                    if (confidence > finalIdx) finalIdx = index;
                    JNI_LOG("%f: %d %s", confidence, index, labels[index].c_str());
                }
            }
            string result = "create client ok. result: ";
            result += labels[finalIdx];
            return env->NewStringUTF(result.c_str());
        }
        nnapi->ASharedMemory_create("testnn", 100);
        return env->NewStringUTF("create ashmem ok.");
    }
    return env->NewStringUTF("create client failed.");
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_rockchip_rknntest_MainActivity_run(JNIEnv *env, jobject thiz) {
    // TODO: implement run()
    return env->NewStringUTF("Got result.");
}

