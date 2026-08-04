# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# cutlass DSL Chapter 8: MLIR Value Tree Debugging
#
# This tutorial covers both straightforward and tricky value-tracking cases.
#
# =============================================================================
# WHY THIS EXISTS: Understanding MLIR Value Tracking in Dynamic Loops
# =============================================================================
#
# BACKGROUND: THE MLIR CONSTRAINT
# -------------------------------
# When the DSL compiles Python code to MLIR (the underlying compiler IR),
# dynamic control flow like `for` loops becomes SCF (Structured Control Flow)
# operations. These SCF operations have a critical constraint:
#
#   The "iter_args" (loop-carried variables) must have a FIXED STRUCTURE
#   that remains IDENTICAL across all loop iterations.
#
# This means if you enter a loop with a variable that has 3 MLIR values
# (e.g., a Particle with position.x, position.y, velocity.x, velocity.y = 4 values),
# the loop body MUST return exactly 4 values of the same types.
#
# THE PROBLEM THIS SOLVES
# -----------------------
# Users often create custom Python classes to organize their data (Accumulators,
# Particles, Systems, etc.). The DSL needs to:
#
#   1. EXTRACT: Flatten these objects into a list of MLIR values for the loop
#   2. TRACK: Remember the structure so values can be reassembled
#   3. RECONSTRUCT: After the loop body, rebuild the Python objects
#   4. VERIFY: Ensure the returned structure matches the input structure
#
# When users accidentally change the structure mid-loop (add a field, change
# a type, resize a list), the DSL must detect this and provide a CLEAR error
# message explaining what went wrong.
#
# THE TREE-BASED APPROACH
# -----------------------
# Previously, MLIR values were tracked as flat lists, making errors cryptic:
#   "Expected 4 values but got 5" - Which field was added? No idea.
#
# The tree-based approach preserves the nested dict/list structure:
#   {
#       "position": {"x": ir.Value, "y": ir.Value},
#       "velocity": {"x": ir.Value, "y": ir.Value}
#   }
#
# This enables:
#   - Clear debug output showing the full structure with field names
#   - Precise error messages: "particle.position.x changed from f32 to i32"
#   - Compact diff tables showing exactly what changed
#
# COMMON STRUCTURE MISMATCH ERRORS
# --------------------------------
# 1. ADDING A FIELD: {value: f32} -> {value: f32, extra: f32}
# 2. CHANGING A TYPE: position.x starts as f32, body returns i32
# 3. RESIZING A LIST: particles list starts with 2 items, body returns 3 items
# 4. CHANGING LIST ELEMENT TYPE: forces[1] starts as f32, body returns i32
#
# All of these violate the MLIR constraint and will be caught with detailed errors.
#
# DEBUG OUTPUT CONTROL
# --------------------
# Use set_dynamic_debug(True, max_depth=N) to see what values flow through loops:
#   - max_depth=0: Only top-level loops
#   - max_depth=1: Top-level + 1 nested level
#   - max_depth=None: All levels (can be verbose!)
#
# The debug output shows:
#   [Level 0] DEBUG 'for'
#     source: myfile.py:42
#       for step in range(num_steps):
#     [0] type: Particle
#         Particle:
#           position:
#             x: f32
#             y: f32
#           velocity:
#             x: f32
#             y: f32
#     => flattened to 4 ir.Values
#
# =============================================================================
# WHAT THIS TUTORIAL DEMONSTRATES
# =============================================================================
#
# 1. Custom classes with __extract_mlir_values__ returning dict structures
# 2. Using enum and dataclass alongside dynamic expressions
# 3. Dynamic loops with iter_args using custom types
# 4. Debug printing of the MLIR value tree structure
# 5. ParticleSystem: handling lists of dynamic objects
# 6. Error cases: what happens when structure changes mid-loop
#
# The key insight is that __extract_mlir_values__ returns a nested dict/list
# structure (not a flat list), making it easier to understand and debug
# what MLIR values are being tracked.

"""MLIR value-tree debugging — custom classes in dynamic loops.

Demonstrates how cutlass tracks nested Python objects (dataclasses,
enums, lists of dynamic values) through MLIR SCF loop iter_args.
The tree-based value tracker gives precise error messages when
loop-carried variable structure changes mid-iteration, replacing
cryptic "expected N values but got M" with field-level diffs.
"""

from dataclasses import dataclass
from enum import Enum, auto

import cutlass
import cutlass.cute as cute
from cutlass.base_dsl.dsl import (
    extract_mlir_values,
    new_from_mlir_values,
    debug_print_mlir_values,
    set_dynamic_debug,
)


# =============================================================================
# 1. Define an Enum for operation modes
# =============================================================================


class ReductionMode(Enum):
    """Enum for different reduction operations (compile-time only)."""

    SUM = auto()
    MAX = auto()
    MIN = auto()


# =============================================================================
# 2. Define a dataclass for configuration (compile-time only)
# =============================================================================


