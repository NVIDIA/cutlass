import ast
import enum
import sys
import unittest
from unittest.mock import Mock

import cutlass
import cutlass.cute as cute
from cutlass.base_dsl.ast_preprocessor import DSLPreprocessor


class TestBoolOpPreprocessing(unittest.TestCase):
    def evaluate(self, tree, **bindings):
        namespace = {"__module_dsl__": cutlass, "__base_dsl__": cutlass.base_dsl}
        return eval(compile(tree, "<boolop>", "eval"), namespace | bindings)

    def test_boolops_in_class_scope(self):
        @cute.jit
        def entry():
            class Config:
                tiles = ((64, 64), (128, 64), (128, 128), (256, 128))
                selected = [(m, n) for m, n in tiles if m <= 128 and n <= 128]
                copied = [tile for tile in (True and selected)]

            class Mode(enum.Enum):
                TILE = True and 3

            return len(Config.copied), len(Mode)

        cute.compile(entry)
        self.assertEqual(entry(), (3, 1))

    def test_ternary_in_filtered_comprehension(self):
        @cute.jit
        def entry(flag: cutlass.Constexpr):
            return [
                tile if flag else 0
                for tile in (False or (1, 2, 3))
                if tile > 0 and tile < 3 and flag
            ][0]

        cute.compile(entry, True)
        self.assertEqual(entry(True), 1)

    def rewrite(self, source, mode="eval"):
        tree = ast.parse(source, mode=mode)
        with DSLPreprocessor(["cutlass"]).get_session() as visitor:
            return ast.fix_missing_locations(visitor.visit(tree))

    def test_short_circuit_chain(self):
        for op, stop in (("and", False), ("or", True)):
            with self.subTest(op=op):
                source = f" {op} ".join(f"probe({idx})" for idx in range(4))
                tree = self.rewrite(source)
                probes = [
                    node
                    for node in ast.walk(tree)
                    if isinstance(node, ast.Name) and node.id == "probe"
                ]
                self.assertEqual(len(probes), 4)
                for stop_at in range(5):
                    calls = []

                    def probe(idx):
                        calls.append(idx)
                        return stop if idx == stop_at else not stop

                    self.assertIs(
                        self.evaluate(tree, probe=probe),
                        stop if stop_at < 4 else not stop,
                    )
                    self.assertEqual(calls, list(range(min(stop_at + 1, 4))))

    def test_walrus_binding(self):
        tree = self.rewrite("((bound := False) or (bound := True), bound)")
        self.assertEqual(self.evaluate(tree), (True, True))

    def test_comprehension_iterable(self):
        tree = self.rewrite("[item for item in ((False or True),)]")
        self.assertEqual(self.evaluate(tree), [True])

    def test_non_bool_uses_helper(self):
        helpers = Mock()
        helpers.or_.return_value = True
        tree = self.rewrite("first or second or unreachable()")
        self.assertIs(
            self.evaluate(tree, __module_dsl__=helpers, first=1, second=2), True
        )
        helpers.or_.assert_called_once_with(1, 2)

    def test_last_result_is_not_truth_tested(self):
        class NoTruth:
            def __bool__(self):
                raise AssertionError("the last result must not be truth-tested")

        marker = NoTruth()
        helpers = Mock()
        helpers.or_.return_value = marker
        self.assertIs(
            self.evaluate(self.rewrite("1 or 2"), __module_dsl__=helpers), marker
        )
        self.assertIs(
            self.evaluate(self.rewrite("True or missing()"), __module_dsl__=object()),
            True,
        )

    def test_suspended_comprehension_iterable(self):
        tree = self.rewrite(
            "def entry(left):\n    return [item for item in (left or (yield))]",
            mode="exec",
        )
        namespace = {"__module_dsl__": cutlass, "__base_dsl__": cutlass.base_dsl}
        exec(compile(tree, "<boolop>", "exec"), namespace)
        keep = namespace["entry"]([7])
        take = namespace["entry"]([])
        self.assertIsNone(next(keep))
        self.assertIsNone(next(take))
        for gen, expected in ((take, [2]), (keep, [7])):
            with self.assertRaises(StopIteration) as stopped:
                gen.send([2])
            self.assertEqual(stopped.exception.value, expected)

    @unittest.skipIf(sys.version_info < (3, 12), "PEP 695 requires Python 3.12+")
    def test_type_alias_scope(self):
        tree = self.rewrite(
            "def entry():\n    type Alias = int or float\n    return Alias.__value__",
            mode="exec",
        )
        namespace = {"__module_dsl__": cutlass, "__base_dsl__": cutlass.base_dsl}
        exec(compile(tree, "<boolop>", "exec"), namespace)
        self.assertIs(namespace["entry"](), int)
