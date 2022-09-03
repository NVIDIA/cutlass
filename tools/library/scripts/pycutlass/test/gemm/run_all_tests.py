import pycutlass
import unittest

if __name__ == '__main__':
    pycutlass.get_memory_pool(2**26, 2**26)
    loader = unittest.TestLoader()
    tests = loader.discover('./', 'gemm_*.py')
    testRunner = unittest.runner.TextTestRunner()
    testRunner.run(tests)