@dataclass
class ReductionConfig:
    """Configuration for reduction operation (compile-time constant)."""

    mode: ReductionMode
    block_size: int
    use_fast_math: bool = True

    def describe(self) -> str:
        return f"Reduction({self.mode.name}, block={self.block_size})"


# =============================================================================
# 3. Define a custom class with __extract_mlir_values__ (dynamic expression)
# =============================================================================


class Accumulator:
    """
    A custom accumulator that tracks running sum, count, and current max.

    This class implements the DynamicExpression protocol with dict-based
    MLIR value extraction, allowing it to be used in JIT-compiled loops.
    """

    def __init__(
        self,
        running_sum: cutlass.Float32,
        count: cutlass.Int32,
        current_max: cutlass.Float32,
    ) -> None:
        self.running_sum = running_sum
        self.count = count
        self.current_max = current_max

    def __extract_mlir_values__(self) -> dict:
        """
        Extract MLIR values as a nested dict structure.

        Returns a dict with named fields, making it easy to understand
        which values correspond to which fields during debugging.
        """
        return {
            "running_sum": extract_mlir_values(self.running_sum, structured=True),
            "count": extract_mlir_values(self.count, structured=True),
            "current_max": extract_mlir_values(self.current_max, structured=True),
        }

    def __new_from_mlir_values__(self, values: dict) -> "Accumulator":
        """
        Reconstruct Accumulator from MLIR values dict.

        The values dict has the same structure as returned by __extract_mlir_values__.
        """
        new_sum = new_from_mlir_values(
            self.running_sum, values["running_sum"], structured=True
        )
        new_count = new_from_mlir_values(self.count, values["count"], structured=True)
        new_max = new_from_mlir_values(
            self.current_max, values["current_max"], structured=True
        )
        return Accumulator(new_sum, new_count, new_max)

    def accumulate(self, value: cutlass.Float32) -> "Accumulator":
        """Add a value to the accumulator and update statistics."""
        new_sum = self.running_sum + value
        new_count = self.count + cutlass.Int32(1)
        new_max = cute.math.max(self.current_max, value)
        return Accumulator(new_sum, new_count, new_max)

    def mean(self) -> cutlass.Float32:
        """Compute the mean of accumulated values."""
        return self.running_sum / cutlass.Float32(self.count)


# =============================================================================
# 4. A 2D coordinate dataclass and Particle using it
# =============================================================================


@dataclass
class Coord2D:
    """
    A 2D coordinate with x and y components.

    This uses the dataclass approach - by declaring fields with dynamic types
    (like cutlass.Float32), the DSL automatically handles MLIR value extraction
    without needing explicit __extract_mlir_values__ / __new_from_mlir_values__.
    """

    x: cutlass.Float32
    y: cutlass.Float32

    def __add__(self, other: "Coord2D") -> "Coord2D":
        """Add two coordinates."""
        return Coord2D(self.x + other.x, self.y + other.y)

    def __mul__(self, scalar: cutlass.Float32) -> "Coord2D":
        """Scale a coordinate by a scalar."""
        return Coord2D(self.x * scalar, self.y * scalar)


class Particle:
    """
    A particle with position and velocity, both as Coord2D.

    Demonstrates nested composition: Particle contains two Coord2D objects,
    and __extract_mlir_values__ delegates to them, creating a tree structure.
    """

    def __init__(self, position: Coord2D, velocity: Coord2D) -> None:
        self.position = position
        self.velocity = velocity

    def __extract_mlir_values__(self) -> dict:
        """
        Extract MLIR values by delegating to Coord2D components.

        This creates a nested tree structure:
        {
            "position": {"x": ..., "y": ...},
            "velocity": {"x": ..., "y": ...},
        }
        """
        return {
            "position": extract_mlir_values(self.position, structured=True),
            "velocity": extract_mlir_values(self.velocity, structured=True),
        }

    def __new_from_mlir_values__(self, values: dict) -> "Particle":
        """Reconstruct Particle from nested MLIR values dict."""
        new_position = new_from_mlir_values(
            self.position, values["position"], structured=True
        )
        new_velocity = new_from_mlir_values(
            self.velocity, values["velocity"], structured=True
        )
        return Particle(new_position, new_velocity)

    def step(self, dt: cutlass.Float32) -> "Particle":
        """Update position based on velocity: position += velocity * dt."""
        new_position = self.position + self.velocity * dt
        return Particle(new_position, self.velocity)


