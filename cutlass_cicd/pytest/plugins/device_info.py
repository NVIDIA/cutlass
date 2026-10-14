import os


def _get_device_compute_capability():
    try:
        import cuda.bindings.driver as drv
        from cuda.bindings.driver import CUdevice_attribute as dev_attr

        def drv_api(api_name, *args):
            ret_code, *result = getattr(drv, api_name)(*args)
            if ret_code:
                raise ValueError(f"CUDA error: {ret_code}")
            return result[0] if len(result) == 1 else result

        drv_api("cuInit", 0)
        device = drv_api("cuDeviceGet", 0)
        major = drv_api(
            "cuDeviceGetAttribute",
            dev_attr.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR,
            device,
        )
        minor = drv_api(
            "cuDeviceGetAttribute",
            dev_attr.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR,
            device,
        )
        return f"{major}{minor}"
    except Exception as e:
        return None


compute_capability = _get_device_compute_capability()
