set(srcs "main.c"
        "../src/board.c"
        "../src/mesh_device_app.c"
        "../src/mesh_server.c")
set(EXTRA_COMPONENT_DIRS components)
idf_component_register(SRCS "${srcs}"
                    INCLUDE_DIRS  "." "../include")