class ParticleSystem:
    """
    A system containing multiple particles.

    Demonstrates handling a LIST of dynamic objects inside a class.
    The __extract_mlir_values__ returns a dict with a "particles" key
    containing a list of particle value dicts.

    This shows what happens when you have mutable/dynamic entries
    inside a dictionary - the tree structure preserves the list
    and each particle's nested structure.
    """

    def __init__(self, particles: list) -> None:
        """
        Initialize with a list of Particle objects.

        Args:
            particles: List of Particle instances
        """
        self.particles = particles

    def __extract_mlir_values__(self) -> dict:
        """
        Extract MLIR values from all particles as a list.

        Returns a structure like:
        {
            "particles": [
                {"position": {"x": ..., "y": ...}, "velocity": {"x": ..., "y": ...}},
                {"position": {"x": ..., "y": ...}, "velocity": {"x": ..., "y": ...}},
                ...
            ]
        }
        """
        return {
            "particles": [
                extract_mlir_values(p, structured=True) for p in self.particles
            ]
        }

    def __new_from_mlir_values__(self, values: dict) -> "ParticleSystem":
        """Reconstruct ParticleSystem from the list of particle values."""
        new_particles = [
            new_from_mlir_values(old_p, new_vals, structured=True)
            for old_p, new_vals in zip(self.particles, values["particles"])
        ]
        return ParticleSystem(new_particles)

    def step_all(self, dt: cutlass.Float32) -> "ParticleSystem":
        """Update all particles by one time step."""
        return ParticleSystem([p.step(dt) for p in self.particles])

    def __len__(self) -> int:
        return len(self.particles)

    def __getitem__(self, idx: int) -> Particle:
        return self.particles[idx]


# =============================================================================
# 5. Debug print helper - call this outside JIT context to see the tree
# =============================================================================


def print_value_tree(name: str, obj: object) -> None:
    """
    Print the MLIR value tree for an object.

    Call this at JIT compile time (not inside @kernel) to see the structure.
    """
    print(f"\n{'=' * 60}")
    print(f"MLIR Value Tree for: {name}")
    print(f"{'=' * 60}")
    print(debug_print_mlir_values(obj))
    print(f"{'=' * 60}\n")


# =============================================================================
# 6. Kernel and JIT functions demonstrating tree capture
# =============================================================================


@cute.kernel
def reduction_kernel(
    data_arr: cutlass.Array,
    result_arr: cutlass.Array,
    N: cutlass.Constexpr[int],
    config: cutlass.Constexpr[ReductionConfig],
) -> None:
    """
    Simple reduction kernel demonstrating Accumulator in a loop.

    The Accumulator class is used as iter_args, and its __extract_mlir_values__
    produces a dict structure that can be debugged with debug_print_mlir_values.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    # Only thread 0 does the work for simplicity
    if tidx == 0 and bidx == 0:
        # Initialize accumulator
        acc = Accumulator(
            running_sum=cutlass.Float32(0.0),
            count=cutlass.Int32(0),
            current_max=cutlass.Float32(-3.4028235e38),
        )

        # Dynamic loop with Accumulator as iter_args
        # The loop infrastructure will call __extract_mlir_values__ on acc
        # to get the MLIR values for the loop's iter_args
        for i in range(N):
            val = data_arr[i]
            acc = acc.accumulate(val)

        # Store results
        result_arr[0] = acc.running_sum
        result_arr[1] = cutlass.Float32(acc.count)
        result_arr[2] = acc.current_max
        result_arr[3] = acc.mean()


@cute.kernel
def particle_simulation_kernel(
    result_x_arr: cutlass.Array,
    result_y_arr: cutlass.Array,
    num_steps: cutlass.Constexpr[int],
) -> None:
    """
    Simple particle simulation demonstrating Particle in a loop.

    The Particle class has nested structure in its __extract_mlir_values__,
    demonstrating how the tree structure preserves hierarchy.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Initialize particle at origin with velocity (1, 0.5)
        particle = Particle(
            position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
            velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.5)),
        )

        dt = cutlass.Float32(0.1)

        # Dynamic loop with Particle as iter_args
        for step in range(num_steps):
            particle = particle.step(dt)

        # Store final position
        result_x_arr[0] = particle.position.x
        result_y_arr[0] = particle.position.y


@cute.jit
def run_reduction(
    data_tensor: cutlass.Array,
    result_tensor: cutlass.Array,
    N: cutlass.Constexpr[int],
    config: cutlass.Constexpr[ReductionConfig],
) -> None:
    """JIT function to launch reduction kernel."""
    reduction_kernel(data_tensor, result_tensor, N, config).launch(
        grid=(1, 1, 1),
        block=(1, 1, 1),
    )


@cute.jit
def run_particle_simulation(
    result_x: cutlass.Array,
    result_y: cutlass.Array,
    num_steps: cutlass.Constexpr[int],
) -> None:
    """JIT function to launch particle simulation kernel."""
    particle_simulation_kernel(result_x, result_y, num_steps).launch(
        grid=(1, 1, 1),
        block=(1, 1, 1),
    )


# =============================================================================
# Example 3: ParticleSystem - A list of particles inside a class
# =============================================================================


