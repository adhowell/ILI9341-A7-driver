`timescale 1ns / 1ps

module clk_half_divider ( clk_in, clk_out );
    input clk_in;
    output clk_out;
    
    reg clk_out_reg = 1'b0;
    assign clk_out = clk_out_reg;
    
    always @ (posedge clk_in)
        clk_out_reg <= clk_out_reg + 1;
endmodule

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din, debug_ram_ptr, debug_ram_out_ptr, debug_ram_out );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;
    
    output [9:0] debug_ram_ptr;
    output [3:0] debug_ram_out_ptr;
    output [7:0] debug_ram_out;

    // Half the clock rate
    wire sysclk_div;
    clk_half_divider clk_half ( 
        .clk_in(sysclk),
        .clk_out(sysclk_div)
    );

    reg int_rst = 1'b0;
    reg int_dc = 1'b0;
    reg int_din = 1'b0;
    reg int_cs = 1'b1;

    reg [15:0] data_out_reg = 16'b0;
    reg [3:0] ptr = 4'b0;
    
    // Initial state 
    reg [9:0] ram_ptr = 10'b0;
    reg [2:0] ram_out_ptr = 3'b111;
    wire [7:0] ram_out;
    localparam INIT = 2'b00, NORM = 2'b01, WAIT = 2'b10;
    reg [1:0] state = INIT;
    // Loaded with init_commands.coe
    dist_mem_gen_0 init_ram (
        .a(ram_ptr),
        .spo(ram_out)
    );

    reg [19:0] wait_counter = 20'b0;
    
    assign tft_bl = btn[0];
    assign tft_rst = int_rst;
    assign tft_dc = int_dc;
    assign tft_cs = int_cs;
    assign tft_clk = sysclk_div;
    assign tft_din = int_din;
    
    assign debug_ram_ptr = ram_ptr;
    assign debug_ram_out_ptr = ram_out_ptr;
    assign debug_ram_out = ram_out;

    always @ (posedge sysclk_div)
    begin            
        case (state)
        INIT:
        begin
            int_dc <= 1'b1;
            int_rst <= 1'b1;
            int_cs <= 1'b0;
            
            if (ram_out_ptr == 3'b0)
            begin
                ram_out_ptr <= 3'b111;
                ram_ptr <= ram_ptr + 1;
                //if (ram_ptr == 110)
                //    state <= NORM;
                if (ram_out == 8'b10000000)
                    state <= WAIT;
            end
            else
                ram_out_ptr <= ram_out_ptr - 1;
                
            int_din <= ram_out[ram_out_ptr];
        end
        WAIT:
        begin
            int_dc <= 1'b1;
            int_rst <= 1'b1;
            int_cs <= 1'b1;
            
            // 150ms wait desired so 900,000 cycles for 6MHz clock
            if (wait_counter == 900000)
            begin
                wait_counter = 20'b0;
                state <= INIT;
            end
            else
                wait_counter <= wait_counter + 1;
        end
        NORM:
        begin
            int_dc <= 1'b0;
            int_rst <= 1'b1;
            int_cs <= 1'b0;
            
            if (ptr == 4'b1)
                ptr <= 4'b0;
            if (data_out_reg == 32'b1)
                data_out_reg <= 32'b0;
            ptr <= ptr + 1'b1;
            data_out_reg <= data_out_reg + 1'b1;
            int_din <= data_out_reg[ptr];
        end
        endcase
    end
endmodule
