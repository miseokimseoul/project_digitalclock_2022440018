module clock_divider_1k_to_1hz(
    input  clk,
    output reg tick_1hz
);

    reg [9:0] cnt; 

    always @(posedge clk) begin
        if (cnt == 10'd999) begin
            cnt      <= 10'd0;
            tick_1hz <= 1'b1;
        end
        else begin
            cnt      <= cnt + 10'd1;
            tick_1hz <= 1'b0;
        end
    end

endmodule