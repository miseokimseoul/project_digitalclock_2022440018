module AlarmController(
    input  wire       clk_1k,
    input  wire       tick_1hz,
    input  wire       alarm_sw,
    input  wire       btn_confirm,
    input  wire       btn_cancel,
    input  wire       btn_stop,

    input  wire [2:0] alarm_btn_t,

    input  wire [5:0] local_hour_val,
    input  wire [5:0] cur_min_val,
    input  wire [5:0] cur_sec_val,

    output reg        alarm_enabled,
    output reg        alarm_ringing,
    output reg [1:0]  alarm_lcd_mode,

    output reg [5:0]  alarm_hour_val,
    output reg [5:0]  alarm_min_val,
    output reg [5:0]  alarm_sec_val,

    output reg [3:0]  alarm_h_tens,
    output reg [3:0]  alarm_h_ones,
    output reg [3:0]  alarm_m_tens,
    output reg [3:0]  alarm_m_ones,
    output reg [3:0]  alarm_s_tens,
    output reg [3:0]  alarm_s_ones,

    output reg [7:0]  alarm_leds
);

    reg [5:0] set_hour;
    reg [5:0] set_min;
    reg [5:0] set_sec;

    reg [5:0] mem_hour [0:7];
    reg [5:0] mem_min  [0:7];
    reg [5:0] mem_sec  [0:7];

    reg [3:0] alarm_count;
    reg [2:0] trigger_idx;

    reg [10:0] msg_timer;

    integer i;

    initial begin
        alarm_enabled   = 1'b0;
        alarm_ringing   = 1'b0;
        alarm_lcd_mode  = 2'b00;

        set_hour = 6'd0;
        set_min  = 6'd0;
        set_sec  = 6'd0;

        alarm_count  = 4'd0;
        trigger_idx  = 3'd0;
        msg_timer    = 11'd0;

        for (i = 0; i < 8; i = i + 1) begin
            mem_hour[i] = 6'd0;
            mem_min[i]  = 6'd0;
            mem_sec[i]  = 6'd0;
        end

        alarm_hour_val = 6'd0;
        alarm_min_val  = 6'd0;
        alarm_sec_val  = 6'd0;

        alarm_h_tens = 4'd0;
        alarm_h_ones = 4'd0;
        alarm_m_tens = 4'd0;
        alarm_m_ones = 4'd0;
        alarm_s_tens = 4'd0;
        alarm_s_ones = 4'd0;

        alarm_leds = 8'b0000_0000;
    end

    reg [2:0] next_alarm_idx;
    reg [16:0] min_diff;
    reg [16:0] diff;
    reg [16:0] cur_time_sec;
    reg [16:0] alarm_time_sec;

    always @(*) begin
        cur_time_sec = (local_hour_val * 3600) + (cur_min_val * 60) + cur_sec_val;

        min_diff       = 17'd86401;
        next_alarm_idx = 3'd0;

        for (i = 0; i < 8; i = i + 1) begin
            if (i < alarm_count) begin
                alarm_time_sec = (mem_hour[i] * 3600) + (mem_min[i] * 60) + mem_sec[i];

                if (alarm_time_sec >= cur_time_sec)
                    diff = alarm_time_sec - cur_time_sec;
                else
                    diff = (alarm_time_sec + 17'd86400) - cur_time_sec;

                if (diff < min_diff) begin
                    min_diff       = diff;
                    next_alarm_idx = i[2:0];
                end
            end
        end
    end

    always @(posedge clk_1k) begin
        if (msg_timer > 0)
            msg_timer <= msg_timer - 1;

        if (alarm_ringing && btn_stop) begin
            alarm_ringing <= 1'b0;

            if (alarm_count > 0) begin
                if (trigger_idx != (alarm_count - 1)) begin
                    mem_hour[trigger_idx] <= mem_hour[alarm_count - 1];
                    mem_min[trigger_idx]  <= mem_min[alarm_count - 1];
                    mem_sec[trigger_idx]  <= mem_sec[alarm_count - 1];
                end
                alarm_count <= alarm_count - 1;

                if (alarm_count == 1)
                    alarm_enabled <= 1'b0;
            end

            if (alarm_sw)
                alarm_lcd_mode <= 2'b01;
            else
                alarm_lcd_mode <= 2'b00;

            msg_timer <= 11'd0;
        end

        else if (alarm_sw) begin
            if (alarm_btn_t[0]) begin
                if (set_hour >= 23) set_hour <= 0;
                else                set_hour <= set_hour + 1;
            end
            if (alarm_btn_t[1]) begin
                if (set_min >= 59) set_min <= 0;
                else               set_min <= set_min + 1;
            end
            if (alarm_btn_t[2]) begin
                if (set_sec >= 59) set_sec <= 0;
                else               set_sec <= set_sec + 1;
            end

            if (btn_confirm) begin
                if (alarm_count < 4'd8) begin
                    mem_hour[alarm_count] <= set_hour;
                    mem_min[alarm_count]  <= set_min;
                    mem_sec[alarm_count]  <= set_sec;
                    alarm_count           <= alarm_count + 1;
                    alarm_enabled         <= 1'b1;
                end
                alarm_lcd_mode <= 2'b10;
                msg_timer      <= 11'd2000;
            end
            else if (btn_cancel) begin
                alarm_count   <= 4'd0;
                alarm_enabled <= 1'b0;
                alarm_ringing <= 1'b0;
                set_hour      <= 6'd0;
                set_min       <= 6'd0;
                set_sec       <= 6'd0;

                alarm_lcd_mode <= 2'b10;
                msg_timer      <= 11'd2000;
            end
            else begin
                if (msg_timer == 0) begin
                    if (alarm_ringing)
                        alarm_lcd_mode <= 2'b11;
                    else
                        alarm_lcd_mode <= 2'b01;
                end
            end
        end

        else begin
            if (alarm_ringing)
                alarm_lcd_mode <= 2'b11;
            else if (msg_timer == 0)
                alarm_lcd_mode <= 2'b00;
        end

        if (alarm_enabled && !alarm_ringing) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (i < alarm_count) begin
                    if ( (local_hour_val == mem_hour[i]) &&
                         (cur_min_val    == mem_min[i])  &&
                         (cur_sec_val    == mem_sec[i]) ) begin
                        alarm_ringing  <= 1'b1;
                        trigger_idx    <= i[2:0];
                        alarm_lcd_mode <= 2'b11;
                    end
                end
            end
        end
    end

    always @(*) begin
        case (alarm_count)
            4'd0: alarm_leds = 8'b0000_0000;
            4'd1: alarm_leds = 8'b0000_0001;
            4'd2: alarm_leds = 8'b0000_0011;
            4'd3: alarm_leds = 8'b0000_0111;
            4'd4: alarm_leds = 8'b0000_1111;
            4'd5: alarm_leds = 8'b0001_1111;
            4'd6: alarm_leds = 8'b0011_1111;
            4'd7: alarm_leds = 8'b0111_1111;
            4'd8: alarm_leds = 8'b1111_1111;
            default: alarm_leds = 8'b0000_0000;
        endcase
    end

    always @(*) begin
        if (alarm_sw) begin
            alarm_hour_val = set_hour;
            alarm_min_val  = set_min;
            alarm_sec_val  = set_sec;
        end
        else if (alarm_count > 0) begin
            alarm_hour_val = mem_hour[next_alarm_idx];
            alarm_min_val  = mem_min[next_alarm_idx];
            alarm_sec_val  = mem_sec[next_alarm_idx];
        end
        else begin
            alarm_hour_val = 6'd0;
            alarm_min_val  = 6'd0;
            alarm_sec_val  = 6'd0;
        end

        alarm_h_tens = alarm_hour_val / 10;
        alarm_h_ones = alarm_hour_val % 10;
        alarm_m_tens = alarm_min_val  / 10;
        alarm_m_ones = alarm_min_val  % 10;
        alarm_s_tens = alarm_sec_val  / 10;
        alarm_s_ones = alarm_sec_val  % 10;
    end

endmodule
