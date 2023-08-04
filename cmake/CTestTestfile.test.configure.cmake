if (CUTLASS_USE_EXTENDED_ADD_TEST_FORMAT)
  # The longform/extended format allows generator expressions to be
  # expanded property and is useful in contexts where the files need
  # to be immediately included into being-processed cmake code.
  add_test(NAME @TEST_NAME@ COMMAND ${_CUTLASS_TEST_EXECUTION_ENVIRONMENT} "${TEST_EXE_PATH}" @TEST_COMMAND_OPTIONS@)
else()
  add_test(@TEST_NAME@ ${_CUTLASS_TEST_EXECUTION_ENVIRONMENT} "${TEST_EXE_PATH}" @TEST_COMMAND_OPTIONS@)
endif()

if (TEST_EXE_WORKING_DIRECTORY)
  set_tests_properties(@TEST_NAME@ PROPERTIES WORKING_DIRECTORY "${TEST_EXE_WORKING_DIRECTORY}")
endif()

set_tests_properties(@TEST_NAME@ PROPERTIES DISABLED @__DISABLE_TESTS@)

