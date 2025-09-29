# Utilities

This folder contains various utilities for kernel authoring. Specifically, the implementation of the
following can be considered experimental and subject to breaking changes:

- static persistent tile scheduler defined in [`static_persistent_tile_scheduler.py`](./static_persistent_tile_scheduler.py)
- pipeline abstractions defined in [`pipeline.py`](./pipeline.py)
- grouped GEMM utilities defined [`grouped_gemm_tile_scheduler_helper.py`](./grouped_gemm_tile_scheduler_helper.py)
  and [`tensormap_manager.py`](./tensormap_manager.py)
