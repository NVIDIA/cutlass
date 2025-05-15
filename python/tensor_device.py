from ast_canopy.api import parse_declarations_from_source

# Today: ast_canopy extracts template info as python objects.
decls = parse_declarations_from_source(
    "/home/wangm/cutlass/include/cute/tensor_impl.hpp",
    ["/home/wangm/cutlass/include/cute/tensor_impl.hpp"],
    "sm_80",
    additional_includes=["/home/wangm/cutlass/include/"]
)

print(decls.class_templates)
print(decls.function_templates)

# make_tensor = [ft for ft in decls.function_templates if ft.function.name == "make_tensor"]

# print(make_tensor)
# make_tensor_T_Args = make_tensor[0]

# print(make_tensor_T_Args.template_parameters)
# print(make_tensor_T_Args.function.params)

# make_tensor_float = make_tensor_T_Args.instantiate(T="float")
# print(make_tensor_float.get_instantiated_c_stmt())
