`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 04.11.2025

module uarttx #(
    PREDIV = 833, // 9600bps @ f=8MHz
    PREBITS = 10 // bits needed for prescaler
) (
    input wire n_rst,
    input wire clk,
    input wire [7:0] charin,
    input wire txen,
    output reg busy,
    output reg phytx
);

reg [7:0] data;
reg [3:0] cnt;
reg [PREBITS - 1:0] precnt;

always @(posedge clk) begin
    // allow sending only when not busy
    if (txen && !busy) begin
        data <= charin;
        busy <= 1'b1;
        cnt <= 4'h0;
        precnt <= 1'b0;
    end
    
    if (busy) begin
        // only use prescaler during send
        precnt <= precnt + 1'b1;
        if (precnt == PREDIV) precnt <= 1'b0;
        if (precnt == 1'b0) begin
            case (cnt)
            4'h0: begin
                // start bit - 0
                phytx <= 1'b0;
                cnt <= cnt + 1'b1;
            end
            4'h1, 4'h2, 4'h3, 4'h4,
            4'h5, 4'h6, 4'h7, 4'h8: begin
                // data bits - LSB first
                phytx <= data[0];
                data <= {1'b0, data[7:1]};
                cnt <= cnt + 1'b1;
            end
            4'h9: begin
                // stop bit - 1
                phytx <= 1'b1;
                cnt <= cnt + 1'b1;
            end
            4'ha, 4'hb, 4'hc, 4'hd:
                cnt <= cnt + 1'b1;
            4'he: begin
                // a very long standoff, just to be sure
                // prevent very long enable pulses from sending another byte
                if (!txen) begin
                    busy <= 1'b0;
                    cnt <= 4'h0;
                end
            end
            default: cnt <= 4'h0;
            endcase
        end
    end
    
    if (!n_rst) begin
        // UART expects logic high when not transmitting
        phytx <= 1'b1;
        busy <= 1'b0;
        cnt <= 4'h0;
    end
end

endmodule
