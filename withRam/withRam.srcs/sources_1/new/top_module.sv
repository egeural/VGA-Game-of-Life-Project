`timescale 1ns / 1ps

module top_module(
    input  logic clk,          // 100MHz clock
    input  logic reset,        // Active-high reset
    input  logic btn_up,       // Up button (T18)
    input  logic btn_down,     // Down button (U17)
    input  logic btn_left,     // Left button (W19)
    input  logic btn_right,    // Right button (T17)
    input  logic btn_center,   // Center button (U18)
    input  logic clear_switch, // Rightmost switch (V17)
    input  logic start_switch, // Left switch (V16)
    output logic hsync,        // Horizontal sync
    output logic vsync,        // Vertical sync
    output logic [3:0] red,    // 4-bit red
    output logic [3:0] green,  // 4-bit green
    output logic [3:0] blue    // 4-bit blue
);

    game_of_life controller(
        .clk(clk),
        .reset(reset),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_center(btn_center),
        .clear_switch(clear_switch),
        .start_switch(start_switch),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

endmodule