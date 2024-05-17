set(srcs "main.c"
        "board.c"
        "../src/mesh_client.c"
        "../src/mesh_device_app.c"
        "../src/mqtt.c"
        "../src/wifi.c")

idf_component_register(SRCS "${srcs}"
                    INCLUDE_DIRS  "." "../include")
