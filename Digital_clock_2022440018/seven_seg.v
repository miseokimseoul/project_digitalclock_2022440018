module seven_seg_driver_6digit(
    input        clk,
    input  [3:0] d0,
    input  [3:0] d1,
    input  [3:0] d2,
    input  [3:0] d3,
    input  [3:0] d4,
    input  [3:0] d5,
    output [7:0] seg_data,
    output reg [7:0] seg_sel
);

    reg [2:0] scan_cnt;

    always @(posedge clk) begin
        if (scan_cnt == 3'd5)
            scan_cnt <= 3'd0;
        else
            scan_cnt <= scan_cnt + 3'd1;
    end

    reg [3:0] cur_digit;

    always @(*) begin
        case (scan_cnt)
            3'd0: cur_digit = d0;
            3'd1: cur_digit = d1;
            3'd2: cur_digit = d2;
            3'd3: cur_digit = d3;
            3'd4: cur_digit = d4;
            3'd5: cur_digit = d5;
            default: cur_digit = 4'd0;
        endcase
    end

    always @(*) begin
        seg_sel = 8'b1111_1111;

        case (scan_cnt)
            3'd0: seg_sel[0] = 1'b0;
            3'd1: seg_sel[1] = 1'b0;
            3'd2: seg_sel[2] = 1'b0;
            3'd3: seg_sel[3] = 1'b0;
            3'd4: seg_sel[4] = 1'b0;
            3'd5: seg_sel[5] = 1'b0;
            default: ;
        endcase
    end

    reg [7:0] seg_data_n;

    always @(*) begin
        case (cur_digit)
            4'd0: seg_data_n = 8'b1100_0000;
            4'd1: seg_data_n = 8'b1111_1001;
            4'd2: seg_data_n = 8'b1010_0100;
            4'd3: seg_data_n = 8'b1011_0000;
            4'd4: seg_data_n = 8'b1001_1001;
            4'd5: seg_data_n = 8'b1001_0010;
            4'd6: seg_data_n = 8'b1000_0010;
            4'd7: seg_data_n = 8'b1111_1000;
            4'd8: seg_data_n = 8'b1000_0000;
            4'd9: seg_data_n = 8'b1001_0000;
            default: seg_data_n = 8'b1111_1111;
        endcase

        case (scan_cnt)
            3'd0, 3'd2, 3'd4: seg_data_n[7] = 1'b0;
            default:           seg_data_n[7] = 1'b1;
        endcase
    end

    assign seg_data = ~seg_data_n;

endmodule
