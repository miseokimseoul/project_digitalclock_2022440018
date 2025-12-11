`timescale 1us/1us

module tb_3_5_stopwatch;

    reg clk_1k;
    reg stopwatch_sw;
    reg btn_start;
    reg btn_lap;
    reg btn_clear;
    reg btn_view;

    wire [3:0] cur_m_tens, cur_m_ones;
    wire [3:0] cur_s_tens, cur_s_ones;
    wire [3:0] cur_cs_tens, cur_cs_ones;

    wire [3:0] lap_m_tens, lap_m_ones;
    wire [3:0] lap_s_tens, lap_s_ones;
    wire [3:0] lap_cs_tens, lap_cs_ones;

    wire [3:0] int_m_tens, int_m_ones;
    wire [3:0] int_s_tens, int_s_ones;
    wire [3:0] int_cs_tens, int_cs_ones;

    wire [3:0] best_m_tens, best_m_ones;
    wire [3:0] best_s_tens, best_s_ones;
    wire [3:0] best_cs_tens, best_cs_ones;

    wire [3:0] avg_m_tens, avg_m_ones;
    wire [3:0] avg_s_tens, avg_s_ones;
    wire [3:0] avg_cs_tens, avg_cs_ones;

    wire       lap_valid;
    wire [1:0] sw_lcd_mode;
    wire       sw_update_toggle;

    StopwatchController dut (
        .clk_1k       (clk_1k),
        .stopwatch_sw (stopwatch_sw),

        .btn_start    (btn_start),
        .btn_lap      (btn_lap),
        .btn_clear    (btn_clear),
        .btn_view     (btn_view),

        .cur_m_tens   (cur_m_tens),
        .cur_m_ones   (cur_m_ones),
        .cur_s_tens   (cur_s_tens),
        .cur_s_ones   (cur_s_ones),
        .cur_cs_tens  (cur_cs_tens),
        .cur_cs_ones  (cur_cs_ones),

        .lap_m_tens   (lap_m_tens),
        .lap_m_ones   (lap_m_ones),
        .lap_s_tens   (lap_s_tens),
        .lap_s_ones   (lap_s_ones),
        .lap_cs_tens  (lap_cs_tens),
        .lap_cs_ones  (lap_cs_ones),

        .int_m_tens   (int_m_tens),
        .int_m_ones   (int_m_ones),
        .int_s_tens   (int_s_tens),
        .int_s_ones   (int_s_ones),
        .int_cs_tens  (int_cs_tens),
        .int_cs_ones  (int_cs_ones),

        .best_m_tens  (best_m_tens),
        .best_m_ones  (best_m_ones),
        .best_s_tens  (best_s_tens),
        .best_s_ones  (best_s_ones),
        .best_cs_tens (best_cs_tens),
        .best_cs_ones (best_cs_ones),

        .avg_m_tens   (avg_m_tens),
        .avg_m_ones   (avg_m_ones),
        .avg_s_tens   (avg_s_tens),
        .avg_s_ones   (avg_s_ones),
        .avg_cs_tens  (avg_cs_tens),
        .avg_cs_ones  (avg_cs_ones),

        .lap_valid        (lap_valid),
        .sw_lcd_mode      (sw_lcd_mode),
        .sw_update_toggle (sw_update_toggle)
    );

    initial clk_1k = 1'b0;
    always #0.5 clk_1k = ~clk_1k;

    task pulse_start;
        begin
            btn_start = 1'b1;
            @(posedge clk_1k);
            btn_start = 1'b0;
        end
    endtask

    task pulse_lap;
        begin
            btn_lap = 1'b1;
            @(posedge clk_1k);
            btn_lap = 1'b0;
        end
    endtask

    task pulse_clear;
        begin
            btn_clear = 1'b1;
            @(posedge clk_1k);
            btn_clear = 1'b0;
        end
    endtask

    task pulse_view;
        begin
            btn_view = 1'b1;
            @(posedge clk_1k);
            btn_view = 1'b0;
        end
    endtask

    initial begin
        stopwatch_sw = 1'b0;
        btn_start    = 1'b0;
        btn_lap      = 1'b0;
        btn_clear    = 1'b0;
        btn_view     = 1'b0;

        repeat (10) @(posedge clk_1k);

        stopwatch_sw = 1'b1;

        repeat (10) @(posedge clk_1k);

        repeat (3000) @(posedge clk_1k);

        pulse_start();

        repeat (3000) @(posedge clk_1k);
        pulse_lap();

        repeat (3000) @(posedge clk_1k);
        pulse_lap();

        repeat (10) @(posedge clk_1k);
        pulse_view();

        repeat (500) @(posedge clk_1k);
        $stop;
    end

endmodule
