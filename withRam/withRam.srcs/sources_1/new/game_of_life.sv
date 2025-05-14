`timescale 1ns / 1ps

module game_of_life(
    input  logic clk,          // 100MHz clock
    input  logic reset,        // Active-high reset
    input  logic btn_up,       // Up button (T18)
    input  logic btn_down,     // Down button (U17)
    input  logic btn_left,     // Left button (W19)
    input  logic btn_right,    // Right button (T17)
    input  logic btn_center,   // Center button (U18)
    input  logic clear_switch, // Rightmost switch (V17)
    input  logic start_switch, // V16
    output logic hsync,        // Horizontal sync
    output logic vsync,        // Vertical sync
    output logic [3:0] red,    // 4-bit red
    output logic [3:0] green,  // 4-bit green
    output logic [3:0] blue    // 4-bit blue
);

    // 1. Parameters for grid size
    parameter SQUARE_SIZE = 8;       // 8x8 pixel squares
    parameter GRID_WIDTH = 80;       // 80 squares wide
    parameter GRID_HEIGHT = 60;      // 60 squares tall
    
    // 2. Clock Division (100MHz -> 25MHz)
    logic pixel_clk;
    logic [1:0] clk_div;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 2'b0;
            pixel_clk <= 1'b0;
        end else begin
            clk_div <= clk_div + 1;
            pixel_clk <= (clk_div == 2'd1); // 25MHz clock
        end
    end
    
    // Game clock for simulation updates (1 Hz)
    logic [24:0] game_clk_div = 0;
    logic game_tick;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            game_clk_div <= 0;
            game_tick <= 0;
        end else begin
            // Keep incrementing the counter
            game_clk_div <= game_clk_div + 1;
            
            // Create a more stable game tick - active for multiple cycles
            // This creates a more reliable window for the state machine to detect
            if (game_clk_div == 25'd0)
                game_tick <= 1;  // Start game tick
            else if (game_clk_div == 25'd100)  
                game_tick <= 0;  // End game tick after 100 cycles
        end
    end

    // 3. VGA Timing Generation
    logic [9:0] h_count;
    logic [9:0] v_count;
    logic display_active;
    logic [9:0] pixel_x, pixel_y;
    logic [6:0] grid_x; // 7 bits for 80 grid width
    logic [5:0] grid_y; // 6 bits for 60 grid height
    
    always_ff @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
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

    assign hsync = ~((h_count >= 10'd656) && (h_count < 10'd752));
    assign vsync = ~((v_count >= 10'd490) && (v_count < 10'd492));
    assign display_active = (h_count < 10'd640) && (v_count < 10'd480);
    assign pixel_x = h_count;
    assign pixel_y = v_count;
    assign grid_x = pixel_x / SQUARE_SIZE; // Which grid square X
    assign grid_y = pixel_y / SQUARE_SIZE; // Which grid square Y

    // 4. Button Debouncing
    // Simple counter-based debounce for buttons
    logic [21:0] btn_counter = 0;
    logic btn_sample;
    
    // Generate button sample enable at ~100Hz
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_counter <= 0;
            btn_sample <= 0;
        end else begin
            btn_counter <= btn_counter + 1;
            btn_sample <= (btn_counter == 0);
        end
    end
    
    // Button states
    logic [7:0] btn_center_sr = 0;  // 8-bit shift register for center button
    logic btn_center_pressed = 0;   // Rising edge detection
    
    // Button debouncing with shift register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            btn_center_sr <= 0;
            btn_center_pressed <= 0;
        end else if (btn_sample) begin
            // Shift in the new button value
            btn_center_sr <= {btn_center_sr[6:0], btn_center};
            
            // Button is pressed when we see a transition from all 0s to some 1s
            if (btn_center_sr == 8'h00 && btn_center)
                btn_center_pressed <= 1;
            else
                btn_center_pressed <= 0;
        end else begin
            btn_center_pressed <= 0; // Clear pressed flag outside sample window
        end
    end
    
    // 5. Cursor Position Control with Speed Adjustment
    logic [6:0] cursor_x = GRID_WIDTH/2;
    logic [5:0] cursor_y = GRID_HEIGHT/2;
    logic [1:0] cursor_speed_divider = 0; // Controls cursor movement speed (1-bit for 50% speed)
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cursor_x <= GRID_WIDTH/2;
            cursor_y <= GRID_HEIGHT/2;
            cursor_speed_divider <= 0;
        end else if (btn_sample && !running) begin
            // Increment speed divider
            cursor_speed_divider <= cursor_speed_divider + 1;
            
            // Only move cursor when divider is 0 (reduces movement to 50% of original speed)
            if (cursor_speed_divider == 0) begin  // Move on 1 out of 2 cycles (exactly 50% speed)
                // Only move cursor when not running
                if (btn_up)
                    cursor_y <= (cursor_y == 0) ? GRID_HEIGHT-1 : cursor_y - 1;
                else if (btn_down)
                    cursor_y <= (cursor_y == GRID_HEIGHT-1) ? 0 : cursor_y + 1;
                else if (btn_left)
                    cursor_x <= (cursor_x == 0) ? GRID_WIDTH-1 : cursor_x - 1;
                else if (btn_right)
                    cursor_x <= (cursor_x == GRID_WIDTH-1) ? 0 : cursor_x + 1;
            end
        end
    end
    
    // 6. Game State Control
    logic running = 0;
    logic prev_clear_switch = 0;
    logic prev_start_switch = 0;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            running <= 0;
            prev_clear_switch <= 0;
            prev_start_switch <= 0;
        end else begin
            prev_clear_switch <= clear_switch;
            prev_start_switch <= start_switch;
            
            // Toggle running state on start_switch rising edge
            if (start_switch && !prev_start_switch)
                running <= ~running;
            
            // Clear grid and stop running on clear_switch rising edge
            if (clear_switch && !prev_clear_switch)
                running <= 0;
        end
    end
    
    // 7. Dual RAM for current and next grid state
    
    // RAM signals
    logic [12:0] curr_addr;         // Address for current grid RAM (13 bits for 4800 cells)
    logic curr_we;                  // Write enable for current grid
    logic [0:0] curr_data_in;       // Data to write to current grid
    logic [0:0] curr_data_out;      // Data read from current grid
    
    logic [12:0] next_addr;         // Address for next grid RAM
    logic next_we;                  // Write enable for next grid
    logic [0:0] next_data_in;       // Data to write to next grid
    logic [0:0] next_data_out;      // Data read from next grid
    
    // Function to convert (x,y) to linear address
    function automatic [12:0] xy_to_addr(input [6:0] x, input [5:0] y);
        return (y * GRID_WIDTH) + x;
    endfunction
    
    // RAM modules instantiation
    ram_4800x1 current_grid (
        .clk(clk),
        .addr(curr_addr),
        .we(curr_we),
        .data_in(curr_data_in),
        .data_out(curr_data_out)
    );
    
    ram_4800x1 next_grid (
        .clk(clk),
        .addr(next_addr),
        .we(next_we),
        .data_in(next_data_in),
        .data_out(next_data_out)
    );
    
    // 8. Game Logic State Machine
    typedef enum logic [3:0] {
        IDLE,
        CLEAR_GRID,
        TOGGLE_CELL_READ,
        TOGGLE_CELL_WRITE,
        READ_CELL,
        COUNT_NEIGHBORS,
        NEXT_NEIGHBOR,
        APPLY_RULES,
        ADVANCE_CELL,
        COPY_START,
        COPY_WAIT_READ,    // Add this new state
        COPY_READ,
        COPY_WAIT_WRITE,   // Add this new state
        COPY_WRITE
    } state_t;
    
    state_t state = IDLE;
    logic [12:0] clear_addr = 0;        // Address counter for clearing grid
    logic [6:0] update_x = 0;           // X coordinate of cell being updated
    logic [5:0] update_y = 0;           // Y coordinate of cell being updated
    logic [3:0] neighbor_count = 0;     // Count of live neighbors
    logic [3:0] neighbor_idx = 0;       // Current neighbor being checked
    logic current_cell_state = 0;       // State of current cell being processed
    logic [12:0] copy_addr = 0;         // Address counter for copying grid
    logic [6:0] nx;
    logic [5:0] ny;
    
    // State machine for game logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= CLEAR_GRID;
            clear_addr <= 0;
            update_x <= 0;
            update_y <= 0;
            neighbor_count <= 0;
            neighbor_idx <= 0;
            current_cell_state <= 0;
            copy_addr <= 0;
            
            curr_addr <= 0;
            curr_we <= 0;
            curr_data_in <= 0;
            
            next_addr <= 0;
            next_we <= 0;
            next_data_in <= 0;
        end else begin
            // Default RAM control values
            curr_we <= 0;
            next_we <= 0;
            
            case (state)
                IDLE: begin
                    // By default, read current pixel for display
                    curr_addr <= xy_to_addr(grid_x, grid_y);
                    
                    // Check for actions
                    if (clear_switch && !prev_clear_switch) begin
                        // Start clearing grid
                        state <= CLEAR_GRID;
                        clear_addr <= 0;
                    end else if (btn_center_pressed && !running) begin
                        // Toggle cell at cursor position
                        state <= TOGGLE_CELL_READ;
                        curr_addr <= xy_to_addr(cursor_x, cursor_y);
                    end else if (game_tick && running) begin
                        // Start game update
                        state <= READ_CELL;
                        update_x <= 0;
                        update_y <= 0;
                    end
                end
                
                CLEAR_GRID: begin
                    // Clear both grids - one address at a time
                    curr_addr <= clear_addr;
                    curr_we <= 1;
                    curr_data_in <= 0;
                    
                    next_addr <= clear_addr;
                    next_we <= 1;
                    next_data_in <= 0;
                    
                    if (clear_addr < (GRID_WIDTH * GRID_HEIGHT - 1)) begin
                        clear_addr <= clear_addr + 1;
                    end else begin
                        state <= IDLE;
                        // Set up for display
                        curr_addr <= xy_to_addr(grid_x, grid_y);
                    end
                end
                
                TOGGLE_CELL_READ: begin
                    // Wait one cycle for RAM read to complete
                    state <= TOGGLE_CELL_WRITE;
                end
                
                TOGGLE_CELL_WRITE: begin
                    // Toggle the cell
                    curr_addr <= xy_to_addr(cursor_x, cursor_y);
                    curr_we <= 1;
                    curr_data_in <= ~curr_data_out;
                    state <= IDLE;
                end
                
                READ_CELL: begin
                    // Read the current cell
                    curr_addr <= xy_to_addr(update_x, update_y);
                    neighbor_count <= 0;
                    neighbor_idx <= 0;
                    state <= COUNT_NEIGHBORS;
                end
                
                COUNT_NEIGHBORS: begin
                    // Store the current cell's state
                    current_cell_state <= curr_data_out;
                    
                    // Start checking neighbors
                    neighbor_idx <= 1;
                    state <= NEXT_NEIGHBOR;
                    
                    // Set up to read the first neighbor (top-left)
                    nx = (update_x == 0) ? GRID_WIDTH-1 : update_x-1;
                    ny = (update_y == 0) ? GRID_HEIGHT-1 : update_y-1;
                    curr_addr <= xy_to_addr(nx, ny);
                end
                
                NEXT_NEIGHBOR: begin
                    // Count the neighbor if it's alive
                    if (curr_data_out)
                        neighbor_count <= neighbor_count + 1;
                    
                    if (neighbor_idx < 8) begin
                        // Set up to read the next neighbor
                        // REMOVED local declarations of nx and ny
                        
                        case (neighbor_idx)
                            1: begin 
                                nx = update_x; 
                                ny = (update_y == 0) ? GRID_HEIGHT-1 : update_y-1; 
                            end
                            2: begin 
                                nx = (update_x == GRID_WIDTH-1) ? 0 : update_x+1; 
                                ny = (update_y == 0) ? GRID_HEIGHT-1 : update_y-1; 
                            end
                            3: begin 
                                nx = (update_x == 0) ? GRID_WIDTH-1 : update_x-1; 
                                ny = update_y; 
                            end
                            4: begin 
                                nx = (update_x == GRID_WIDTH-1) ? 0 : update_x+1; 
                                ny = update_y; 
                            end
                            5: begin 
                                nx = (update_x == 0) ? GRID_WIDTH-1 : update_x-1; 
                                ny = (update_y == GRID_HEIGHT-1) ? 0 : update_y+1; 
                            end
                            6: begin 
                                nx = update_x; 
                                ny = (update_y == GRID_HEIGHT-1) ? 0 : update_y+1; 
                            end
                            7: begin 
                                nx = (update_x == GRID_WIDTH-1) ? 0 : update_x+1; 
                                ny = (update_y == GRID_HEIGHT-1) ? 0 : update_y+1; 
                            end
                            default: begin 
                                nx = update_x; 
                                ny = update_y; 
                            end
                        endcase
                        
                        curr_addr <= xy_to_addr(nx, ny);
                        neighbor_idx <= neighbor_idx + 1;
                    end else begin
                        // All neighbors checked - apply rules
                        state <= APPLY_RULES;
                        
                        // Count the last neighbor
                        if (curr_data_out)
                            neighbor_count <= neighbor_count + 1;
                    end
                end
                
                APPLY_RULES: begin
                    // Apply Conway's rules and write to next state RAM
                    next_addr <= xy_to_addr(update_x, update_y);
                    next_we <= 1;
                    
                    if (current_cell_state) begin
                        // Cell is alive
                        next_data_in <= (neighbor_count == 2 || neighbor_count == 3);
                    end else begin
                        // Cell is dead
                        next_data_in <= (neighbor_count == 3);
                    end
                    
                    state <= ADVANCE_CELL;
                end
                
                ADVANCE_CELL: begin
                    // Move to next cell or finish update
                    if (update_x < GRID_WIDTH - 1) begin
                        update_x <= update_x + 1;
                        state <= READ_CELL;
                    end else if (update_y < GRID_HEIGHT - 1) begin
                        update_x <= 0;
                        update_y <= update_y + 1;
                        state <= READ_CELL;
                    end else begin
                        // All cells processed, copy next state to current
                        state <= COPY_START;
                        copy_addr <= 0;
                    end
                end
                
                COPY_START: begin
                    // Initialize the copy process
                    next_addr <= copy_addr;
                    state <= COPY_WAIT_READ;  // Add wait state
                end

                COPY_WAIT_READ: begin
                    // Wait one cycle for address to propagate
                    state <= COPY_READ;
                end

                COPY_READ: begin
                    // Read from next grid
                    curr_addr <= copy_addr;  // Setup current grid address for writing
                    state <= COPY_WAIT_WRITE;  // Add wait state
                end

                COPY_WAIT_WRITE: begin
                    // Wait one cycle for data to be ready
                    state <= COPY_WRITE;
                end

                COPY_WRITE: begin
                    // Write to current grid
                    curr_we <= 1;
                    curr_data_in <= next_data_out;
                    
                    if (copy_addr < (GRID_WIDTH * GRID_HEIGHT - 1)) begin
                        // Move to next address
                        copy_addr <= copy_addr + 1;
                        next_addr <= copy_addr + 1;
                        state <= COPY_WAIT_READ;  // Go back to wait state
                    end else begin
                        // Copying complete
                        state <= IDLE;
                        // Set up for display
                        curr_addr <= xy_to_addr(grid_x, grid_y);
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // 9. Cursor and Grid Rendering
    logic is_cursor;
    logic is_grid_line;
    
    // Calculate cursor and grid line positions
    always_comb begin
        // Vertical cursor line (middle of square)
        is_cursor = ((pixel_x % SQUARE_SIZE == SQUARE_SIZE/2) && 
                    (grid_x == cursor_x) &&
                    (pixel_y >= cursor_y*SQUARE_SIZE) && 
                    (pixel_y < (cursor_y+1)*SQUARE_SIZE)) ||
                   // Horizontal cursor line (middle of square)
                   ((pixel_y % SQUARE_SIZE == SQUARE_SIZE/2) && 
                    (grid_y == cursor_y) &&
                    (pixel_x >= cursor_x*SQUARE_SIZE) && 
                    (pixel_x < (cursor_x+1)*SQUARE_SIZE));
        
        // Grid lines (1 pixel border between squares)
        is_grid_line = (pixel_x % SQUARE_SIZE == 0) || 
                       (pixel_y % SQUARE_SIZE == 0);
    end
    
    // 10. Output to VGA
    always_ff @(posedge pixel_clk) begin
        if (display_active) begin
            if (is_cursor && !running) begin  // Only show cursor when not running
                red   <= 4'hF; // Cursor is red
                green <= 4'h0;
                blue  <= 4'h0;
            end else if (is_grid_line) begin
                red   <= 4'h8; // Grid lines are gray
                green <= 4'h8;
                blue  <= 4'h8;
            end else if (curr_data_out) begin
                // Square is black when set to 1 (alive cell)
                red   <= 4'h0;
                green <= 4'h0;
                blue  <= 4'h0;
            end else begin
                // Square is white when set to 0 (dead cell)
                red   <= 4'hF;
                green <= 4'hF;
                blue  <= 4'hF;
            end
        end else begin
            // Blanking interval
            red   <= 4'b0;
            green <= 4'b0;
            blue  <= 4'b0;
        end
    end
endmodule

// Single-port RAM module (4800x1 bits)
module ram_4800x1 (
    input  logic clk,
    input  logic [12:0] addr,    // 13 bits for 4800 cells
    input  logic we,             // Write enable
    input  logic [0:0] data_in,  // 1-bit input data
    output logic [0:0] data_out  // 1-bit output data
);
    // Memory array
    logic [0:0] mem [0:4799];
    
    // Write synchronously
    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
    end
    
    // Read asynchronously for display performance
    assign data_out = mem[addr];
    
    // Initialize memory to zeros
    initial begin
        for (int i = 0; i < 4800; i = i + 1) begin
            mem[i] = 1'b0;
        end
    end
endmodule