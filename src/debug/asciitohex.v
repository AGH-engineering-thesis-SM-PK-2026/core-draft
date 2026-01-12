`timescale 1ns / 1ps

// ASCII to 4-bit hex converter
// Szymon Miękina - 24.11.2025

module asciitohex (
    input wire [7:0]    charin, // ASCII input
    output reg [3:0]    hexout, // 4-bit output
    output reg          nothex  // error occured, not a valid character
);

always @(*) begin
    case (charin)
    "0", "1", "2", "3", 
    "4", "5", "6", "7", 
    "8", "9": begin
        hexout = charin[3:0];
        nothex = 1'b0;
    end
    "A", "B", "C", "D", 
    "E", "F": begin
        hexout = charin - 8'h37;
        nothex = 1'b0;
    end
    default: begin
        hexout = 4'h0;
        nothex = 1'b1;
    end
    endcase
end

endmodule
