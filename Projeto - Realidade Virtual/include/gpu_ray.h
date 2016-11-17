#ifndef GPU_RAY_H_
#define GPU_RAY_H_

#include <cuda_runtime.h>
#include <thrust/device_vector.h>

#include "gpu_renderable_object.h"

namespace gpu {

class GPURenderableObject;

// TODO(Mateus): implement a stack on device (thrust::device_vector cannot be used on device).
struct GPURay {
  __device__ GPURay(const float3 &origin, const float3 &direction)
      : origin(origin),
        direction(direction),
        depth(1) {}
  __device__ GPURay(const float3 &origin, const float3 &direction, int depth)
      : origin(origin),
        direction(direction),
        depth(depth) {}
  __device__ GPURay(const float3 &origin, const float3 &direction,
                    const thrust::device_vector<GPURenderableObject*> &objs_stack, int depth)
       : origin(origin),
         direction(direction),
         objs_stack(objs_stack),
         depth(depth) {}
  __device__ ~GPURay() {}

  float3 origin;
  float3 direction;
  thrust::device_vector<GPURenderableObject*> objs_stack;
  int depth;
};
}

#endif  // GPU_RAY_H_