module time_counter_hms_bcd(
    input        clk,
    input        clr_time,
    input        tick_1hz,
    input        inc_hour,
    input        inc_min,
    input        inc_sec,
    output reg [3:0] sec_ones,
    output reg [3:0] sec_tens,
    output reg [3:0] min_ones,
    output reg [3:0] min_tens,
    output reg [3:0] hour_ones,
    output reg [1:0] hour_tens
);

    wire sec_pulse  = tick_1hz | inc_sec;
    wire min_pulse  = inc_min;
    wire hour_pulse = inc_hour;

    always @(posedge clk) begin
        if (clr_time) begin
            sec_ones  <= 4'd0;
            sec_tens  <= 4'd0;
            min_ones  <= 4'd0;
            min_tens  <= 4'd0;
            hour_ones <= 4'd0;
            hour_tens <= 2'd0;
        end
        else begin
            if (sec_pulse) begin
                if (sec_ones == 4'd9) begin
                    sec_ones <= 4'd0;
                    if (sec_tens == 4'd5) begin
                        sec_tens <= 4'd0;

                        if (min_ones == 4'd9) begin
                            min_ones <= 4'd0;
                            if (min_tens == 4'd5) begin
                                min_tens <= 4'd0;

                                if (hour_tens == 2'd2 && hour_ones == 4'd3) begin
                                    hour_tens <= 2'd0;
                                    hour_ones <= 4'd0;
                                end
                                else if (hour_ones == 4'd9) begin
                                    hour_ones <= 4'd0;
                                    hour_tens <= hour_tens + 2'd1;
                                end
                                else begin
                                    hour_ones <= hour_ones + 4'd1;
                                end
                            end
                            else begin
                                min_tens <= min_tens + 4'd1;
                            end
                        end
                        else begin
                            min_ones <= min_ones + 4'd1;
                        end
                    end
                    else begin
                        sec_tens <= sec_tens + 4'd1;
                    end
                end
                else begin
                    sec_ones <= sec_ones + 4'd1;
                end
            end

            if (min_pulse) begin
                if (min_ones == 4'd9) begin
                    min_ones <= 4'd0;
                    if (min_tens == 4'd5) begin
                        min_tens <= 4'd0;

                        if (hour_tens == 2'd2 && hour_ones == 4'd3) begin
                            hour_tens <= 2'd0;
                            hour_ones <= 4'd0;
                        end
                        else if (hour_ones == 4'd9) begin
                            hour_ones <= 4'd0;
                            hour_tens <= hour_tens + 2'd1;
                        end
                        else begin
                            hour_ones <= hour_ones + 4'd1;
                        end
                    end
                    else begin
                        min_tens <= min_tens + 4'd1;
                    end
                end
                else begin
                    min_ones <= min_ones + 4'd1;
                end
            end

            if (hour_pulse) begin
                if (hour_tens == 2'd2 && hour_ones == 4'd3) begin
                    hour_tens <= 2'd0;
                    hour_ones <= 4'd0;
                end
                else if (hour_ones == 4'd9) begin
                    hour_ones <= 4'd0;
                    hour_tens <= hour_tens + 2'd1;
                end
                else begin
                    hour_ones <= hour_ones + 4'd1;
                end
            end
        end
    end

endmodule
