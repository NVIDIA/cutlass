import pycutlass
import unittest
from pycutlass.memory_manager import *

if __name__ == '__main__':
    pycutlass.get_memory_pool(2**32, 2**32)
    loader = unittest.TestLoader()
    tests = loader.discover('./', 'conv2d_*.py')
    testRunner = unittest.runner.TextTestRunner()
    testRunner.run(tests)
