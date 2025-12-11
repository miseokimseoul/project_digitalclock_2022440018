`timescale 1ns/1ps

module tb_3_1_time_rollover;

    reg        clk_1k       = 0;
    reg        clr_sw_n     = 1;
    reg        alarm_sw     = 0;
    reg        stopwatch_sw = 0;
    reg        timer_sw     = 0;
    reg  [8:0] btn          = 9'b0;

    wire [7:0] seg_data;
    wire [7:0] seg_sel;
    wire       lcd_rs, lcd_rw, lcd_e;
    wire [7:0] lcd_data;
    wire       piezo;
    wire [7:0] led_1;
    wire [3:0] led_r, led_g, led_b;

    DigitalClock dut (
        .clk_1k      (clk_1k),
        .clr_sw_n    (clr_sw_n),
        .alarm_sw    (alarm_sw),
        .stopwatch_sw(stopwatch_sw),
        .timer_sw    (timer_sw),
        .btn         (btn),
        .seg_data    (seg_data),
        .seg_sel     (seg_sel),
        .lcd_rs      (lcd_rs),
        .lcd_rw      (lcd_rw),
        .lcd_e       (lcd_e),
        .lcd_data    (lcd_data),
        .piezo       (piezo),
        .led_1       (led_1),
        .led_r       (led_r),
        .led_g       (led_g),
        .led_b       (led_b)
    );

    always #5 clk_1k = ~clk_1k;

    task press_btn(input integer idx);
        begin
            btn[idx] = 1;   #10;
            btn[idx] = 0;   #100;
        end
    endtask

    initial begin
        alarm_sw     = 0;
        stopwatch_sw = 0;
        timer_sw     = 0;
        btn          = 9'b0;

        clr_sw_n = 1;   #50;
        clr_sw_n = 0;   #20;
        clr_sw_n = 1;   #100;

        repeat (23) press_btn(0);
        repeat (59) press_btn(1);
        repeat (58) press_btn(2);

        #1000;
        press_btn(2);

        #1000;
        press_btn(2);

        #5000;
        $finish;
    end

endmodule