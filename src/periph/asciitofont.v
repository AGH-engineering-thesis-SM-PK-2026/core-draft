`timescale 1ns / 1ps

// TODO
// Szymon Miękina - 03.12.2025

module asciitofont (
    input wire [7:0] charin,
    output reg [5:0] fontout,
    output reg nonprint,
    output reg newline    
);

// careful, this module is asynchronous and thus glitches can propagate 
// to signals 'nonprint', 'newline', use generous delay
always @(*) begin
    // a little cheat of a remapping
    // 0x00 -> 0x00, 0x20 -> 0x00, 0x40 -> 0x20, 0x60 -> 0x20
    fontout = {charin[6], charin[4:0]};
    nonprint = charin[7:5] == 3'b000;
    newline = charin[6:0] == {3'b000, 4'ha};
end

endmodule
