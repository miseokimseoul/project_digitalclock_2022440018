module TimerController(
    input wire clk_1k,          
    input wire tick_1hz,        
    input wire timer_sw,        
    
    input wire btn_h_inc,       
    input wire btn_m_inc,       
    input wire btn_s_inc,       
    input wire btn_confirm,     
    input wire btn_start, 
    input wire btn_clear,
    
    input wire btn_add5,
    input wire btn_add10,
    input wire btn_add15,

    output reg [3:0] tm_h_tens,
    output reg [3:0] tm_h_ones,
    output reg [3:0] tm_m_tens,
    output reg [3:0] tm_m_ones,
    output reg [3:0] tm_s_tens,
    output reg [3:0] tm_s_ones,

    output reg [1:0] timer_state, 
    output wire led_1_blink,      
    output wire [2:0] rgb_pwm,    
    output wire piezo_out,
    output reg [3:0] sand_count
);

    reg [5:0] cnt_hour;
    reg [5:0] cnt_min;
    reg [5:0] cnt_sec;

    localparam S_IDLE_SET = 2'd0;
    localparam S_RUNNING  = 2'd1;
    localparam S_RINGING  = 2'd2;
    localparam S_CONFIRM  = 2'd3;

    reg [1:0] ring_cnt;
    reg [10:0] confirm_msg_cnt;

    reg [16:0] total_start_time;
    reg [16:0] current_remain;

    always @(posedge clk_1k) begin
        if (btn_clear) begin
            timer_state <= S_IDLE_SET;
            cnt_hour <= 0; cnt_min <= 0; cnt_sec <= 0;
            ring_cnt <= 0; confirm_msg_cnt <= 0; total_start_time <= 0;
        end
        else begin
            case (timer_state)
                S_IDLE_SET: begin
                    ring_cnt <= 0;
                    
                    if (timer_sw) begin
                        if (btn_h_inc) begin if (cnt_hour >= 23) cnt_hour <= 0; else cnt_hour <= cnt_hour + 1; end
                        if (btn_m_inc) begin if (cnt_min >= 59) cnt_min <= 0; else cnt_min <= cnt_min + 1; end
                        if (btn_s_inc) begin if (cnt_sec >= 59) cnt_sec <= 0; else cnt_sec <= cnt_sec + 1; end
                        
                        if (btn_add5) begin
                            if (cnt_min + 5 >= 60) begin
                                cnt_min <= (cnt_min + 5) - 60;
                                if (cnt_hour < 23) cnt_hour <= cnt_hour + 1;
                            end else begin
                                cnt_min <= cnt_min + 5;
                            end
                        end
                        if (btn_add10) begin
                            if (cnt_min + 10 >= 60) begin
                                cnt_min <= (cnt_min + 10) - 60;
                                if (cnt_hour < 23) cnt_hour <= cnt_hour + 1;
                            end else begin
                                cnt_min <= cnt_min + 10;
                            end
                        end
                        if (btn_add15) begin
                            if (cnt_min + 15 >= 60) begin
                                cnt_min <= (cnt_min + 15) - 60;
                                if (cnt_hour < 23) cnt_hour <= cnt_hour + 1;
                            end else begin
                                cnt_min <= cnt_min + 15;
                            end
                        end

                        if (btn_confirm) begin
                            timer_state <= S_CONFIRM; confirm_msg_cnt <= 0;
                        end
                        if (btn_start) begin
                            if (cnt_hour != 0 || cnt_min != 0 || cnt_sec != 0) begin
                                timer_state <= S_RUNNING;
                                total_start_time <= (cnt_hour * 3600) + (cnt_min * 60) + cnt_sec;
                            end
                        end
                    end
                end

                S_CONFIRM: begin
                    if (confirm_msg_cnt >= 2000) timer_state <= S_IDLE_SET;
                    else confirm_msg_cnt <= confirm_msg_cnt + 1;
                end

                S_RUNNING: begin
                    if (tick_1hz) begin
                        if (cnt_sec > 0) cnt_sec <= cnt_sec - 1;
                        else begin 
                            if (cnt_min > 0) begin cnt_min <= cnt_min - 1; cnt_sec <= 59; end
                            else begin 
                                if (cnt_hour > 0) begin cnt_hour <= cnt_hour - 1; cnt_min <= 59; cnt_sec <= 59; end
                                else begin timer_state <= S_RINGING; ring_cnt <= 3; end
                            end
                        end
                    end
                end

                S_RINGING: begin
                    if (tick_1hz) begin
                        if (ring_cnt > 0) ring_cnt <= ring_cnt - 1;
                        else begin timer_state <= S_IDLE_SET; cnt_hour <= 0; cnt_min <= 0; cnt_sec <= 0; end
                    end
                end
            endcase
        end
    end

    always @(*) begin
        current_remain = (cnt_hour * 3600) + (cnt_min * 60) + cnt_sec;
        if (timer_state == S_RUNNING && total_start_time > 0) begin
            sand_count = (current_remain * 9 + (total_start_time/2)) / total_start_time;
            if (sand_count > 9) sand_count = 9;
            if (sand_count == 0 && current_remain > 0) sand_count = 1;
        end else if (timer_state == S_IDLE_SET || timer_state == S_CONFIRM) begin
            sand_count = 9;
        end else begin
            sand_count = 0;
        end
    end

    always @(*) begin
        tm_h_tens = cnt_hour / 10; tm_h_ones = cnt_hour % 10;
        tm_m_tens = cnt_min / 10; tm_m_ones = cnt_min % 10;
        tm_s_tens = cnt_sec / 10; tm_s_ones = cnt_sec % 10;
    end

    reg [9:0] blink_cnt;
    always @(posedge clk_1k) begin
        if (timer_state == S_RUNNING) begin
            if (blink_cnt >= 999) blink_cnt <= 0; else blink_cnt <= blink_cnt + 1;
        end else blink_cnt <= 0;
    end
    assign led_1_blink = ((timer_state == S_RUNNING) && !timer_sw) ? (blink_cnt < 500) : 1'b0;

    reg piezo_reg;
    always @(posedge clk_1k) begin
        if (timer_state == S_RINGING) piezo_reg <= ~piezo_reg; else piezo_reg <= 0;
    end
    assign piezo_out = (timer_state == S_RINGING) ? piezo_reg : 0;

    wire [11:0] total_sec = (cnt_hour * 3600) + (cnt_min * 60) + cnt_sec;
    reg r_on, g_on, b_on;
    always @(*) begin
        r_on = 0; g_on = 0; b_on = 0;
        if (timer_state == S_RUNNING && cnt_hour == 0) begin
            if (total_sec <= 15 && total_sec > 5) g_on = 1;
            else if (total_sec <= 5 && total_sec > 3) begin r_on = 1; g_on = 1; end
            else if (total_sec <= 3) r_on = 1;
        end
        else if (timer_state == S_RINGING) r_on = 1;
    end
    assign rgb_pwm[2] = r_on; assign rgb_pwm[1] = g_on; assign rgb_pwm[0] = b_on; 

endmodule
