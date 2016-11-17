#ifndef GPU_TRIANGULAR_OBJECT_H_
#define GPU_TRIANGULAR_OBJECT_H_

#include <cuda_runtime.h>

#include "gpu_material.h"
#include "gpu_ray.h"
#include "gpu_renderable_object.h"
#include "gpu_matrix.h"

namespace gpu {

class GPUTriangularObject : public GPURenderableObject {
 public:
  __device__ GPUTriangularObject(const GPUMaterial &material, const float3 *vertices,
                                 const int3 *faces, int num_faces);
  __device__ ~GPUTriangularObject() {
    delete[] this->planes_coeffs_;
    delete[] this->linear_systems_;
  }

  __device__ float GetIntersectionParameter(const GPURay &ray, float3 *normal) const;

 private:
  float4* planes_coeffs_;        // Plane coefficients where each face belongs.
  GPUMatrix* linear_systems_;  // Upper triangular system matrices.
  int num_faces_;
};

}  // namespace gpu


#endif  // GPU_TRIANGULAR_OBJECT_H_