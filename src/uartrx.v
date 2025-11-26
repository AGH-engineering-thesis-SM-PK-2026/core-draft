`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 24.11.2025

module uartrx #(
    PREDIV = 833, // 9600bps @ f=8MHz
    PREMID = 400, // midpoint for sampling
    PREBITS = 10 // bits needed for prescaler
) (
    input wire n_rst,
    input wire clk,
    output reg [7:0] charout,
    output reg done,
    output reg busy,
    input wire phyrx
);

reg [3:0] cnt;
reg [15:0] filter;
reg [PREBITS - 1:0] precnt;

// conditioned rx
wire rx = &filter;

always @(posedge clk) begin
    filter <= {phyrx, filter[15:1]};
    if (!busy && !rx) begin
        // start condition detected, sync precnt
        precnt <= 1'b0;
        cnt <= 4'h0;
        busy <= 1'b1;
    end

    if (busy) begin
        // only use prescaler during recv
        precnt <= precnt + 1'b1;
        if (precnt == PREDIV) precnt <= 1'b0;
        if (precnt == PREMID) begin
            case (cnt)
            4'h0: begin
                // start bit
                done <= 1'b0;
                cnt <= cnt + 1'b1;
            end
            4'h1, 4'h2, 4'h3, 4'h4,
            4'h5, 4'h6, 4'h7, 4'h8: begin
                // data bits - LSB first
                charout <= {rx, charout[7:1]};
                cnt <= cnt + 1'b1;
            end
            4'h9: begin
                // stop bit - done
                done <= 1'b1;
                busy <= 1'b0;
            end
            default: cnt <= 4'h0;
            endcase
        end
    end

    if (!n_rst) begin
        busy <= 1'b0;
        done <= 1'b0;
    end
end

endmodule
