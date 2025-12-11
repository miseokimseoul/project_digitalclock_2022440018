module oneshot_universal
#(
    parameter WIDTH = 1
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      btn,
    output reg [WIDTH-1:0]  btn_trig
);

    reg [WIDTH-1:0] btn_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_reg  <= {WIDTH{1'b0}};
            btn_trig <= {WIDTH{1'b0}};
        end
        else begin
            btn_reg  <= btn;
            btn_trig <= btn & ~btn_reg;
        end
    end

endmodule
