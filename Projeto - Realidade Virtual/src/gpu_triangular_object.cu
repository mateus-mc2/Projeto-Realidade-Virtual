#include "gpu_triangular_object.h"

#include <thrust/complex.h>

#include "gpu_linear_algebra.h"
#include "math_lib.h"

namespace gpu {

__device__ GPUTriangularObject::GPUTriangularObject(const GPUMaterial &material,
                                                    const float3 *vertices,
                                                    const int3 *faces,
                                                    int num_faces)
    : GPURenderableObject(material),
      planes_coeffs_(new float4[num_faces]),
      linear_systems_(new GPUMatrix[3 * num_faces]),
      num_faces_(num_faces) {
  for (int i = 0; i < num_faces_; ++i) {
    // Get plane equation (coefficients) - we are assuming the .obj files provide us the 
    // correct orientation of the vertices.
    float3 a = vertices[faces[i].x];
    float3 b = vertices[faces[i].y];
    float3 c = vertices[faces[i].z];

    float3 ab = make_float3(b.x - a.x, b.y - a.y, b.z - a.z);
    float3 ac = make_float3(c.x - a.x, c.y - a.y, c.z - a.z);
    float4 coeffs;
    
    coeffs.x = ab.y * ac.z - ab.z * ac.y;
    coeffs.y = ab.z * ac.x - ab.x * ac.z;
    coeffs.z = ab.x * ac.y - ab.y * ac.z;
    coeffs.w = -(coeffs.x * a.x + coeffs.y * a.y + coeffs.z * a.z);

    this->planes_coeffs_[i] = coeffs;

    // Get system's LUP decomposition matrices.
    GPUMatrix A(3, 3);

    A(0, 0) = a.x;
    A(1, 0) = a.y;
    A(2, 0) = a.z;

    A(0, 1) = b.x;
    A(1, 1) = b.y;
    A(2, 1) = b.z;

    A(0, 2) = c.x;
    A(1, 2) = c.y;
    A(2, 2) = c.z;

    GPUMatrix L, U, P;
    LUPDecomposition(A, &L, &U, &P);

    this->linear_systems_[3 * i] = L;
    this->linear_systems_[3 * i + 1] = U;
    this->linear_systems_[3 * i + 2] = P;
  }
}

__device__ float GPUTriangularObject::GetIntersectionParameter(const GPURay &ray, float3 *normal) const {
  float min_t = -1.0f;
  auto is_inner_point = [this](float a, float b, float c) -> bool { 
    return math::IsAlmostEqual(a + b + c, 1.0f, this->kEps) && a >= 0 && b >= 0 && c >= 0 && a <= 1
           && b <= 1 && c <= 1;
  };

  bool has_intersection = false;

  // Get nearest intersection point - need to check every single face of the object.
  for (int i = 0; i < num_faces_; ++i) {
    const float3 current_normal = make_float3(this->planes_coeffs_[i].x, this->planes_coeffs_[i].y,
                                              this->planes_coeffs_[i].z);
    const float numerator = -(this->planes_coeffs_[i].x * ray.origin.x +
                              this->planes_coeffs_[i].y * ray.origin.y +
                              this->planes_coeffs_[i].z * ray.origin.z +
                              this->planes_coeffs_[i].w);
    const float denominator = (current_normal.x * ray.direction.x +
                               current_normal.y * ray.direction.y +
                               current_normal.z * ray.direction.z);

    // Test if the ray and this plane are parallel (or if this plane contains the ray).
    // Returns a negative (dummy) parameter t if this happens.
    if (math::IsAlmostEqual(denominator, 0.0f, this->kEps)) {
      return -1.0;
    }

    float curr_t = numerator / denominator;
    GPUMatrix intersection_point(3, 1);

    intersection_point(0, 0) = ray.origin.x + curr_t * ray.direction.x;
    intersection_point(1, 0) = ray.origin.y + curr_t * ray.direction.y;
    intersection_point(2, 0) = ray.origin.z + curr_t * ray.direction.z;

    intersection_point = this->linear_systems_[3 * i + 2] * intersection_point;
    GPUMatrix barycentric_coords(3, 1);

    ApplyForwardSubstitution(this->linear_systems_[3 * i], intersection_point, &barycentric_coords);
    ApplyBackSubstitution(this->linear_systems_[3 * i + 1], barycentric_coords, &barycentric_coords);

    bool is_inside = is_inner_point(barycentric_coords(0, 0), barycentric_coords(1, 0),
                                    barycentric_coords(2, 0));

    if (is_inside && (!has_intersection || (min_t > curr_t && curr_t > this->kEps))) {
      min_t = curr_t;
      (*normal) = current_normal;
      has_intersection = true;
    }
  }

  if (has_intersection) {
    math::Normalize(normal);
  }

  return min_t;
}

}  // namespace gpu
