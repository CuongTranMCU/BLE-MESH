set(srcs "main.c"
        "board.c"
        "../src/mesh_client.c"
        "../src/mesh_device_app.c"
        "../src/mesh_server.c")

idf_component_register(SRCS "${srcs}"
                    INCLUDE_DIRS  "." "../include")

