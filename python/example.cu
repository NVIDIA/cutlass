template <unsigned N> struct foo_t {
    static __device__ constexpr unsigned size = N;
};

template <class TA, class TB>
constexpr __device__ unsigned smem(TA t0, TB t1) {
    return TA::size + TB::size;
}