@cute.kernel
def particle_system_kernel(
    result_arr: cutlass.Array,  # Output: [num_particles, 2] for x,y
    num_particles: cutlass.Constexpr[int],
    num_steps: cutlass.Constexpr[int],
) -> None:
    """
    Simulate a system of multiple particles.

    This demonstrates using a LIST of dynamic objects inside a class.
    The ParticleSystem contains multiple Particle objects, each with
    their own position and velocity.

    The debug output will show the tree structure with nested lists.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Initialize particles with different velocities
        # Particle 0: velocity (1.0, 0.0) - moves right
        # Particle 1: velocity (0.0, 1.0) - moves up
        # Particle 2: velocity (0.5, 0.5) - moves diagonally
        particles_list = [
            Particle(
                position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.0)),
            ),
            Particle(
                position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                velocity=Coord2D(cutlass.Float32(0.0), cutlass.Float32(1.0)),
            ),
            Particle(
                position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                velocity=Coord2D(cutlass.Float32(0.5), cutlass.Float32(0.5)),
            ),
        ]

        system = ParticleSystem(particles_list)
        dt = cutlass.Float32(0.1)

        # Dynamic loop with ParticleSystem as iter_arg
        # This shows how a list of particles flows through the loop
        for step in range(num_steps):
            system = system.step_all(dt)

        # Store final positions for all particles
        # Use range_constexpr since num_particles is a compile-time constant
        for i in cutlass.range_constexpr(num_particles):
            result_arr[i * 2] = system[i].position.x
            result_arr[i * 2 + 1] = system[i].position.y


@cute.jit
def run_particle_system(
    result_positions: cutlass.Array,
    num_particles: cutlass.Constexpr[int],
    num_steps: cutlass.Constexpr[int],
) -> None:
    """JIT function to launch particle system kernel."""
    particle_system_kernel(result_positions, num_particles, num_steps).launch(
        grid=(1, 1, 1),
        block=(1, 1, 1),
    )


# =============================================================================
# COUNTER-EXAMPLE: What happens when loop variable structure changes?
# =============================================================================


class BadAccumulator:
    """
    An accumulator that INCORRECTLY changes its structure during iteration.

    This demonstrates what NOT to do - the loop body returns a different
    structure than it received, which will cause an error.
    """

    def __init__(self, value: cutlass.Float32, extra: cutlass.Float32 = None) -> None:
        self.value = value
        self.extra = extra  # This field may or may not be present

    def __extract_mlir_values__(self) -> dict:
        if self.extra is None:
            # Only one field
            return {"value": extract_mlir_values(self.value, structured=True)}
        else:
            # Two fields - different structure!
            return {
                "value": extract_mlir_values(self.value, structured=True),
                "extra": extract_mlir_values(self.extra, structured=True),
            }

    def __new_from_mlir_values__(self, values: dict) -> "BadAccumulator":
        if "extra" in values:
            return BadAccumulator(
                new_from_mlir_values(self.value, values["value"], structured=True),
                new_from_mlir_values(self.extra, values["extra"], structured=True),
            )
        else:
            return BadAccumulator(
                new_from_mlir_values(self.value, values["value"], structured=True),
            )

    def bad_update(self, new_val: cutlass.Float32) -> "BadAccumulator":
        """This adds a new field, changing the structure!"""
        return BadAccumulator(self.value + new_val, extra=new_val)


@cute.kernel
def bad_structure_change_kernel(
    data_arr: cutlass.Array,
    result_arr: cutlass.Array,
    N: cutlass.Constexpr[int],
) -> None:
    """
    COUNTER-EXAMPLE: This kernel tries to change the loop variable structure.

    The loop starts with BadAccumulator(value=0.0) which has 1 field,
    but bad_update() returns BadAccumulator(value, extra) which has 2 fields.

    This SHOULD fail with a clear error message about structure mismatch.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Start with 1-field accumulator
        acc = BadAccumulator(value=cutlass.Float32(0.0))

        # This loop will fail because bad_update changes the structure
        for i in range(N):
            val = data_arr[i]
            acc = acc.bad_update(val)  # Returns 2-field accumulator!

        result_arr[0] = acc.value


@cute.jit
def run_bad_structure_change(
    data_tensor: cutlass.Array,
    result_tensor: cutlass.Array,
    N: cutlass.Constexpr[int],
) -> None:
    """JIT function that will fail due to structure change."""
    bad_structure_change_kernel(data_tensor, result_tensor, N).launch(
        grid=(1, 1, 1),
        block=(1, 1, 1),
    )


