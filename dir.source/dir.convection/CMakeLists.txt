add_library(convec OBJECT convec.f convec_1.f conv_ar.f)
target_link_libraries(convec PRIVATE proj)
set_target_properties(convec PROPERTIES Fortran_MODULE_DIRECTORY ${PROJECT_BINARY_DIR})