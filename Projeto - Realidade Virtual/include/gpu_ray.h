#ifndef GPU_RAY_H_
#define GPU_RAY_H_

#include <cuda_runtime.h>

#include "gpu_renderable_object.h"
#include "gpu_stack.h"

namespace gpu {

class GPURenderableObject;

// TODO(Mateus): implement a stack on device (thrust::device_vector cannot be used on device).
struct GPURay {
 public:
  GPURay(const float3 &origin, const float3 &direction)
      : origin(origin),
        direction(direction),
        depth(1) {}
  GPURay(const float3 &origin, const float3 &direction, int depth)
      : origin(origin),
        direction(direction),
        depth(depth) {}
  GPURay(const float3 &origin, const float3 &direction,
         const GPUStack<GPURenderableObject*> &objs_stack, int depth)
       : origin(origin),
         direction(direction),
         objs_stack(objs_stack),
         depth(depth) {}
  ~GPURay() {}

  float3 origin;
  float3 direction;
  GPUStack<GPURenderableObject*> objs_stack;
  int depth;
};
}

#endif  // GPU_RAY_H_
