`timescale 1ns / 1ps

module ili9341_colour_ramp( start, clk, bl, rst, dc, cs, din );
//, debug_data, debug_addr );
    input start;
    input clk;
    output bl;
    output rst;
    output dc;
    output cs;
    output din;
    
    //output [31:0] debug_data;
    //output [7:0] debug_addr;
    
    reg int_bl = 1'b1;
    reg int_rst = 1'b1;
    reg int_dc = 1'bx;
    reg int_din = 1'bx;
    reg int_cs = 1'b1;
    
                              //  RRRRRGGGGGGBBBBB
    localparam r_start      = 16'b0000100000000000;
    localparam r_limit      = 16'b1111100000000000;
    localparam g_start      = 16'b0000000000100000;
    localparam g_limit      = 16'b0000011111100000;
    localparam b_start      = 16'b0000000000000001;
    localparam b_limit      = 16'b0000000000011111;
    localparam rg_start     = 16'b0000100001000000;
    localparam rg_limit     = 16'b1111111111000000;
    localparam rb_start     = 16'b0000100000000001;
    localparam rb_limit     = 16'b1111100000011111;
    localparam gb_start     = 16'b0000000001000001;
    localparam gb_limit     = 16'b0000011111011111;
    localparam grey_start   = 16'b0000100001000001;
    localparam grey_limit   = 16'b1111111111011111;
    localparam all_start    = 16'b1111111111111111;
    localparam all_limit    = 16'b1111111111111111;
    localparam black_start  = 16'b0000000000000000;
    localparam black_limit  = 16'b1111111111111111;
        
    // State machine
    localparam WAIT = 3'b000, COMMAND_X = 3'b001, WRITE_X = 3'b010, COMMAND_Y = 3'b011, WRITE_Y = 3'b100, COMMAND_RAM = 3'b101, WRITE_RGB = 3'b110, WRITE = 3'b111;
    reg [2:0] state = WAIT;
    reg [2:0] next_state = WAIT;
    
    // Colour-mode state machine
    localparam RED = 4'h0, GREEN = 4'h1, BLUE = 4'h2, RED_GREEN = 4'h3, RED_BLUE = 4'h5, GREEN_BLUE = 4'h6, GREY = 4'h7, ALL = 4'h8, BLACK = 4'h9; 
    reg [3:0] colour_state = RED;
    reg [7:0] rgb_len = 8'h0F;
    reg [15:0] r_val = r_start;
    reg [15:0] g_val = g_start;
    reg [15:0] b_val = b_start;
    reg [15:0] rg_val = rg_start;
    reg [15:0] rb_val = rb_start;
    reg [15:0] gb_val = gb_start;
    reg [15:0] grey_val = grey_start;
    reg [15:0] all_val = all_start;
    reg [15:0] black_val = black_start;
    reg [15:0] rgb_val = r_start;
    reg [15:0] rgb_incr = r_start;
    reg [15:0] rgb_limit = r_limit;
    
    reg [7:0] x_command = 8'h2A;
    reg [7:0] y_command = 8'h2B;
    reg [7:0] ram_command = 8'h2C;
    reg [7:0] command_len = 8'h07;
    reg [31:0] x_val = 32'h001600D8;  // 22 -> 216
    reg [31:0] y_val = 32'h003E0100;  // 62 -> 256
    reg [7:0] xy_len = 8'h1F;
    
    localparam square_size = 65;
    
    reg [7:0] row = 8'h00;
    reg [7:0] col = 8'h00;
    
    reg [31:0] data = 32'h00000000;
    reg [7:0] index = 8'h00;
    
    assign bl = int_bl;
    assign rst = int_rst;
    assign dc = int_dc;
    assign cs = int_cs;
    assign din = int_din;
    
    //assign debug_data = data;
    //assign debug_addr = addr;

    always @ (negedge clk)
    begin            
        case (state)
        WAIT:
        begin
            if (start)
                state <= COMMAND_X;
        end
        COMMAND_X:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b0;
            
            data <= x_command;
            index <= command_len;
            
            next_state <= WRITE_X;
            state <= WRITE;
        end
        WRITE_X:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            data <= x_val;
            index <= xy_len;
            
            next_state <= COMMAND_Y;
            state <= WRITE;
        end
        COMMAND_Y:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b0;
            
            data <= y_command;
            index <= command_len;
            
            next_state <= WRITE_Y;
            state <= WRITE;
        end
        WRITE_Y:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            data <= y_val;
            index <= xy_len;
            
            next_state <= COMMAND_RAM;
            state <= WRITE;
        end
        COMMAND_RAM:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b0;
            
            data <= ram_command;
            index <= command_len;
            
            next_state <= WRITE_RGB;
            state <= WRITE;
        end
        WRITE_RGB:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            col <= col + 1;
            if (rgb_val >= rgb_limit)
                rgb_val <= rgb_incr;
            else
                rgb_val <= rgb_val + rgb_incr;

            if (col == square_size - 1)
            begin
                col <= 0;
                case (colour_state)
                RED:
                begin
                    r_val <= rgb_val;
                    rgb_val <= g_val;
                    rgb_incr <= g_start;
                    rgb_limit <= g_limit;
                    colour_state <= GREEN;
                end
                GREEN:
                begin
                    g_val <= rgb_val;
                    rgb_val <= b_val;
                    rgb_incr <= b_start;
                    rgb_limit <= b_limit;
                    colour_state <= BLUE;
                end
                BLUE:
                begin
                    b_val <= rgb_val;
                    row <= row + 1;
                    if (row == square_size - 1)
                    begin
                        row <= 0;
                        rgb_val <= rg_val;
                        rgb_incr <= rg_start;
                        rgb_limit <= rg_limit;
                        colour_state <= RED_GREEN;
                    end
                    else
                    begin
                        rgb_val <= r_val;
                        rgb_incr <= r_start;
                        rgb_limit <= r_limit;
                        colour_state <= RED;
                    end
                end
                RED_GREEN:
                begin
                    rg_val <= rgb_val;
                    rgb_val <= rb_val;
                    rgb_incr <= rb_start;
                    rgb_limit <= rb_limit;
                    colour_state <= RED_BLUE;
                end
                RED_BLUE:
                begin
                    rb_val <= rgb_val;
                    rgb_val <= gb_val;
                    rgb_incr <= gb_start;
                    rgb_limit <= gb_limit;
                    colour_state <= GREEN_BLUE;
                end
                GREEN_BLUE:
                begin
                    gb_val <= rgb_val;
                    row <= row + 1;
                    if (row == square_size - 1)
                    begin
                        row <= 0;
                        rgb_val <= grey_val;
                        rgb_incr <= grey_start;
                        rgb_limit <= grey_limit;
                        colour_state <= GREY;
                    end
                    else
                    begin
                        rgb_val <= rg_val;
                        rgb_incr <= rg_start;
                        rgb_limit <= rg_limit;
                        colour_state <= RED_GREEN;
                    end
                end
                GREY:
                begin
                    grey_val <= rgb_val;
                    rgb_val <= all_val;
                    rgb_incr <= all_start;
                    rgb_limit <= all_limit;
                    colour_state <= ALL;
                end
                ALL:
                begin
                    all_val <= rgb_val;
                    rgb_val <= black_val;
                    rgb_incr <= black_start;
                    rgb_limit <= black_limit;
                    colour_state <= BLACK;
                end
                BLACK:
                begin
                    black_val <= rgb_val;
                    row <= row + 1;
                    if (row == square_size - 1)
                    begin
                        row <= 0;
                        rgb_val <= r_val;
                        rgb_incr <= r_start;
                        rgb_limit <= r_limit;
                        colour_state <= RED;
                    end
                    else
                    begin
                        rgb_val <= grey_val;
                        rgb_incr <= grey_start;
                        rgb_limit <= grey_limit;
                        colour_state <= GREY;
                    end
                end
                endcase
            end

            data <= rgb_val;
            index <= rgb_len;
            
            next_state <= WRITE_RGB;
            state <= WRITE;
        end
        WRITE:
        begin
            int_cs <= 1'b0;
            if (index == 8'h00)
                state <= next_state;
            else
                index <= index - 1;
                
            int_din <= data[index];
        end
        endcase
    end
endmodule
