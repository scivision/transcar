add_library(proj OBJECT projection.f90 val_fit.f90 plegendr.f
            coef_prec.f coef_pot.f coef_cour.f
            precipitation.f90 potentiel.f90 courant.f90
            ${PROJECT_SOURCE_DIR}/dir.source/dir.cine/hardelec.f)
target_link_libraries(proj PRIVATE common)
set_target_properties(proj PROPERTIES Fortran_MODULE_DIRECTORY ${PROJECT_BINARY_DIR})