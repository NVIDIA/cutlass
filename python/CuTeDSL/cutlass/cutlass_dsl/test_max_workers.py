"""Test that max_workers is always >= 1, even on single-cpu systems."""

import os
from unittest import mock


def compute_max_workers():
    """Mirror the logic in cutlass.py for computing max_workers."""
    return max(1, min(16, (os.cpu_count() or 8) // 2))


def test_single_cpu():
    with mock.patch("os.cpu_count", return_value=1):
        assert compute_max_workers() >= 1


def test_cpu_count_none():
    with mock.patch("os.cpu_count", return_value=None):
        assert compute_max_workers() >= 1


def test_normal_cpu_count():
    with mock.patch("os.cpu_count", return_value=8):
        assert compute_max_workers() == 4


if __name__ == "__main__":
    test_single_cpu()
    test_cpu_count_none()
    test_normal_cpu_count()
    print("all tests passed")
