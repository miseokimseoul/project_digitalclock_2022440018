module LCD_WorldTime_Controller(
    input        clk,
    input        is_pm,
    input  [2:0] world_mode,
    input        mode_12,

    input        alarm_enabled,
    input  [1:0] alarm_lcd_mode,
    input  [3:0] alarm_h_tens, alarm_h_ones,
    input  [3:0] alarm_m_tens, alarm_m_ones,
    input  [3:0] alarm_s_tens, alarm_s_ones,

    input  [1:0] sw_lcd_mode,
    input        sw_update_toggle,
    input        sw_lap_valid,
    input  [3:0] sw_lap_m_tens, sw_lap_m_ones, sw_lap_s_tens, sw_lap_s_ones, sw_lap_cs_tens, sw_lap_cs_ones,
    
    input  [3:0] sw_int_m_tens, sw_int_m_ones, sw_int_s_tens, sw_int_s_ones, sw_int_cs_tens, sw_int_cs_ones,
    
    input  [3:0] sw_best_m_tens, sw_best_m_ones, sw_best_s_tens, sw_best_s_ones, sw_best_cs_tens, sw_best_cs_ones,
    input  [3:0] sw_avg_m_tens, sw_avg_m_ones, sw_avg_s_tens, sw_avg_s_ones, sw_avg_cs_tens, sw_avg_cs_ones,

    input        timer_sw,
    input  [1:0] timer_state,
    input  [3:0] tm_h_tens, tm_h_ones,
    input  [3:0] tm_m_tens, tm_m_ones,
    input  [3:0] tm_s_tens, tm_s_ones,
    input  [3:0] timer_sand_count,
    
    output reg       lcd_rs,
    output reg       lcd_rw,
    output reg       lcd_e,
    output reg [7:0] lcd_data
);

    reg [7:0] city_rom [0:7];
    reg [3:0] city_len;
    integer j;

    always @(*) begin
        for (j=0; j<8; j=j+1) city_rom[j] = " ";
        case (world_mode)
            3'd0: begin city_rom[0]="S"; city_rom[1]="E"; city_rom[2]="O"; city_rom[3]="U"; city_rom[4]="L"; city_len=5; end
            3'd1: begin city_rom[0]="N"; city_rom[1]="Y"; city_rom[2]="C"; city_len=3; end
            3'd2: begin city_rom[0]="L"; city_rom[1]="O"; city_rom[2]="N"; city_rom[3]="D"; city_rom[4]="O"; city_rom[5]="N"; city_len=6; end
            3'd3: begin city_rom[0]="P"; city_rom[1]="A"; city_rom[2]="R"; city_rom[3]="I"; city_rom[4]="S"; city_len=5; end
            3'd4: begin city_rom[0]="R"; city_rom[1]="O"; city_rom[2]="M"; city_rom[3]="E"; city_len=4; end
            3'd5: begin city_rom[0]="T"; city_rom[1]="O"; city_rom[2]="K"; city_rom[3]="Y"; city_rom[4]="O"; city_len=5; end
            default: begin city_rom[0]="?"; city_len=1; end
        endcase
    end

    reg [7:0] row1_buf [0:15];
    reg [7:0] row2_buf [0:15];
    integer i, start;
    integer k; 

    reg        mode_banner;
    reg [11:0] mode_cnt;

    reg [2:0] prev_mode;
    reg       prev_pm;
    reg       prev_mode12;
    reg       prev_banner;
    reg       prev_alarm_enabled;
    reg [1:0] prev_alarm_lcd_mode;
    reg [3:0] prev_alarm_h_ones;
    reg [3:0] prev_alarm_m_ones;
    reg [3:0] prev_alarm_s_ones;
    reg [1:0] prev_sw_lcd_mode;
    reg       prev_sw_update_toggle;
    reg       prev_timer_sw;
    reg [1:0] prev_timer_state;
    reg [3:0] prev_tm_h_ones;
    reg [3:0] prev_tm_m_ones;
    reg [3:0] prev_tm_m_tens;
    reg [3:0] prev_tm_s_ones; 
    reg [3:0] prev_sand_count;

    always @(*) begin
        for (k=0; k<16; k=k+1) begin 
            row1_buf[k] = " "; 
            row2_buf[k] = " "; 
        end

        if (timer_state == 2'd2) begin
            row1_buf[3]="T"; row1_buf[4]="I"; row1_buf[5]="M"; row1_buf[6]="E"; row1_buf[7]="R";
            row1_buf[9]="E"; row1_buf[10]="N"; row1_buf[11]="D"; row1_buf[12]="!";
            row2_buf[4]="0"+tm_h_tens; row2_buf[5]="0"+tm_h_ones; row2_buf[6]=":";
            row2_buf[7]="0"+tm_m_tens; row2_buf[8]="0"+tm_m_ones; row2_buf[9]=":";
            row2_buf[10]="0"+tm_s_tens; row2_buf[11]="0"+tm_s_ones;
        end
        else if (timer_state == 2'd3) begin
            row1_buf[3]="T"; row1_buf[4]="I"; row1_buf[5]="M"; row1_buf[6]="E"; row1_buf[7]="R";
            row1_buf[9]="S"; row1_buf[10]="E"; row1_buf[11]="T"; row1_buf[12]="!";
            row2_buf[4]="0"+tm_h_tens; row2_buf[5]="0"+tm_h_ones; row2_buf[6]=":";
            row2_buf[7]="0"+tm_m_tens; row2_buf[8]="0"+tm_m_ones; row2_buf[9]=":";
            row2_buf[10]="0"+tm_s_tens; row2_buf[11]="0"+tm_s_ones;
        end
        else if (timer_sw) begin
            row1_buf[3]="T"; row1_buf[4]="I"; row1_buf[5]="M"; row1_buf[6]="E"; row1_buf[7]="R";
            row1_buf[9]="M"; row1_buf[10]="O"; row1_buf[11]="D"; row1_buf[12]="E";
            row2_buf[4]="0"+tm_h_tens; row2_buf[5]="0"+tm_h_ones; row2_buf[6]=":";
            row2_buf[7]="0"+tm_m_tens; row2_buf[8]="0"+tm_m_ones; row2_buf[9]=":";
            row2_buf[10]="0"+tm_s_tens; row2_buf[11]="0"+tm_s_ones;
        end
        else if (alarm_lcd_mode != 2'b00) begin
            row1_buf[5]="*"; row1_buf[6]="A"; row1_buf[7]="L"; row1_buf[8]="A"; row1_buf[9]="R"; row1_buf[10]="M";
            case (alarm_lcd_mode)
                2'b01: begin row2_buf[6]="M"; row2_buf[7]="O"; row2_buf[8]="D"; row2_buf[9]="E"; end
                2'b10: begin if (alarm_enabled) begin row2_buf[6]="S"; row2_buf[7]="E"; row2_buf[8]="T"; row2_buf[9]="!"; end
                             else begin row2_buf[5]="C"; row2_buf[6]="A"; row2_buf[7]="N"; row2_buf[8]="C"; row2_buf[9]="E"; row2_buf[10]="L"; end end
                2'b11: begin row2_buf[6]="E"; row2_buf[7]="N"; row2_buf[8]="D"; row2_buf[9]="!"; end
            endcase
        end
        else if (sw_lcd_mode != 2'b00) begin
            case (sw_lcd_mode)
                2'b01: begin
                    row1_buf[3]="S"; row1_buf[4]="T"; row1_buf[5]="O"; row1_buf[6]="P"; row1_buf[7]="W"; row1_buf[8]="A"; row1_buf[9]="T"; row1_buf[10]="C"; row1_buf[11]="H";
                    row2_buf[6]="M"; row2_buf[7]="O"; row2_buf[8]="D"; row2_buf[9]="E";
                end
                2'b10: begin
                    row1_buf[0]="L"; row1_buf[1]="A"; row1_buf[2]="P"; row1_buf[3]=":";
                    if (sw_lap_valid) begin
                        row1_buf[5]="0"+sw_lap_m_tens; row1_buf[6]="0"+sw_lap_m_ones; row1_buf[7]=".";
                        row1_buf[8]="0"+sw_lap_s_tens; row1_buf[9]="0"+sw_lap_s_ones; row1_buf[10]=".";
                        row1_buf[11]="0"+sw_lap_cs_tens; row1_buf[12]="0"+sw_lap_cs_ones;
                    end
                    row2_buf[0]="I"; row2_buf[1]="N"; row2_buf[2]="T"; row2_buf[3]=":";
                    if (sw_lap_valid) begin
                        row2_buf[5]="0"+sw_int_m_tens; row2_buf[6]="0"+sw_int_m_ones; row2_buf[7]=".";
                        row2_buf[8]="0"+sw_int_s_tens; row2_buf[9]="0"+sw_int_s_ones; row2_buf[10]=".";
                        row2_buf[11]="0"+sw_int_cs_tens; row2_buf[12]="0"+sw_int_cs_ones;
                    end
                end
                2'b11: begin
                    row1_buf[0]="B"; row1_buf[1]="E"; row1_buf[2]="S"; row1_buf[3]="T"; row1_buf[4]=":";
                    if (sw_lap_valid) begin
                        row1_buf[6]="0"+sw_best_m_tens; row1_buf[7]="0"+sw_best_m_ones; row1_buf[8]=".";
                        row1_buf[9]="0"+sw_best_s_tens; row1_buf[10]="0"+sw_best_s_ones; row1_buf[11]=".";
                        row1_buf[12]="0"+sw_best_cs_tens; row1_buf[13]="0"+sw_best_cs_ones;
                    end
                    row2_buf[0]="A"; row2_buf[1]="V"; row2_buf[2]="G"; row2_buf[3]=":";
                    if (sw_lap_valid) begin
                        row2_buf[5]="0"+sw_avg_m_tens; row2_buf[6]="0"+sw_avg_m_ones; row2_buf[7]=".";
                        row2_buf[8]="0"+sw_avg_s_tens; row2_buf[9]="0"+sw_avg_s_ones; row2_buf[10]=".";
                        row2_buf[11]="0"+sw_avg_cs_tens; row2_buf[12]="0"+sw_avg_cs_ones;
                    end
                end
            endcase
        end
        else begin
            if (mode_12) begin row1_buf[0]="1"; row1_buf[1]="2"; end else begin row1_buf[0]="2"; row1_buf[1]="4"; end

            if (alarm_enabled) begin
                row1_buf[8]="0"+alarm_h_tens; row1_buf[9]="0"+alarm_h_ones; row1_buf[10]=":";
                row1_buf[11]="0"+alarm_m_tens; row1_buf[12]="0"+alarm_m_ones; row1_buf[13]=":";
                row1_buf[14]="0"+alarm_s_tens; row1_buf[15]="0"+alarm_s_ones;
            end 
            else if (timer_state == 2'd1) begin 
                for (k = 0; k < 9; k = k + 1) begin
                    if (k < timer_sand_count) row1_buf[7 + k] = 8'h00;
                    else row1_buf[7 + k] = " ";
                end
            end 
            else if (mode_banner) begin
                row1_buf[3]="H"; row1_buf[4]="O"; row1_buf[5]="U"; row1_buf[6]="R";
                row1_buf[8]="M"; row1_buf[9]="O"; row1_buf[10]="D"; row1_buf[11]="E";
            end

            if (mode_12) begin row2_buf[0] = (is_pm ? "P" : "A"); row2_buf[1] = "M"; end
            for (k=0; k<city_len; k=k+1) row2_buf[16 - city_len + k] = city_rom[k];
        end
    end

    localparam S_POWERON_DELAY = 4'd0,
               S_FUNC_SET      = 4'd1,
               S_DISP_ON       = 4'd2,
               S_CLEAR         = 4'd3,
               S_ENTRY_MODE    = 4'd4,
               S_CGRAM_ADDR    = 4'd5,
               S_CGRAM_WRITE   = 4'd6,
               S_IDLE          = 4'd7,
               S_SETADDR_ROW1  = 4'd8,
               S_WRITE_ROW1    = 4'd9,
               S_SETADDR_ROW2  = 4'd10,
               S_WRITE_ROW2    = 4'd11;

    reg [3:0] state = S_POWERON_DELAY;
    reg [15:0] delay_cnt;
    reg [4:0]  idx;
    
    reg [7:0] bell_pattern [0:7];
    initial begin
        bell_pattern[0] = 5'b00100;
        bell_pattern[1] = 5'b01110;
        bell_pattern[2] = 5'b01110;
        bell_pattern[3] = 5'b01110;
        bell_pattern[4] = 5'b01110;
        bell_pattern[5] = 5'b11111;
        bell_pattern[6] = 5'b00100;
        bell_pattern[7] = 5'b00000;
    end

    initial begin
        lcd_rs = 0; lcd_rw = 0; lcd_e = 0; lcd_data = 0;
        delay_cnt = 0; idx = 0;
        mode_banner = 0; mode_cnt = 0;
        
        prev_mode = 3'd7; prev_pm = 1; prev_mode12 = 1; prev_banner = 1;
        prev_alarm_enabled = 1; prev_alarm_lcd_mode = 3;
        prev_alarm_h_ones = 15; prev_alarm_m_ones = 15; prev_alarm_s_ones = 15;
        prev_sw_lcd_mode = 3; prev_sw_update_toggle = 1;
        prev_timer_sw = 1; prev_timer_state = 3;
        prev_tm_h_ones = 15; prev_tm_m_ones = 15; prev_tm_m_tens = 15; 
        prev_tm_s_ones = 15;
        prev_sand_count = 15;
    end

    always @(posedge clk) begin
        case (state)
            S_POWERON_DELAY: begin
                if (delay_cnt >= 16'd500) begin delay_cnt <= 0; state <= S_FUNC_SET; end
                else delay_cnt <= delay_cnt + 1;
                lcd_e <= 0;
            end
            S_FUNC_SET: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h38; lcd_e<=1;
                if (delay_cnt == 5) begin lcd_e<=0; delay_cnt<=0; state<=S_DISP_ON; end
                else delay_cnt<=delay_cnt+1;
            end
            S_DISP_ON: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h0C; lcd_e<=1;
                if (delay_cnt == 5) begin lcd_e<=0; delay_cnt<=0; state<=S_CLEAR; end
                else delay_cnt<=delay_cnt+1;
            end
            S_CLEAR: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h01; lcd_e<=1;
                if (delay_cnt == 20) begin lcd_e<=0; delay_cnt<=0; state<=S_ENTRY_MODE; end
                else delay_cnt<=delay_cnt+1;
            end
            S_ENTRY_MODE: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h06; lcd_e<=1;
                if (delay_cnt == 5) begin lcd_e<=0; delay_cnt<=0; state<=S_CGRAM_ADDR; end 
                else delay_cnt<=delay_cnt+1;
            end
            S_CGRAM_ADDR: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h40; lcd_e<=1;
                if (delay_cnt == 5) begin 
                    lcd_e<=0; delay_cnt<=0; idx<=0; state<=S_CGRAM_WRITE; 
                end else delay_cnt<=delay_cnt+1;
            end
            S_CGRAM_WRITE: begin
                lcd_rs<=1; lcd_rw<=0; lcd_data<=bell_pattern[idx]; lcd_e<=1;
                if (delay_cnt == 5) begin
                    lcd_e<=0; delay_cnt<=0; idx<=idx+1;
                    if (idx == 7) state <= S_SETADDR_ROW1; 
                end else delay_cnt<=delay_cnt+1;
            end
            S_IDLE: begin
                lcd_e <= 0;
                if (mode_banner) begin
                    if (mode_cnt >= 12'd3000) mode_banner <= 0; else mode_cnt <= mode_cnt + 1;
                end
                if (prev_mode12 != mode_12) begin mode_banner <= 1; mode_cnt <= 0; end

                if ( (prev_mode != world_mode) || (prev_pm != is_pm) || (prev_mode12 != mode_12) ||
                     (prev_banner != mode_banner) || (prev_alarm_enabled != alarm_enabled) ||
                     (prev_alarm_lcd_mode != alarm_lcd_mode) || (prev_alarm_h_ones != alarm_h_ones) ||
                     (prev_alarm_m_ones != alarm_m_ones) || (prev_alarm_s_ones != alarm_s_ones) ||
                     (prev_sw_lcd_mode != sw_lcd_mode) || (prev_sw_update_toggle != sw_update_toggle) ||
                     (prev_timer_sw != timer_sw) || (prev_timer_state != timer_state) ||
                     (prev_tm_h_ones != tm_h_ones) || (prev_tm_m_tens != tm_m_tens) || (prev_tm_m_ones != tm_m_ones) ||
                     (prev_tm_s_ones != tm_s_ones) || (prev_sand_count != timer_sand_count) ) begin
                    state <= S_SETADDR_ROW1;
                end
            end
            S_SETADDR_ROW1: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'h80; lcd_e<=1;
                if (delay_cnt == 3) begin lcd_e<=0; delay_cnt<=0; idx<=0; state<=S_WRITE_ROW1; end
                else delay_cnt<=delay_cnt+1;
            end
            S_WRITE_ROW1: begin
                lcd_rs<=1; lcd_rw<=0; lcd_data<=row1_buf[idx]; lcd_e<=1;
                if (delay_cnt == 3) begin
                    lcd_e<=0; delay_cnt<=0; idx<=idx+1;
                    if (idx == 16) state <= S_SETADDR_ROW2;
                end else delay_cnt<=delay_cnt+1;
            end
            S_SETADDR_ROW2: begin
                lcd_rs<=0; lcd_rw<=0; lcd_data<=8'hC0; lcd_e<=1;
                if (delay_cnt == 3) begin lcd_e<=0; delay_cnt<=0; idx<=0; state<=S_WRITE_ROW2; end
                else delay_cnt<=delay_cnt+1;
            end
            S_WRITE_ROW2: begin
                lcd_rs<=1; lcd_rw<=0; lcd_data<=row2_buf[idx]; lcd_e<=1;
                if (delay_cnt == 3) begin
                    lcd_e<=0; delay_cnt<=0; idx<=idx+1;
                    if (idx == 16) begin
                        prev_mode <= world_mode; prev_pm <= is_pm; prev_mode12 <= mode_12;
                        prev_banner <= mode_banner; prev_alarm_enabled <= alarm_enabled;
                        prev_alarm_lcd_mode <= alarm_lcd_mode; prev_alarm_h_ones <= alarm_h_ones;
                        prev_alarm_m_ones <= alarm_m_ones; prev_alarm_s_ones <= alarm_s_ones;
                        prev_sw_lcd_mode <= sw_lcd_mode; prev_sw_update_toggle <= sw_update_toggle;
                        prev_timer_sw <= timer_sw; prev_timer_state <= timer_state;
                        
                        prev_tm_h_ones <= tm_h_ones; prev_tm_m_tens <= tm_m_tens; prev_tm_m_ones <= tm_m_ones;
                        prev_tm_s_ones <= tm_s_ones; prev_sand_count <= timer_sand_count;
                        
                        state <= S_IDLE;
                    end
                end else delay_cnt<=delay_cnt+1;
            end
            default: state <= S_POWERON_DELAY;
        endcase
    end
endmodule
