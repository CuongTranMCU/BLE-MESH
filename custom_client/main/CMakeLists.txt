set(srcs "main.c"
        "../src/board.c"
        "../src/mesh_client.c"
        "../src/mesh_device_app.c"
        "../src/wifi.c"
        "../src/mqtt.c")

idf_component_register(SRCS "${srcs}"
                    INCLUDE_DIRS  "." "../include")
