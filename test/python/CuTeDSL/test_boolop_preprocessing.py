import ast
import unittest

import cutlass
from cutlass.base_dsl.ast_preprocessor import DSLPreprocessor


class TestBoolOpPreprocessing(unittest.TestCase):
    def rewrite(self, source):
        tree = ast.parse(source, mode="eval")
        with DSLPreprocessor(["cutlass"]).get_session() as visitor:
            return ast.fix_missing_locations(visitor.visit(tree))

    def test_short_circuit_chain(self):
        for op, stop in (("and", False), ("or", True)):
            with self.subTest(op=op):
                source = f" {op} ".join(f"probe({idx})" for idx in range(4))
                tree = self.rewrite(source)
                code = compile(tree, "<boolop>", "eval")
                calls = []

                def probe(idx):
                    calls.append(idx)
                    return stop if idx == 2 else not stop

                namespace = {"__module_dsl__": cutlass, "probe": probe}
                self.assertIs(eval(code, namespace), stop)
                self.assertEqual(calls, [0, 1, 2])
                probes = [
                    node for node in ast.walk(tree)
                    if isinstance(node, ast.Name) and node.id == "probe"
                ]
                self.assertEqual(len(probes), 4)

    def test_walrus_binding(self):
        tree = self.rewrite("((bound := False) or True, bound)")
        self.assertEqual(eval(compile(tree, "<boolop>", "eval"), {"__module_dsl__": cutlass}), (True, False))

    def test_comprehension_iterable(self):
        tree = self.rewrite("[item for item in ((False or True),)]")
        self.assertEqual(eval(compile(tree, "<boolop>", "eval"), {"__module_dsl__": cutlass}), [True])

    def test_non_bool_uses_helper(self):
        from unittest.mock import Mock

        helpers = Mock()
        helpers.or_.return_value = True
        tree = self.rewrite("first or second or unreachable()")
        namespace = {"__module_dsl__": helpers, "first": 1, "second": 2}
        self.assertIs(eval(compile(tree, "<boolop>", "eval"), namespace), True)
        helpers.or_.assert_called_once_with(1, 2)