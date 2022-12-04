`timescale 1ns / 1ps

module ili9341_pixel_raster( start, clk, bl, rst, dc, cs, din
, debug_data, debug_addr );
    input start;
    input clk;
    output bl;
    output rst;
    output dc;
    output cs;
    output din;
    
    output [31:0] debug_data;
    output [7:0] debug_addr;
    
    reg int_rst = 1'b1;
    reg int_dc = 1'bx;
    reg int_din = 1'bx;
    reg int_cs = 1'b1;
    
    // State machine
    localparam WAIT = 3'b000, COMMAND_X = 3'b001, WRITE_X = 3'b010, COMMAND_Y = 3'b011, WRITE_Y = 3'b100, COMMAND_RAM = 3'b101, WRITE_RGB = 3'b110, WRITE = 3'b111;
    reg [2:0] state = WAIT;
    reg [2:0] next_state = COMMAND_X;
    reg [7:0] rgb_addr = 8'h0F;
    reg [15:0] rgb_val = 16'b1111100000000000;
                         //  RRRRRGGGGGGBBBBB
    reg [7:0] x_command = 8'h2A;
    reg [7:0] y_command = 8'h2B;
    reg [7:0] ram_command = 8'h2C;
    reg [7:0] command_addr = 8'h07;
    reg [31:0] x_val = 32'h000000EF;
    reg [31:0] y_val = 32'h0000013F;
    reg [7:0] xy_addr = 8'h1F;
    
    reg [31:0] data = 32'h00000000;
    reg [7:0] addr = 8'h00;
    
    assign bl = 1'b1;
    assign rst = int_rst;
    assign dc = int_dc;
    assign cs = int_cs;
    assign din = int_din;
    
    assign debug_data = data;
    assign debug_addr = addr;

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
            addr <= command_addr;
            
            next_state <= WRITE_X;
            state <= WRITE;
        end
        WRITE_X:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            data <= x_val;
            addr <= xy_addr;
            
            next_state <= COMMAND_Y;
            state <= WRITE;
        end
        COMMAND_Y:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b0;
            
            data <= y_command;
            addr <= command_addr;
            
            next_state <= WRITE_Y;
            state <= WRITE;
        end
        WRITE_Y:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            data <= y_val;
            addr <= xy_addr;
            
            next_state <= COMMAND_RAM;
            state <= WRITE;
        end
        COMMAND_RAM:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b0;
            
            data <= ram_command;
            addr <= command_addr;
            
            next_state <= WRITE_RGB;
            state <= WRITE;
        end
        WRITE_RGB:
        begin
            int_cs <= 1'b1;
            int_dc <= 1'b1;
            
            data <= rgb_val;
            addr <= rgb_addr;
            
            next_state <= WRITE_RGB;
            state <= WRITE;
        end
        WRITE:
        begin
            int_cs <= 1'b0;
            if (addr == 16'h0000)
            begin
                state <= next_state;
            end
            else
                addr <= addr - 1;
                
            int_din <= data[addr];
        end
        endcase
    end
endmodule
