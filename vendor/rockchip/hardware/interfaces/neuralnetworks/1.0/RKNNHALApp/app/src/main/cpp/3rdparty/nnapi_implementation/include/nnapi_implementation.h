/* Copyright 2017 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/
#ifndef RKNNAPI_NNAPI_IMPLEMENTATION_H_
#define RKNNAPI_NNAPI_IMPLEMENTATION_H_

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "NeuralNetworksTypes.h"

struct NnApi {
  bool nnapi_exists;
  int32_t android_sdk_version;

  int (*ARKNN_client_create)(ARKNNHAL **hal);
  int (*ARKNN_find_devices)(ARKNNHAL *hal, rknn_devices_id* pdevs);
  int (*ARKNN_init)(ARKNNHAL *hal, rknn_context *context, void *model, uint32_t size, uint32_t flag);
  int (*ARKNN_init2)(ARKNNHAL *hal, rknn_context* context, void *model, uint32_t size, uint32_t flag, rknn_init_extend* extend);
  int (*ARKNN_destroy)(ARKNNHAL *hal, rknn_context);
  int (*ARKNN_query)(ARKNNHAL *hal, rknn_context context, rknn_query_cmd cmd, void* info, uint32_t size);
  int (*ARKNN_inputs_set)(ARKNNHAL *hal, rknn_context context, uint32_t n_inputs, rknn_input inputs[]);
  int (*ARKNN_run)(ARKNNHAL *hal, rknn_context context, rknn_run_extend* extend);
  int (*ARKNN_outputs_get)(ARKNNHAL *hal, rknn_context, uint32_t n_outputs, rknn_output outputs[], rknn_output_extend* extend);
  int (*ARKNN_outputs_release)(ARKNNHAL *hal, rknn_context context, uint32_t n_ouputs, rknn_output outputs[]);

  int (*ASharedMemory_create)(const char* name, size_t size);
};

/**
 * Load the NNAPI implementation from the shared libraries.
 * The NnApi structure is filled with all the pointers. If one function doesn't
 * exist, a null pointer is stored.
 */
const NnApi* NnApiImplementation();

#endif  // RKNNAPI_NNAPI_IMPLEMENTATION_H_