def test_structure_mismatch_error() -> None:
    """
    Test that changing loop variable structure produces a clear error.

    This function intentionally triggers an error to demonstrate the
    improved error messages when loop variable structure changes.
    """
    import torch

    print("\n" + "=" * 70)
    print("COUNTER-EXAMPLE: Structure Mismatch Error")
    print("=" * 70)
    print("\nThis test intentionally causes an error by changing the")
    print("structure of a loop variable during iteration.")
    print("\nThe loop starts with BadAccumulator(value) [1 field]")
    print("but bad_update() returns BadAccumulator(value, extra) [2 fields]")
    print("\n" + "-" * 70)

    N = 5
    data = torch.arange(1, N + 1, dtype=torch.float32, device="cuda")
    result = torch.zeros(1, dtype=torch.float32, device="cuda")

    data_tensor = cute.runtime.from_dlpack(data, assumed_align=16)
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    try:
        run_bad_structure_change(data_tensor, result_tensor, N)
        print("ERROR: Expected an exception but none was raised!")
    except Exception as e:
        print(f"\nCaught expected error:\n{type(e).__name__}: {e}")
        print("\n" + "-" * 70)
        print("This error correctly indicates that the loop variable")
        print("structure changed during iteration.")

    print("=" * 70)


# =============================================================================
# Additional Structure Mismatch Tests
# =============================================================================


class ParticleWithForces:
    """
    A particle with position, velocity, AND a list of force magnitudes.

    The forces list represents multiple force sources acting on the particle
    (e.g., gravity, drag, spring forces, etc.)
    """

    def __init__(self, position: Coord2D, velocity: Coord2D, forces: list) -> None:
        self.position = position
        self.velocity = velocity
        self.forces = forces  # List of Float32 force magnitudes

    def __extract_mlir_values__(self) -> dict:
        return {
            "position": extract_mlir_values(self.position, structured=True),
            "velocity": extract_mlir_values(self.velocity, structured=True),
            "forces": [extract_mlir_values(f, structured=True) for f in self.forces],
        }

    def __new_from_mlir_values__(self, values: dict) -> "ParticleWithForces":
        new_position = new_from_mlir_values(
            self.position, values["position"], structured=True
        )
        new_velocity = new_from_mlir_values(
            self.velocity, values["velocity"], structured=True
        )
        new_forces = [
            new_from_mlir_values(old_f, new_f, structured=True)
            for old_f, new_f in zip(self.forces, values["forces"])
        ]
        return ParticleWithForces(new_position, new_velocity, new_forces)


# -----------------------------------------------------------------------------
# Test 1: Adding a particle to ParticleSystem (list length change)
# -----------------------------------------------------------------------------


@cute.kernel
def bad_add_particle_kernel(
    result_arr: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    """
    BAD: Tries to add a particle to the system during iteration.
    This changes the list length, which is not allowed.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Start with 2 particles
        system = ParticleSystem(
            [
                Particle(
                    position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                    velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.0)),
                ),
                Particle(
                    position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                    velocity=Coord2D(cutlass.Float32(0.0), cutlass.Float32(1.0)),
                ),
            ]
        )

        for step in range(num_steps):
            # BAD: Adding a new particle changes the list length!
            new_particle = Particle(
                position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
                velocity=Coord2D(cutlass.Float32(0.5), cutlass.Float32(0.5)),
            )
            new_particles = system.particles + [new_particle]
            system = ParticleSystem(new_particles)

        result_arr[0] = system[0].position.x


@cute.jit
def run_bad_add_particle(
    result: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    bad_add_particle_kernel(result, num_steps).launch(grid=(1, 1, 1), block=(1, 1, 1))


def test_list_length_change_error() -> None:
    """Test error when list length changes during iteration."""
    import torch

    print("\n" + "=" * 70)
    print("TEST: List Length Change Error")
    print("=" * 70)
    print("\nThis test adds a particle to ParticleSystem during iteration,")
    print("changing the list from 2 particles to 3 particles.")
    print("\n" + "-" * 70)

    result = torch.zeros(1, dtype=torch.float32, device="cuda")
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    try:
        run_bad_add_particle(result_tensor, 5)
        print("ERROR: Expected an exception but none was raised!")
    except Exception as e:
        print(f"\nCaught expected error:\n{type(e).__name__}: {e}")

    print("=" * 70)


# -----------------------------------------------------------------------------
# Test 2: Changing coordinate type from Float32 to Int32
# -----------------------------------------------------------------------------


class BadParticleTypeChange:
    """A particle that incorrectly changes a coordinate type."""

    def __init__(
        self,
        position: Coord2D,
        velocity: Coord2D,
        use_int_x: bool = False,
    ) -> None:
        self.position = position
        self.velocity = velocity
        self.use_int_x = use_int_x

    def __extract_mlir_values__(self) -> dict:
        pos_vals = extract_mlir_values(self.position, structured=True)
        if self.use_int_x:
            # BAD: Change x from float to int!
            pos_vals = {
                "x": extract_mlir_values(
                    cutlass.Int32(0), structured=True
                ),  # Wrong type!
                "y": pos_vals["y"],
            }
        return {
            "position": pos_vals,
            "velocity": extract_mlir_values(self.velocity, structured=True),
        }

    def __new_from_mlir_values__(self, values: dict) -> "BadParticleTypeChange":
        new_position = new_from_mlir_values(
            self.position, values["position"], structured=True
        )
        new_velocity = new_from_mlir_values(
            self.velocity, values["velocity"], structured=True
        )
        return BadParticleTypeChange(new_position, new_velocity, self.use_int_x)

    def bad_step(self, dt: cutlass.Float32) -> "BadParticleTypeChange":
        """Returns a particle with x as Int32 instead of Float32!"""
        new_pos = self.position + self.velocity * dt
        return BadParticleTypeChange(new_pos, self.velocity, use_int_x=True)


@cute.kernel
def bad_type_change_kernel(
    result_arr: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    """
    BAD: Changes the type of position.x from Float32 to Int32.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        particle = BadParticleTypeChange(
            position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
            velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.5)),
        )

        dt = cutlass.Float32(0.1)

        for step in range(num_steps):
            particle = particle.bad_step(dt)  # Changes x to Int32!

        result_arr[0] = cutlass.Float32(0)  # Won't reach here


