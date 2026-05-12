localparam p_num_commands = 4;
localparam p_max_cmd_data_bytes = 64;
localparam p_max_resp_data_bytes = 64;

localparam p_size_cmd_data_bytes = $clog2(p_max_cmd_data_bytes);
localparam p_size_resp_data_bytes = $clog2(p_max_resp_data_bytes);

localparam p_cmd_settings_size = p_size_cmd_data_bytes + p_size_resp_data_bytes + 1;

localparam [p_cmd_settings_size-1:0] 
    p_cmd_ping  = {1'b1, 5'd1, 5'd1},
    p_cmd_speed = {1'b1, 5'd0, 5'd2},
    p_cmd_dir   = {1'b1, 5'd0, 5'd1},
    p_cmd_cal   = {1'b1, 5'd0, 5'd1},
    p_cmd_none  = {1'b0, 5'd0, 5'd0};

assign {w_cmd_cli, w_cmd_data_bytes, w_resp_data_bytes} = 
    r_cmd == 8'h70 ? p_cmd_ping  :
    r_cmd == 8'h73 ? p_cmd_speed :
    r_cmd == 8'h64 ? p_cmd_dir   :
    r_cmd == 8'h63 ? p_cmd_dir   :
                     p_cmd_none  ;