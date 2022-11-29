`timescale 1ns / 1ps

module clk_half_divider ( clk_in, clk_out );
    input clk_in;
    output clk_out;
    
    reg clk_out_reg = 1'b0;
    assign clk_out = clk_out_reg;
    
    always @ (posedge clk_in)
        clk_out_reg <= clk_out_reg + 1;
endmodule

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din, debug_ram_addr, debug_ram_out_addr, debug_ram_out );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;
    
    output [9:0] debug_ram_addr;
    output [3:0] debug_ram_out_addr;
    output [7:0] debug_ram_out;

    // Half the clock rate
    wire sysclk_div;
    clk_half_divider clk_half ( 
        .clk_in(sysclk),
        .clk_out(sysclk_div)
    );
    
    wire int_bl;
    wire int_rst;
    wire int_dc;
    wire int_din;
    wire int_cs;
    wire system_ready;
    ili9341_initialiser init_unit (
        .clk(sysclk_div),
        .tft_bl(int_bl),
        .tft_rst(int_rst),
        .tft_dc(int_dc),
        .tft_cs(int_cs),
        .tft_din(int_din),
        .ready(system_ready)
    );
    
    assign tft_bl = int_bl;
    assign tft_rst = int_rst;
    assign tft_dc = int_dc;
    assign tft_cs = int_cs;
    assign tft_clk = sysclk_div;
    assign tft_din = int_din;
    assign ready = system_ready;

endmodule