@cute.jit
def run_bad_type_change(
    result: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    bad_type_change_kernel(result, num_steps).launch(grid=(1, 1, 1), block=(1, 1, 1))


def test_type_change_error() -> None:
    """Test error when field type changes during iteration."""
    import torch

    print("\n" + "=" * 70)
    print("TEST: Field Type Change Error")
    print("=" * 70)
    print("\nThis test changes position.x from Float32 to Int32 during iteration.")
    print("\n" + "-" * 70)

    result = torch.zeros(1, dtype=torch.float32, device="cuda")
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    try:
        run_bad_type_change(result_tensor, 5)
        print("ERROR: Expected an exception but none was raised!")
    except Exception as e:
        print(f"\nCaught expected error:\n{type(e).__name__}: {e}")

    print("=" * 70)


# -----------------------------------------------------------------------------
# Test 3: Mutating one element in a list of floats to a different type
# -----------------------------------------------------------------------------


@cute.kernel
def bad_force_type_kernel(
    result_arr: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    """
    BAD: Changes one force magnitude from Float32 to Int32.

    The particle has forces = [Float32, Float32, Float32]
    but we change it to forces = [Float32, Int32, Float32]
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Particle with 3 force magnitudes (all Float32)
        particle = ParticleWithForces(
            position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
            velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.5)),
            forces=[cutlass.Float32(1.0), cutlass.Float32(2.0), cutlass.Float32(3.0)],
        )

        for step in range(num_steps):
            # BAD: Change middle force from Float32 to Int32!
            new_forces = [
                particle.forces[0] + cutlass.Float32(0.1),
                cutlass.Int32(5),  # WRONG TYPE!
                particle.forces[2] + cutlass.Float32(0.1),
            ]
            particle = ParticleWithForces(
                particle.position,
                particle.velocity,
                new_forces,
            )

        result_arr[0] = particle.forces[0]


@cute.jit
def run_bad_force_type(
    result: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    bad_force_type_kernel(result, num_steps).launch(grid=(1, 1, 1), block=(1, 1, 1))


def test_list_element_type_change_error() -> None:
    """Test error when a list element's type changes during iteration."""
    import torch

    print("\n" + "=" * 70)
    print("TEST: List Element Type Change Error")
    print("=" * 70)
    print("\nThis test changes forces[1] from Float32 to Int32.")
    print("forces starts as [Float32, Float32, Float32]")
    print("but changes to [Float32, Int32, Float32]")
    print("\n" + "-" * 70)

    result = torch.zeros(1, dtype=torch.float32, device="cuda")
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    try:
        run_bad_force_type(result_tensor, 5)
        print("ERROR: Expected an exception but none was raised!")
    except Exception as e:
        print(f"\nCaught expected error:\n{type(e).__name__}: {e}")

    print("=" * 70)


# -----------------------------------------------------------------------------
# Test 4: Large list with one element type change (tests truncation)
# -----------------------------------------------------------------------------


@cute.kernel
def bad_large_list_kernel(
    result_arr: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    """
    BAD: Changes one element in a large list from Float32 to Int32.

    The particle has forces = [20 x Float32]
    but we change forces[12] to Int32.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    if tidx == 0 and bidx == 0:
        # Particle with 20 force magnitudes (all Float32)
        particle = ParticleWithForces(
            position=Coord2D(cutlass.Float32(0.0), cutlass.Float32(0.0)),
            velocity=Coord2D(cutlass.Float32(1.0), cutlass.Float32(0.5)),
            forces=[cutlass.Float32(float(i)) for i in range(20)],
        )

        for step in range(num_steps):
            # BAD: Change forces[12] from Float32 to Int32!
            new_forces = [f + cutlass.Float32(0.1) for f in particle.forces]
            new_forces[12] = cutlass.Int32(999)  # WRONG TYPE at index 12!
            particle = ParticleWithForces(
                particle.position,
                particle.velocity,
                new_forces,
            )

        result_arr[0] = particle.forces[0]


@cute.jit
def run_bad_large_list(
    result: cutlass.Array, num_steps: cutlass.Constexpr[int]
) -> None:
    bad_large_list_kernel(result, num_steps).launch(grid=(1, 1, 1), block=(1, 1, 1))


def test_large_list_element_type_change_error() -> None:
    """Test error when a large list element's type changes during iteration."""
    import torch

    print("\n" + "=" * 70)
    print("TEST: Large List Element Type Change Error")
    print("=" * 70)
    print("\nThis test has 20 forces, and changes forces[12] from Float32 to Int32.")
    print("Tests that the error message shows the index of the changed element.")
    print("\n" + "-" * 70)

    result = torch.zeros(1, dtype=torch.float32, device="cuda")
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    try:
        run_bad_large_list(result_tensor, 5)
        print("ERROR: Expected an exception but none was raised!")
    except Exception as e:
        print(f"\nCaught expected error:\n{type(e).__name__}: {e}")

    print("=" * 70)


def test_all_structure_errors() -> None:
    """Run all structure mismatch error tests."""
    import torch

    if not torch.cuda.is_available():
        print("CUDA not available, skipping tests.")
        return

    cutlass.cuda.initialize_cuda_context()

    # Disable debug output for cleaner error messages
    set_dynamic_debug(False)

    print("\n" + "=" * 70)
    print("RUNNING ALL STRUCTURE MISMATCH ERROR TESTS")
    print("=" * 70)

    test_structure_mismatch_error()
    test_list_length_change_error()
    test_type_change_error()
    test_list_element_type_change_error()
    test_large_list_element_type_change_error()

    print("\n" + "=" * 70)
    print("ALL ERROR TESTS COMPLETED")
    print("=" * 70)


# =============================================================================
# 7. Demo function showing the debug output
# =============================================================================


def demo_value_tree_structure() -> None:
    """
    Demonstrate the MLIR value tree structure at host time.

    This shows what the __extract_mlir_values__ output looks like
    before the values are created (showing structure only).
    """
    print("\n" + "=" * 70)
    print("DEMO: MLIR Value Tree Structure (Host-time Preview)")
    print("=" * 70)

    # Create dummy objects to show structure
    # Note: In real usage, these would have actual MLIR values inside JIT context

    print("\n1. Accumulator structure (keys_only mode):")
    print("   __extract_mlir_values__ returns:")
    print("""   {
       "running_sum": <ir.Value>,   # Float32
       "count": <ir.Value>,         # Int32
       "current_max": <ir.Value>,   # Float32
   }""")

    print("\n2. Coord2D structure (reusable component):")
    print("   __extract_mlir_values__ returns:")
    print("""   {
       "x": <ir.Value>,  # Float32
       "y": <ir.Value>,  # Float32
   }""")

    print("\n3. Particle structure (composed of two Coord2D):")
    print("   __extract_mlir_values__ returns:")
    print("""   {
       "position": {      # Coord2D
           "x": <ir.Value>,
           "y": <ir.Value>,
       },
       "velocity": {      # Coord2D
           "x": <ir.Value>,
           "y": <ir.Value>,
       },
   }""")

    print("\n4. When these are used as iter_args in a for loop:")
    print("   - The DSL extracts the dict structure")
    print("   - Flattens it to a list for MLIR: [sum, count, max] or [x, y, vx, vy]")
    print("   - After the loop, unflattens back using the dict as template")
    print("   - This preserves field names for debugging!")

    print("\n" + "=" * 70)


def run_examples() -> None:
    """Run the example kernels and verify results."""
    import torch

    if not torch.cuda.is_available():
        print("CUDA not available, skipping kernel execution.")
        print("The structure demo above shows the key concepts.")
        return

    print("\n" + "=" * 70)
    print("RUNNING KERNELS")
    print("=" * 70)

    # Enable dynamic debug with depth limit
    # - max_depth=0: Only show top-level dynamic blocks
    # - max_depth=1: Show top-level and first nested level
    # - max_depth=None: Show all levels (unlimited)
    set_dynamic_debug(True, max_depth=1)
    print("\n[Debug enabled with max_depth=1 - showing top-level + 1 nested level]")

    # Initialize CUDA
    cutlass.cuda.initialize_cuda_context()

    # -------------------------------------------------------------------------
    # Example 1: Reduction with Accumulator
    # -------------------------------------------------------------------------
    print("\n--- Example 1: Reduction with Accumulator ---")

    N = 10
    data = torch.arange(1, N + 1, dtype=torch.float32, device="cuda")
    result = torch.zeros(4, dtype=torch.float32, device="cuda")

    data_tensor = cute.runtime.from_dlpack(data, assumed_align=16)
    result_tensor = cute.runtime.from_dlpack(result, assumed_align=16)

    config = ReductionConfig(
        mode=ReductionMode.SUM,
        block_size=256,
        use_fast_math=True,
    )

    print(f"Config: {config.describe()}")
    print(f"Input data: {data.tolist()}")

    # Run reduction
    run_reduction(data_tensor, result_tensor, N, config)
    torch.cuda.synchronize()

    print("Results:")
    print(f"  Sum: {result[0].item():.1f} (expected: {sum(range(1, N + 1))})")
    print(f"  Count: {result[1].item():.0f} (expected: {N})")
    print(f"  Max: {result[2].item():.1f} (expected: {N})")
    print(f"  Mean: {result[3].item():.2f} (expected: {sum(range(1, N + 1)) / N:.2f})")

    # -------------------------------------------------------------------------
    # Example 2: Particle simulation with nested structure
    # -------------------------------------------------------------------------
    print("\n--- Example 2: Particle Simulation with Nested Structure ---")

    num_steps = 100
    result_x = torch.zeros(1, dtype=torch.float32, device="cuda")
    result_y = torch.zeros(1, dtype=torch.float32, device="cuda")

    result_x_tensor = cute.runtime.from_dlpack(result_x, assumed_align=16)
    result_y_tensor = cute.runtime.from_dlpack(result_y, assumed_align=16)

    print(f"Simulating particle for {num_steps} steps")
    print("Initial: position=(0, 0), velocity=(1, 0.5), dt=0.1")

    # Run simulation
    run_particle_simulation(result_x_tensor, result_y_tensor, num_steps)
    torch.cuda.synchronize()

    expected_x = 1.0 * 0.1 * num_steps
    expected_y = 0.5 * 0.1 * num_steps

    print("Final position:")
    print(f"  x: {result_x[0].item():.2f} (expected: {expected_x:.2f})")
    print(f"  y: {result_y[0].item():.2f} (expected: {expected_y:.2f})")

    # -------------------------------------------------------------------------
    # Example 3: ParticleSystem with LIST of particles
    # -------------------------------------------------------------------------
    print("\n--- Example 3: ParticleSystem with List of Particles ---")

    num_particles = 3
    num_steps = 100

    # Result tensor: [num_particles * 2] for x,y pairs
    result_positions = torch.zeros(
        num_particles * 2, dtype=torch.float32, device="cuda"
    )
    result_positions_tensor = cute.runtime.from_dlpack(
        result_positions, assumed_align=16
    )

    print(f"Simulating {num_particles} particles for {num_steps} steps")
    print("Initial positions: all at (0, 0)")
    print("Velocities: (1,0), (0,1), (0.5,0.5)")

    # Run particle system simulation
    run_particle_system(result_positions_tensor, num_particles, num_steps)
    torch.cuda.synchronize()

    dt = 0.1
    expected_positions = [
        (1.0 * dt * num_steps, 0.0 * dt * num_steps),  # Particle 0
        (0.0 * dt * num_steps, 1.0 * dt * num_steps),  # Particle 1
        (0.5 * dt * num_steps, 0.5 * dt * num_steps),  # Particle 2
    ]

    print("Final positions:")
    for i in range(num_particles):
        x = result_positions[i * 2].item()
        y = result_positions[i * 2 + 1].item()
        ex, ey = expected_positions[i]
        print(f"  Particle {i}: ({x:.2f}, {y:.2f}) (expected: ({ex:.2f}, {ey:.2f}))")

    # Disable debug for clean output
    set_dynamic_debug(False)

    print("\n" + "=" * 70)
    print("PASS - All examples completed successfully!")
    print("=" * 70)
    print("\nDebug control usage:")
    print("  set_dynamic_debug(True)           # Enable for all levels")
    print("  set_dynamic_debug(True, max_depth=0)  # Only top-level")
    print("  set_dynamic_debug(True, max_depth=1)  # Top + 1 nested")
    print("  set_dynamic_debug(False)          # Disable")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == "error":
            # Run the original structure mismatch error demo
            cutlass.cuda.initialize_cuda_context()
            test_structure_mismatch_error()
        elif arg == "errors":
            # Run ALL error tests
            test_all_structure_errors()
        elif arg == "list":
            # Test list length change
            cutlass.cuda.initialize_cuda_context()
            test_list_length_change_error()
        elif arg == "type":
            # Test type change
            cutlass.cuda.initialize_cuda_context()
            test_type_change_error()
        elif arg == "listtype":
            # Test list element type change
            cutlass.cuda.initialize_cuda_context()
            test_list_element_type_change_error()
        elif arg == "largelist":
            # Test large list element type change (truncation)
            cutlass.cuda.initialize_cuda_context()
            test_large_list_element_type_change_error()
        else:
            print(f"Unknown argument: {arg}")
            print(
                "Usage: python 08_mlir_value_tree_debug.py "
                "[error|errors|list|type|listtype|largelist]"
            )
    else:
        # Show the structure demo (works without GPU)
        demo_value_tree_structure()

        # Run actual kernels if GPU available
        run_examples()
