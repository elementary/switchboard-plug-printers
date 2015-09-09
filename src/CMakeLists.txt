find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 switchboard-2.0 granite)
find_package (Cups REQUIRED)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS} ${CUPS_INCLUDE_DIR})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Plug.vala
    PrinterPage.vala
    OptionsPage.vala
    JobsView.vala
    EditableTitle.vala
    CUPSNotifier.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    switchboard-2.0
    granite
    cups
OPTIONS
    --thread
    --target-glib=2.32
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES} ${CUPS_LIBRARIES}) 

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
