struct rs2_context;
typedef struct rs2_context rs2_context;

struct rs2_device_list;
typedef struct rs2_device_list rs2_device_list;

struct rs2_device;
typedef struct rs2_device rs2_device;

struct rs2_pipeline;
typedef struct rs2_pipeline rs2_pipeline;

struct rs2_config;
typedef struct rs2_config rs2_config;

struct rs2_frame;
typedef struct rs2_frame rs2_frame;

struct rs2_error;
typedef struct rs2_error rs2_error;

// Functions needed for setup
rs2_context* rs2_create_context(int api_version, rs2_error** error);
rs2_device_list* rs2_query_devices(const rs2_context* context, rs2_error** error);
rs2_device* rs2_create_device(const rs2_device_list* info_list, int index, rs2_error** error);
rs2_pipeline* rs2_create_pipeline(rs2_context* ctx, rs2_error ** error);
rs2_config* rs2_create_config(rs2_error** error);
void rs2_config_enable_stream(rs2_config* config,
        rs2_stream stream,
        int index,
        int width,
        int height,
        rs2_format format,
        int framerate,
        rs2_error** error);

// Functions needed to run program
rs2_frame* rs2_pipeline_wait_for_frames(rs2_pipeline* pipe, unsigned int timeout_ms, rs2_error ** error);
int rs2_embedded_frames_count(rs2_frame* composite, rs2_error** error);
rs2_frame* rs2_extract_frame(rs2_frame* composite, int index, rs2_error** error);
int rs2_is_frame_extendable_to(const rs2_frame* frame, rs2_extension extension_type, rs2_error ** error);
float rs2_depth_frame_get_distance(const rs2_frame* frame_ref, int x, int y, rs2_error** error);
void rs2_release_frame(rs2_frame* frame);
void rs2_pipeline_stop(rs2_pipeline* pipe, rs2_error ** error);