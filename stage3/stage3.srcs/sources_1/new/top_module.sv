`timescale 1ns / 1ps

module top_module(
    input  logic clock,
    input  logic rst,
    input  logic up,
    input  logic down,
    input  logic left,
    input  logic right, 
    input  logic center,
    input  logic clear,
    input  logic start,
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b
);
    game_of_life_controller sim(
        .clock(clock),
        .rst(rst),
        .up(up),
        .down(down),
        .left(left),
        .right(right),
        .center(center),
        .clear(clear),
        .start(start),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .r(r),
        .g(g),
        .b(b)
    );
endmodule