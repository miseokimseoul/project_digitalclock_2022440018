`timescale 1us/1us

module tb_TimerController;

    reg clk_1k;
    reg tick_1hz;
    reg timer_sw;

    reg btn_h_inc;
    reg btn_m_inc;
    reg btn_s_inc;
    reg btn_confirm;
    reg btn_start;
    reg btn_clear;
    reg btn_add5;
    reg btn_add10;
    reg btn_add15;

    wire [3:0] tm_h_tens;
    wire [3:0] tm_h_ones;
    wire [3:0] tm_m_tens;
    wire [3:0] tm_m_ones;
    wire [3:0] tm_s_tens;
    wire [3:0] tm_s_ones;

    wire [1:0] timer_state;
    wire       led_1_blink;
    wire [2:0] rgb_pwm;
    wire       piezo_out;
    wire [3:0] sand_count;

    TimerController dut (
        .clk_1k      (clk_1k),
        .tick_1hz    (tick_1hz),
        .timer_sw    (timer_sw),
        .btn_h_inc   (btn_h_inc),
        .btn_m_inc   (btn_m_inc),
        .btn_s_inc   (btn_s_inc),
        .btn_confirm (btn_confirm),
        .btn_start   (btn_start),
        .btn_clear   (btn_clear),
        .btn_add5    (btn_add5),
        .btn_add10   (btn_add10),
        .btn_add15   (btn_add15),
        .tm_h_tens   (tm_h_tens),
        .tm_h_ones   (tm_h_ones),
        .tm_m_tens   (tm_m_tens),
        .tm_m_ones   (tm_m_ones),
        .tm_s_tens   (tm_s_tens),
        .tm_s_ones   (tm_s_ones),
        .timer_state (timer_state),
        .led_1_blink (led_1_blink),
        .rgb_pwm     (rgb_pwm),
        .piezo_out   (piezo_out),
        .sand_count  (sand_count)
    );

    initial clk_1k = 0;
    always #500 clk_1k = ~clk_1k;

    task tick_once;
    begin
        tick_1hz = 1'b1;
        @(posedge clk_1k);
        tick_1hz = 1'b0;
        @(posedge clk_1k);
    end
    endtask

    task tick_many;
        input integer n;
        integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            tick_once();
    end
    endtask

    task clear_buttons;
    begin
        btn_h_inc   = 0;
        btn_m_inc   = 0;
        btn_s_inc   = 0;
        btn_confirm = 0;
        btn_start   = 0;
        btn_clear   = 0;
        btn_add5    = 0;
        btn_add10   = 0;
        btn_add15   = 0;
    end
    endtask

    task press_s_inc;
    begin
        btn_s_inc = 1;
        @(posedge clk_1k);
        btn_s_inc = 0;
        @(posedge clk_1k);
    end
    endtask

    task press_start;
    begin
        btn_start = 1;
        @(posedge clk_1k);
        btn_start = 0;
        @(posedge clk_1k);
    end
    endtask

    initial begin
        tick_1hz = 0;
        timer_sw = 0;
        clear_buttons();

        btn_clear = 1;
        repeat(5) @(posedge clk_1k);
        btn_clear = 0;
        repeat(5) @(posedge clk_1k);

        timer_sw = 1;
        repeat(5) @(posedge clk_1k);

        repeat(5) press_s_inc();

        press_start();
        repeat(5) @(posedge clk_1k);

        tick_many(6);

        tick_many(3);

        #5000;

        btn_clear = 1;
        repeat(5) @(posedge clk_1k);
        btn_clear = 0;
        repeat(5) @(posedge clk_1k);

        timer_sw = 1;
        repeat(5) @(posedge clk_1k);

        repeat(20) press_s_inc();

        press_start();
        repeat(5) @(posedge clk_1k);

        tick_many(2);

        timer_sw = 0;

        tick_many(18);

        #5000;
        $stop;
    end

endmodule
