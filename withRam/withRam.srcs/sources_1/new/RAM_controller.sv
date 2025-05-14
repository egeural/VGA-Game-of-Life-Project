`timescale 1ns / 1ps

module RAM_controller#(
parameter int width_of_ram = 1, // Width of each memory word
parameter int depth_of_ram = 10 // Depth of the memory (number of words)
) (
    input logic clk,                                 
    input logic write_en,                             
    input logic read_en,                              
    input logic output_rst,                           
    input logic output_en,   
    input logic [clogb2(depth_of_ram-1)-1:0] write_addr,  // Address for writing data
    input logic [clogb2(depth_of_ram-1)-1:0] read_addr,  // Address for reading data
    input logic [width_of_ram-1:0] word_in,   // Data to be written to memory                                   
    output logic [width_of_ram-1:0] word_out  // Data output        
    );
    
    logic [width_of_ram-1:0] RAM [0:depth_of_ram-1];
    logic [width_of_ram-1:0] data_of_RAM = {width_of_ram{1'b0}};
    
 
    initial begin
        foreach (RAM[i]) begin
            RAM[i] = {width_of_ram{1'b0}};
        end
    end
    
   
    always_ff @(posedge clk) begin
        if (write_en) begin
            RAM[write_addr] <= word_in; // Write data to memory at specified address
        end
        if (read_en) begin
            data_of_RAM <= RAM[read_addr]; // Read data from memory at specified address
        end
    end
    
    
    logic [width_of_ram-1:0] doutb_reg = {width_of_ram{1'b0}};
    
    always_ff @(posedge clk) begin
        if (output_rst) begin
            doutb_reg <= {width_of_ram{1'b0}};// Reset output register to zero
        end else if (output_en) begin
            doutb_reg <= data_of_RAM;  // Load data from memory into output register
        end
    end
    
     // Assign the output register value to the module output
    assign word_out = doutb_reg;
    
     // Function to calculate the number of address bits required for the given depth
    function automatic integer clogb2;
        input integer depth;
        integer i;
        begin
            clogb2 = 0;
            for (i = depth; i > 0; i = i >> 1) begin
                clogb2 = clogb2 + 1;
            end
        end
    endfunction
endmodule