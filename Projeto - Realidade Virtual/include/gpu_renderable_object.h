#ifndef GPU_RENDERABLE_OBJECT_H_
#define GPU_RENDERABLE_OBJECT_H_

#include <cuda_runtime.h>

#include "gpu_material.h"
#include "gpu_ray.h"

namespace gpu {

struct GPURay;

class GPURenderableObject {
 public:
  __device__ explicit GPURenderableObject(const GPUMaterial &material)
      : kMaterial(material),
        kEps(1.0e-03f) {}
  __device__ ~GPURenderableObject() {}

  __device__ virtual float GetIntersectionParameter(const GPURay &ray, float3 *normal) const = 0;

  // Accessors.
  __device__ const GPUMaterial& material() const { return this->kMaterial; }

 protected:
  const float kEps;
  const GPUMaterial kMaterial;
};

}  // namespace gpu

#endif  // GPU_RENDERABLE_OBJECT_H_