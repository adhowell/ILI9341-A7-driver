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
    localparam r_start = 16'b0000100000000000;
    localparam r_limit = 16'b1111100000000000;
    localparam g_start = 16'b0000000000100000;
    localparam g_limit = 16'b0000011111100000;
    localparam b_start = 16'b0000000000000001;
    localparam b_limit = 16'b0000000000011111;
    localparam a_start = 16'b0000100001000001;
    localparam a_limit = 16'b1111111111011111;
        
    // State machine
    localparam WAIT = 3'b000, COMMAND_X = 3'b001, WRITE_X = 3'b010, COMMAND_Y = 3'b011, WRITE_Y = 3'b100, COMMAND_RAM = 3'b101, WRITE_RGB = 3'b110, WRITE = 3'b111;
    reg [2:0] state = WAIT;
    reg [2:0] next_state = WAIT;
    
    // Colour-mode state machine
    localparam RED = 2'b00, GREEN = 2'b01, BLUE = 2'b10, ALL = 2'b11; 
    reg [1:0] colour_state = RED;
    reg [7:0] rgb_len = 8'h0F;
    reg [15:0] r_val = r_start;
    reg [15:0] g_val = g_start;
    reg [15:0] b_val = b_start;
    reg [15:0] a_val = a_start;
    reg [15:0] rgb_val = r_start;
    reg [15:0] rgb_incr = r_start;
    reg [15:0] rgb_limit = r_limit;
    
    reg [7:0] x_command = 8'h2A;
    reg [7:0] y_command = 8'h2B;
    reg [7:0] ram_command = 8'h2C;
    reg [7:0] command_len = 8'h07;
    //reg [31:0] x_val = 32'h000000EF;
    //reg [31:0] y_val = 32'h0000013F;
    reg [31:0] x_val = 32'h001400DB;  // 20 -> 219
    reg [31:0] y_val = 32'h003C0103;  // 60 -> 259
    reg [7:0] xy_len = 8'h1F;
    
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
            if (col == 0)
            begin
                if (rgb_val >= rgb_limit)
                    rgb_val <= rgb_incr;
                else
                    rgb_val <= rgb_val + rgb_incr;
            end
            if (col == 99)
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
                    row <= row + 1;
                    if (row == 99)
                    begin
                        row <= 0;
                        rgb_val <= b_val;
                        rgb_incr <= b_start;
                        rgb_limit <= b_limit;
                        colour_state <= BLUE;
                    end
                    else
                    begin
                        rgb_val <= r_val;
                        rgb_incr <= r_start;
                        rgb_limit <= r_limit;
                        colour_state <= RED;
                    end
                end
                BLUE:
                begin
                    b_val <= rgb_val;
                    rgb_val <= a_val;
                    rgb_incr <= a_start;
                    rgb_limit <= a_limit;
                    colour_state <= ALL;
                end
                ALL:
                begin
                    a_val <= rgb_val;
                    row <= row + 1;
                    if (row == 99)
                    begin
                        row <= 0;
                        rgb_val <= r_val;
                        rgb_incr <= r_start;
                        rgb_limit <= r_limit;
                        colour_state <= RED;
                    end
                    else
                    begin
                        rgb_val <= b_val;
                        rgb_incr <= b_start;
                        rgb_limit <= b_limit;
                        colour_state <= BLUE;
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
