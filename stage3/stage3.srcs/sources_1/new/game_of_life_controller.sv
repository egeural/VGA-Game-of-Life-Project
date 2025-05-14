`timescale 1ns / 1ps

module game_of_life_controller(
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

    parameter CELL_DIM = 16;
    parameter GRID_W = 640/CELL_DIM;
    parameter GRID_H = 480/CELL_DIM;
    
    logic cells [0:GRID_W-1][0:GRID_H-1];
    logic next_cells [0:GRID_W-1][0:GRID_H-1];
    
    logic px_clock;
    logic [1:0] clk_counter;
    
    always_ff @(posedge clock or posedge rst) begin
        if (rst) begin
            clk_counter <= 2'b0;
            px_clock <= 1'b0;
        end else begin
            clk_counter <= clk_counter + 1;
            px_clock <= (clk_counter == 2'd1);
        end
    end
    
    logic [24:0] sim_clk_counter = 0;
    logic sim_tick;
    
    always_ff @(posedge clock or posedge rst) begin
        if (rst) begin
            sim_clk_counter <= 0;
            sim_tick <= 0;
        end else begin
            sim_clk_counter <= sim_clk_counter + 1;
            sim_tick <= (sim_clk_counter == 25'd0);
        end
    end

    logic [9:0] h_count;
    logic [9:0] v_count;
    logic active;
    logic [9:0] px_x, px_y;
    logic [5:0] grid_x, grid_y;
    
    always_ff @(posedge px_clock or posedge rst) begin
        if (rst) begin
            h_count <= 10'b0;
            v_count <= 10'b0;
        end else begin
            if (h_count == 10'd799) begin
                h_count <= 10'b0;
                v_count <= (v_count == 10'd524) ? 10'b0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    assign h_sync = ~((h_count >= 10'd656) && (h_count < 10'd752));
    assign v_sync = ~((v_count >= 10'd490) && (v_count < 10'd492));
    assign active = (h_count < 10'd640) && (v_count < 10'd480);
    assign px_x = h_count;
    assign px_y = v_count;
    assign grid_x = px_x / CELL_DIM;
    assign grid_y = px_y / CELL_DIM;

    logic [21:0] btn_counter = 0;
    logic btn_pulse;
    logic prev_center = 0;
    
    always_ff @(posedge px_clock) begin
        btn_counter <= btn_counter + 1;
        btn_pulse <= (btn_counter == 22'd0);
    end
    
    logic [5:0] cursor_x = GRID_W/2;
    logic [5:0] cursor_y = GRID_H/2;
    
    always_ff @(posedge px_clock or posedge rst) begin
        if (rst) begin
            cursor_x <= GRID_W/2;
            cursor_y <= GRID_H/2;
        end else if (btn_pulse) begin
            if (up)
                cursor_y <= (cursor_y == 0) ? GRID_H-1 : cursor_y - 1;
            if (down)
                cursor_y <= (cursor_y == GRID_H-1) ? 0 : cursor_y + 1;
            if (left)
                cursor_x <= (cursor_x == 0) ? GRID_W-1 : cursor_x - 1;
            if (right)
                cursor_x <= (cursor_x == GRID_W-1) ? 0 : cursor_x + 1;
        end
    end

    logic prev_clear = 0;
    
    logic running = 0;
    
    always_ff @(posedge clock or posedge rst) begin
        if (rst) begin
            running <= 0;
        end else if (start) begin
            running <= 1;
        end
    end
    
    logic is_cursor;
    logic is_grid_line;
    logic cell_alive;
    
    always_comb begin
        is_cursor = ((px_x % CELL_DIM == CELL_DIM/2) && 
                    (grid_x == cursor_x) &&
                    (px_y >= cursor_y*CELL_DIM) && 
                    (px_y < (cursor_y+1)*CELL_DIM)) ||
                   ((px_y % CELL_DIM == CELL_DIM/2) && 
                    (grid_y == cursor_y) &&
                    (px_x >= cursor_x*CELL_DIM) && 
                    (px_x < (cursor_x+1)*CELL_DIM));
        
        is_grid_line = (px_x % CELL_DIM == 0) || 
                       (px_y % CELL_DIM == 0);
        
        cell_alive = cells[grid_x][grid_y];
    end
    
    always_ff @(posedge px_clock) begin
        if (active) begin
            if (is_cursor && !running) begin
                r <= 4'hF;
                g <= 4'h0;
                b <= 4'h0;
            end else if (is_grid_line) begin
                r <= 4'h8;
                g <= 4'h8;
                b <= 4'h8;
            end else if (cell_alive) begin
                r <= 4'h0;
                g <= 4'h0;
                b <= 4'h0;
            end else begin
                r <= 4'hF;
                g <= 4'hF;
                b <= 4'hF;
            end
        end else begin
            r <= 4'b0;
            g <= 4'b0;
            b <= 4'b0;
        end
    end

    always_ff @(posedge clock or posedge rst) begin
        if (rst) begin
            for (int x = 0; x < GRID_W; x++)
                for (int y = 0; y < GRID_H; y++)
                    cells[x][y] <= 1'b0;
            prev_clear <= 0;
            prev_center <= 0;
        end else begin
            if (clear && !prev_clear) begin
                for (int x = 0; x < GRID_W; x++)
                    for (int y = 0; y < GRID_H; y++)
                        cells[x][y] <= 1'b0;
            end
            
            if (btn_pulse && !running) begin
                if (center && !prev_center) begin
                    cells[cursor_x][cursor_y] <= ~cells[cursor_x][cursor_y];
                end
                prev_center <= center;
            end
            
            if (sim_tick && running) begin
                for (int x = 0; x < GRID_W; x++) begin
                    for (int y = 0; y < GRID_H; y++) begin
                        int count = 0;
                        for (int dx = -1; dx <= 1; dx++) begin
                            for (int dy = -1; dy <= 1; dy++) begin
                                if (dx != 0 || dy != 0) begin
                                    int nx = (x + dx + GRID_W) % GRID_W;
                                    int ny = (y + dy + GRID_H) % GRID_H;
                                    count += cells[nx][ny];
                                end
                            end
                        end
                        
                        if (cells[x][y]) begin
                            next_cells[x][y] <= (count == 2 || count == 3);
                        end else begin
                            next_cells[x][y] <= (count == 3);
                        end
                    end
                end
                
                for (int x = 0; x < GRID_W; x++)
                    for (int y = 0; y < GRID_H; y++)
                        cells[x][y] <= next_cells[x][y];
            end
            
            prev_clear <= clear;
        end
    end
endmodule