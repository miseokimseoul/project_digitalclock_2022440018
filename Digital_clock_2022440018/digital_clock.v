module DigitalClock(
    input        clk_1k,
    input        clr_sw_n,
    input        alarm_sw,
    input        stopwatch_sw,
    input        timer_sw,
    
    input  [8:0] btn,          

    output [7:0] seg_data,
    output [7:0] seg_sel,

    output       lcd_rs,
    output       lcd_rw,
    output       lcd_e,
    output [7:0] lcd_data,

    output       piezo,
    output [7:0] led_1,        
    
    output [3:0] led_r,        
    output [3:0] led_g,        
    output [3:0] led_b         
);

    wire [8:0] btn_t;
    oneshot_universal #(.WIDTH(9)) u_btn_oneshot (
        .clk      (clk_1k),
        .rst_n    (1'b1),
        .btn      (btn),
        .btn_trig (btn_t)
    );

    wire clr_sw = ~clr_sw_n;
    wire clr_time;
    oneshot_universal #(.WIDTH(1)) u_clr_oneshot (
        .clk      (clk_1k),
        .rst_n    (1'b1),
        .btn      (clr_sw),
        .btn_trig (clr_time)
    );

    wire tick_1hz;
    clock_divider_1k_to_1hz u_div (
        .clk      (clk_1k),
        .tick_1hz (tick_1hz)
    );

    wire clock_adjust_enable = ~alarm_sw & ~stopwatch_sw & ~timer_sw;
    wire inc_hour_main = btn_t[0] & clock_adjust_enable;
    wire inc_min_main  = btn_t[1] & clock_adjust_enable;
    wire inc_sec_main  = btn_t[2] & clock_adjust_enable;

    wire [3:0] sec_ones, sec_tens;
    wire [3:0] min_ones, min_tens;
    wire [3:0] hour_ones;
    wire [1:0] hour_tens;

    time_counter_hms_bcd u_time (
        .clk       (clk_1k),
        .clr_time  (clr_time),
        .tick_1hz  (tick_1hz),
        .inc_hour  (inc_hour_main),
        .inc_min   (inc_min_main),
        .inc_sec   (inc_sec_main),
        .sec_ones  (sec_ones), .sec_tens  (sec_tens),
        .min_ones  (min_ones), .min_tens  (min_tens),
        .hour_ones (hour_ones), .hour_tens (hour_tens)
    );

    reg mode_12 = 1'b0; 
    always @(posedge clk_1k) begin
        if (btn_t[3] && clock_adjust_enable) begin
            mode_12 <= ~mode_12;
        end
    end

    reg [2:0] world_mode = 3'd0;
    always @(posedge clk_1k) begin
        if (btn_t[4] && clock_adjust_enable) begin
            if (world_mode == 3'd5) world_mode <= 3'd0;
            else world_mode <= world_mode + 3'd1;
        end
    end

    reg [5:0] local_hour_val;
    reg [5:0] cur_min_val, cur_sec_val;
    always @(*) begin
        case (hour_tens)
            2'd0: local_hour_val = {2'b00, hour_ones};
            2'd1: local_hour_val = 6'd10 + hour_ones;
            2'd2: local_hour_val = 6'd20 + hour_ones;
            default: local_hour_val = 6'd0;
        endcase
        cur_min_val = {2'b00, min_tens} * 6'd10 + {2'b00, min_ones};
        cur_sec_val = {2'b00, sec_tens} * 6'd10 + {2'b00, sec_ones};
    end

    reg [5:0] world_hour_val, disp_hour_val;
    reg [1:0] disp_hour_tens;
    reg [3:0] disp_hour_ones;
    reg [5:0] temp_hour;
    reg       is_pm;

    always @(*) begin
        case (world_mode)
            3'd0: temp_hour = local_hour_val;
            3'd1: temp_hour = local_hour_val + 6'd10; 
            3'd2: temp_hour = local_hour_val + 6'd15; 
            3'd3: temp_hour = local_hour_val + 6'd16; 
            3'd4: temp_hour = local_hour_val + 6'd16; 
            3'd5: temp_hour = local_hour_val;
            default: temp_hour = local_hour_val;
        endcase
        if (temp_hour >= 6'd24) world_hour_val = temp_hour - 6'd24;
        else world_hour_val = temp_hour;

        is_pm = (world_hour_val >= 6'd12);

        if (!mode_12) disp_hour_val = world_hour_val;
        else begin
            if (world_hour_val == 6'd0) disp_hour_val = 6'd12;
            else if (world_hour_val <= 6'd12) disp_hour_val = world_hour_val;
            else disp_hour_val = world_hour_val - 6'd12;
        end

        if (disp_hour_val >= 6'd20) begin
            disp_hour_tens = 2'd2; disp_hour_ones = disp_hour_val - 6'd20;
        end else if (disp_hour_val >= 6'd10) begin
            disp_hour_tens = 2'd1; disp_hour_ones = disp_hour_val - 6'd10;
        end else begin
            disp_hour_tens = 2'd0; disp_hour_ones = disp_hour_val[3:0];
        end
    end

    wire alarm_ringing, alarm_enabled;
    wire [1:0] alarm_lcd_mode;
    wire [3:0] alarm_h_tens, alarm_h_ones, alarm_m_tens, alarm_m_ones, alarm_s_tens, alarm_s_ones;
    wire [5:0] ah_val, am_val, as_val; 
    wire [7:0] alarm_leds; 

    AlarmController u_alarm (
        .clk_1k         (clk_1k),
        .tick_1hz       (tick_1hz),
        .alarm_sw       (alarm_sw),
        .btn_confirm    (btn_t[3]),
        .btn_cancel     (btn_t[4]),
        .btn_stop       (btn_t[5]),
        .alarm_btn_t    (btn_t[2:0]),
        .local_hour_val (local_hour_val),
        .cur_min_val    (cur_min_val),
        .cur_sec_val    (cur_sec_val),
        .alarm_enabled  (alarm_enabled),
        .alarm_ringing  (alarm_ringing),
        .alarm_lcd_mode (alarm_lcd_mode),
        .alarm_hour_val (ah_val), .alarm_min_val (am_val), .alarm_sec_val (as_val),
        .alarm_h_tens   (alarm_h_tens), .alarm_h_ones   (alarm_h_ones),
        .alarm_m_tens   (alarm_m_tens), .alarm_m_ones   (alarm_m_ones),
        .alarm_s_tens   (alarm_s_tens), .alarm_s_ones   (alarm_s_ones),
        .alarm_leds     (alarm_leds) 
    );

    wire [3:0] sw_m_t, sw_m_o, sw_s_t, sw_s_o, sw_cs_t, sw_cs_o;
    wire [3:0] sw_lap_m_tens, sw_lap_m_ones, sw_lap_s_tens, sw_lap_s_ones, sw_lap_cs_tens, sw_lap_cs_ones;
    wire [3:0] sw_best_m_tens, sw_best_m_ones, sw_best_s_tens, sw_best_s_ones, sw_best_cs_tens, sw_best_cs_ones;
    wire [3:0] sw_avg_m_tens, sw_avg_m_ones, sw_avg_s_tens, sw_avg_s_ones, sw_avg_cs_tens, sw_avg_cs_ones;
    wire [3:0] sw_int_m_tens, sw_int_m_ones, sw_int_s_tens, sw_int_s_ones, sw_int_cs_tens, sw_int_cs_ones;
    
    wire sw_lap_valid, sw_update_toggle;
    wire [1:0] sw_lcd_mode;

    StopwatchController u_stopwatch (
        .clk_1k           (clk_1k),
        .stopwatch_sw     (stopwatch_sw),
        .btn_start        (btn_t[0]),
        .btn_lap          (btn_t[1]),
        .btn_clear        (btn_t[2]),
        .btn_view         (btn_t[3]),
        
        .cur_m_tens       (sw_m_t), .cur_m_ones (sw_m_o),
        .cur_s_tens       (sw_s_t), .cur_s_ones (sw_s_o),
        .cur_cs_tens      (sw_cs_t), .cur_cs_ones (sw_cs_o),
        
        .lap_m_tens       (sw_lap_m_tens), .lap_m_ones(sw_lap_m_ones),
        .lap_s_tens       (sw_lap_s_tens), .lap_s_ones(sw_lap_s_ones),
        .lap_cs_tens      (sw_lap_cs_tens), .lap_cs_ones(sw_lap_cs_ones),
        
        .int_m_tens(sw_int_m_tens), .int_m_ones(sw_int_m_ones),
        .int_s_tens(sw_int_s_tens), .int_s_ones(sw_int_s_ones),
        .int_cs_tens(sw_int_cs_tens), .int_cs_ones(sw_int_cs_ones),

        .best_m_tens      (sw_best_m_tens), .best_m_ones(sw_best_m_ones),
        .best_s_tens      (sw_best_s_tens), .best_s_ones(sw_best_s_ones),
        .best_cs_tens     (sw_best_cs_tens), .best_cs_ones(sw_best_cs_ones),
        .avg_m_tens       (sw_avg_m_tens), .avg_m_ones(sw_avg_m_ones),
        .avg_s_tens       (sw_avg_s_tens), .avg_s_ones(sw_avg_s_ones),
        .avg_cs_tens      (sw_avg_cs_tens), .avg_cs_ones(sw_avg_cs_ones),
        .lap_valid        (sw_lap_valid),
        .sw_lcd_mode      (sw_lcd_mode),
        .sw_update_toggle (sw_update_toggle)
    );

    wire [3:0] tm_h_tens, tm_h_ones;
    wire [3:0] tm_m_tens, tm_m_ones;
    wire [3:0] tm_s_tens, tm_s_ones;
    wire [1:0] timer_state;
    wire       timer_piezo;
    wire [2:0] timer_rgb_sig; 
    wire       timer_led_blink; 
    wire [3:0] timer_sand_count; 
    
    TimerController u_timer (
        .clk_1k      (clk_1k),
        .tick_1hz    (tick_1hz),
        .timer_sw    (timer_sw),
        
        .btn_h_inc   (btn_t[0]), 
        .btn_m_inc   (btn_t[1]), 
        .btn_s_inc   (btn_t[2]), 
        .btn_confirm (btn_t[3]), 
        .btn_start   (btn_t[4]), 
        .btn_clear   (btn_t[5]), 
        .btn_add5    (btn_t[6]), 
        .btn_add10   (btn_t[7]), 
        .btn_add15   (btn_t[8]), 
        
        .tm_h_tens   (tm_h_tens), .tm_h_ones(tm_h_ones),
        .tm_m_tens   (tm_m_tens), .tm_m_ones(tm_m_ones),
        .tm_s_tens   (tm_s_tens), .tm_s_ones(tm_s_ones),
        
        .timer_state (timer_state),
        .led_1_blink (timer_led_blink), 
        .rgb_pwm     (timer_rgb_sig),
        .piezo_out   (timer_piezo),
        .sand_count  (timer_sand_count) 
    );

    assign led_r = {4{timer_rgb_sig[2]}};
    assign led_g = {4{timer_rgb_sig[1]}};
    assign led_b = {4{timer_rgb_sig[0]}};

    wire timer_run_bg = (timer_state == 2'd1) && (!timer_sw);
    assign led_1[0]   = timer_run_bg ? timer_led_blink : alarm_leds[0];
    assign led_1[7:1] = alarm_leds[7:1];

    wire disp_timer = timer_sw;
    wire disp_sw    = stopwatch_sw && !disp_timer;
    wire disp_alarm = alarm_sw && !disp_sw && !disp_timer;

    wire [3:0] seg_d0, seg_d1, seg_d2, seg_d3, seg_d4, seg_d5;

    assign seg_d0 = disp_timer ? tm_s_ones :
                    disp_sw    ? sw_cs_o :
                    disp_alarm ? alarm_s_ones : sec_ones;

    assign seg_d1 = disp_timer ? tm_s_tens :
                    disp_sw    ? sw_cs_t :
                    disp_alarm ? alarm_s_tens : sec_tens;

    assign seg_d2 = disp_timer ? tm_m_ones :
                    disp_sw    ? sw_s_o :
                    disp_alarm ? alarm_m_ones : min_ones;

    assign seg_d3 = disp_timer ? tm_m_tens :
                    disp_sw    ? sw_s_t :
                    disp_alarm ? alarm_m_tens : min_tens;

    assign seg_d4 = disp_timer ? tm_h_ones :
                    disp_sw    ? sw_m_o :
                    disp_alarm ? alarm_h_ones : disp_hour_ones;

    assign seg_d5 = disp_timer ? tm_h_tens :
                    disp_sw    ? sw_m_t :
                    disp_alarm ? {2'b00, alarm_h_tens[1:0]} : {2'b00, disp_hour_tens};

    seven_seg_driver_6digit u_7seg (
        .clk      (clk_1k),
        .d0(seg_d0), .d1(seg_d1), .d2(seg_d2),
        .d3(seg_d3), .d4(seg_d4), .d5(seg_d5),
        .seg_data (seg_data),
        .seg_sel  (seg_sel)
    );

    LCD_WorldTime_Controller u_lcd (
        .clk             (clk_1k),
        .is_pm           (is_pm),
        .world_mode      (world_mode),
        .mode_12         (mode_12),
        
        .alarm_enabled   (alarm_enabled),
        .alarm_lcd_mode  (alarm_lcd_mode),
        .alarm_h_tens(alarm_h_tens), .alarm_h_ones(alarm_h_ones),
        .alarm_m_tens(alarm_m_tens), .alarm_m_ones(alarm_m_ones),
        .alarm_s_tens(alarm_s_tens), .alarm_s_ones(alarm_s_ones),

        .sw_lcd_mode       (sw_lcd_mode),
        .sw_update_toggle  (sw_update_toggle),
        .sw_lap_valid      (sw_lap_valid),
        .sw_lap_m_tens(sw_lap_m_tens), .sw_lap_m_ones(sw_lap_m_ones),
        .sw_lap_s_tens(sw_lap_s_tens), .sw_lap_s_ones(sw_lap_s_ones),
        .sw_lap_cs_tens(sw_lap_cs_tens), .sw_lap_cs_ones(sw_lap_cs_ones),

        .sw_int_m_tens(sw_int_m_tens), .sw_int_m_ones(sw_int_m_ones),
        .sw_int_s_tens(sw_int_s_tens), .sw_int_s_ones(sw_int_s_ones),
        .sw_int_cs_tens(sw_int_cs_tens), .sw_int_cs_ones(sw_int_cs_ones),

        .sw_best_m_tens(sw_best_m_tens), .sw_best_m_ones(sw_best_m_ones),
        .sw_best_s_tens(sw_best_s_tens), .sw_best_s_ones(sw_best_s_ones),
        .sw_best_cs_tens(sw_best_cs_tens), .sw_best_cs_ones(sw_best_cs_ones),
        .sw_avg_m_tens(sw_avg_m_tens), .sw_avg_m_ones(sw_avg_m_ones),
        .sw_avg_s_tens(sw_avg_s_tens), .sw_avg_s_ones(sw_avg_s_ones),
        .sw_avg_cs_tens(sw_avg_cs_tens), .sw_avg_cs_ones(sw_avg_cs_ones),

        .timer_sw        (timer_sw),
        .timer_state     (timer_state),
        .tm_h_tens(tm_h_tens), .tm_h_ones(tm_h_ones),
        .tm_m_tens(tm_m_tens), .tm_m_ones(tm_m_ones),
        .tm_s_tens(tm_s_tens), .tm_s_ones(tm_s_ones),
        .timer_sand_count(timer_sand_count), 

        .lcd_rs          (lcd_rs),
        .lcd_rw          (lcd_rw),
        .lcd_e           (lcd_e),
        .lcd_data        (lcd_data)
    );

    localparam MELODY_LEN = 5'd25;
    localparam HALF_SEC_CNT = 10'd500;
    localparam NOTE_REST = 2'd0;
    localparam NOTE_DO   = 2'd1;
    localparam NOTE_RE   = 2'd2;
    localparam NOTE_MI   = 2'd3;

    reg [1:0] cur_note;
    reg [4:0] note_idx;
    reg       play_phase;
    reg [9:0] half_cnt;
    reg [9:0] tone_cnt_melody;
    reg       piezo_melody;

    wire [9:0] tone_limit = (cur_note == NOTE_MI) ? 10'd1 :
                            (cur_note == NOTE_RE) ? 10'd2 :
                            (cur_note == NOTE_DO) ? 10'd3 : 10'd0;

    always @(posedge clk_1k) begin
        if (!alarm_ringing) begin
            note_idx <= 0; play_phase <= 1; half_cnt <= 0; tone_cnt_melody <= 0;
            cur_note <= 0; piezo_melody <= 0;
        end else begin
            if (half_cnt >= HALF_SEC_CNT-1) begin
                half_cnt <= 0; play_phase <= ~play_phase;
                if (!play_phase) begin
                    if (note_idx == MELODY_LEN-1) note_idx <= 0;
                    else note_idx <= note_idx + 1;
                end
            end else half_cnt <= half_cnt + 1;

            if (play_phase) begin
                case (note_idx) 
                    5'd0,5'd4,5'd5,5'd6,5'd10,5'd11,5'd12,5'd13,5'd17,5'd18,5'd19,5'd22: cur_note <= NOTE_MI;
                    5'd1,5'd3,5'd7,5'd8,5'd9,5'd14,5'd16,5'd20,5'd21,5'd23: cur_note <= NOTE_RE;
                    5'd2,5'd15,5'd24: cur_note <= NOTE_DO;
                    default: cur_note <= NOTE_REST;
                endcase
            end else cur_note <= NOTE_REST;

            if (tone_limit == 0) begin
                piezo_melody <= 0; tone_cnt_melody <= 0;
            end else begin
                if (tone_cnt_melody >= tone_limit) begin
                    tone_cnt_melody <= 0; piezo_melody <= ~piezo_melody;
                end else tone_cnt_melody <= tone_cnt_melody + 1;
            end
        end
    end

    assign piezo = piezo_melody | timer_piezo;

endmodule
