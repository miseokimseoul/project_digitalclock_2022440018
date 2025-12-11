module StopwatchController(
    input        clk_1k,
    input        stopwatch_sw,

    input        btn_start,
    input        btn_lap,
    input        btn_clear,
    input        btn_view,

    output reg [3:0] cur_m_tens, cur_m_ones,
    output reg [3:0] cur_s_tens, cur_s_ones,
    output reg [3:0] cur_cs_tens, cur_cs_ones,

    output reg [3:0] lap_m_tens, lap_m_ones,
    output reg [3:0] lap_s_tens, lap_s_ones,
    output reg [3:0] lap_cs_tens, lap_cs_ones,

    output reg [3:0] int_m_tens, int_m_ones,
    output reg [3:0] int_s_tens, int_s_ones,
    output reg [3:0] int_cs_tens, int_cs_ones,

    output reg [3:0] best_m_tens, best_m_ones,
    output reg [3:0] best_s_tens, best_s_ones,
    output reg [3:0] best_cs_tens, best_cs_ones,

    output reg [3:0] avg_m_tens, avg_m_ones,
    output reg [3:0] avg_s_tens, avg_s_ones,
    output reg [3:0] avg_cs_tens, avg_cs_ones,

    output reg        lap_valid,
    output reg [1:0]  sw_lcd_mode,
    output reg        sw_update_toggle
);

    reg stopwatch_sw_d;
    wire sw_rise =  stopwatch_sw & ~stopwatch_sw_d;

    reg running;

    reg [3:0] cs_ones, cs_tens;
    reg [3:0] s_ones, s_tens;
    reg [3:0] m_ones, m_tens;
    reg [3:0] sub_10ms;

    reg [31:0] sw_ticks;
    reg [31:0] prev_lap_ticks;
    reg [31:0] interval_ticks;

    reg [31:0] lap_count;
    reg [31:0] sum_lap_ticks;
    reg [31:0] best_lap_ticks;

    reg [11:0] banner_cnt;

    initial begin
        stopwatch_sw_d = 0; running = 0;
        sw_ticks = 0; prev_lap_ticks = 0;
        lap_count = 0; sum_lap_ticks = 0;
        best_lap_ticks = 32'hFFFF_FFFF;
        lap_valid = 0; sw_lcd_mode = 0; sw_update_toggle = 0;
    end

    task calc_bcd;
        input [31:0] ticks;
        output [3:0] mt, mo, st, so, cst, cso;
        integer m, s, c, t;
        begin
            m = ticks / 6000; if (m > 99) m = 99;
            t = ticks % 6000;
            s = t / 100;
            c = t % 100;
            mt = m / 10; mo = m % 10;
            st = s / 10; so = s % 10;
            cst = c / 10; cso = c % 10;
        end
    endtask

    always @(posedge clk_1k) begin
        stopwatch_sw_d <= stopwatch_sw;

        if (sw_rise || (stopwatch_sw && btn_clear)) begin
            running <= 0;
            cs_ones <= 0; cs_tens <= 0; s_ones <= 0; s_tens <= 0; m_ones <= 0; m_tens <= 0; sub_10ms <= 0;
            
            sw_ticks <= 0;
            prev_lap_ticks <= 0;
            
            lap_count <= 0;
            sum_lap_ticks <= 0;
            best_lap_ticks <= 32'hFFFF_FFFF;
            lap_valid <= 0;

            cur_m_tens<=0; cur_m_ones<=0; cur_s_tens<=0; cur_s_ones<=0; cur_cs_tens<=0; cur_cs_ones<=0;
            lap_m_tens<=0; lap_m_ones<=0; lap_s_tens<=0; lap_s_ones<=0; lap_cs_tens<=0; lap_cs_ones<=0;
            int_m_tens<=0; int_m_ones<=0; int_s_tens<=0; int_s_ones<=0; int_cs_tens<=0; int_cs_ones<=0;
            best_m_tens<=0; best_m_ones<=0; best_s_tens<=0; best_s_ones<=0; best_cs_tens<=0; best_cs_ones<=0;
            avg_m_tens<=0; avg_m_ones<=0; avg_s_tens<=0; avg_s_ones<=0; avg_cs_tens<=0; avg_cs_ones<=0;

            if (sw_rise) begin
                sw_lcd_mode <= 2'b01;
                banner_cnt <= 0;
            end
            sw_update_toggle <= ~sw_update_toggle;
        end
        else if (!stopwatch_sw) begin
            running <= 0;
            sw_lcd_mode <= 2'b00;
        end
        else begin
            if (sw_lcd_mode == 2'b01) begin
                if (banner_cnt >= 3000) begin
                    sw_lcd_mode <= 2'b10;
                    sw_update_toggle <= ~sw_update_toggle;
                end else banner_cnt <= banner_cnt + 1;
            end

            if ((sw_lcd_mode != 2'b01) && btn_start) running <= ~running;

            if ((sw_lcd_mode != 2'b01) && btn_view) begin
                if (sw_lcd_mode == 2'b10) sw_lcd_mode <= 2'b11;
                else if (sw_lcd_mode == 2'b11) sw_lcd_mode <= 2'b10;
                sw_update_toggle <= ~sw_update_toggle;
            end

            if (running) begin
                if (sub_10ms == 9) begin
                    sub_10ms <= 0;
                    sw_ticks <= sw_ticks + 1;

                    if (cs_ones==9) begin cs_ones<=0;
                        if (cs_tens==9) begin cs_tens<=0;
                            if (s_ones==9) begin s_ones<=0;
                                if (s_tens==5) begin s_tens<=0;
                                    if (m_ones==9) begin m_ones<=0;
                                        if (m_tens==5) m_tens<=0; else m_tens<=m_tens+1;
                                    end else m_ones<=m_ones+1;
                                end else s_tens<=s_tens+1;
                            end else s_ones<=s_ones+1;
                        end else cs_tens<=cs_tens+1;
                    end else cs_ones<=cs_ones+1;
                end else sub_10ms <= sub_10ms + 1;
            end

            cur_m_tens <= m_tens; cur_m_ones <= m_ones;
            cur_s_tens <= s_tens; cur_s_ones <= s_ones;
            cur_cs_tens <= cs_tens; cur_cs_ones <= cs_ones;

            if ((sw_lcd_mode != 2'b01) && btn_lap) begin
                lap_m_tens <= m_tens; lap_m_ones <= m_ones;
                lap_s_tens <= s_tens; lap_s_ones <= s_ones;
                lap_cs_tens <= cs_tens; lap_cs_ones <= cs_ones;

                interval_ticks = sw_ticks - prev_lap_ticks;
                prev_lap_ticks <= sw_ticks;

                calc_bcd(interval_ticks, 
                         int_m_tens, int_m_ones, int_s_tens, int_s_ones, int_cs_tens, int_cs_ones);

                lap_valid <= 1;
                
                if (lap_count == 0 || sw_ticks < best_lap_ticks) begin
                    best_lap_ticks <= sw_ticks;
                    calc_bcd(sw_ticks, 
                             best_m_tens, best_m_ones, best_s_tens, best_s_ones, best_cs_tens, best_cs_ones);
                end

                sum_lap_ticks <= sum_lap_ticks + sw_ticks;
                lap_count <= lap_count + 1;
                
                calc_bcd((sum_lap_ticks + sw_ticks) / (lap_count + 1),
                         avg_m_tens, avg_m_ones, avg_s_tens, avg_s_ones, avg_cs_tens, avg_cs_ones);

                sw_update_toggle <= ~sw_update_toggle;
            end
        end
    end

endmodule
