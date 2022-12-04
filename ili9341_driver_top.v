`timescale 1ns / 1ps

module clk_half_divider ( clk_in, clk_out );
    input clk_in;
    output clk_out;
    
    reg clk_out_reg = 1'b0;
    assign clk_out = clk_out_reg;
    
    always @ (posedge clk_in)
        clk_out_reg <= clk_out_reg + 1;
endmodule

module mode_select ( bl_0, bl_1, bl, rst_0, rst_1, rst, dc_0, dc_1, dc, cs_0, cs_1, cs, din_0, din_1, din, select );
    input bl_0, bl_1;
    output bl;
    input rst_0, rst_1;
    output rst;
    input dc_0, dc_1;
    output dc;
    input cs_0, cs_1;
    output cs;
    input din_0, din_1;
    output din;
    input select;
    
    assign bl = (bl_0 & ~select) | (bl_1 & select);
    assign rst = (rst_0 & ~select) | (rst_1 & select);
    assign dc = (dc_0 & ~select) | (dc_1 & select);
    assign cs = (cs_0 & ~select) | (cs_1 & select);
    assign din = (din_0 & ~select) | (din_1 & select);
endmodule

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din
, debug_ram_out_addr, debug_ram_out
, debug_data, debug_addr );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;
    
    //output [9:0] debug_ram_addr;
    output [3:0] debug_ram_out_addr;
    output [7:0] debug_ram_out;
    
    output [31:0] debug_data;
    output [7:0] debug_addr;

    // Half the clock rate
    wire sysclk_div;
    clk_half_divider clk_half ( 
        .clk_in(sysclk),
        .clk_out(sysclk_div)
    );
    
    wire init_bl;
    wire init_rst;
    wire init_dc;
    wire init_din;
    wire init_cs;
    wire system_ready;
    ili9341_initialiser init_unit (
        .clk(sysclk_div),
        .bl(init_bl),
        .rst(init_rst),
        .dc(init_dc),
        .cs(init_cs),
        .din(init_din),
        .ready(system_ready),
        .debug_ram_out(debug_ram_out),
        .debug_ram_out_addr(debug_ram_out_addr)
    );
    
    wire display_bl;
    wire display_rst;
    wire display_dc;
    wire display_din;
    wire display_cs;
    ili9341_pixel_raster display_unit (
        .start(system_ready),
        .clk(sysclk_div),
        .bl(display_bl),
        .rst(display_rst),
        .dc(display_dc),
        .cs(display_cs),
        .din(display_din),
        .debug_data(debug_data),
        .debug_addr(debug_addr)
    );
    
    wire bl;
    wire rst;
    wire dc;
    wire din;
    wire cs;
    mode_select selector (
        .bl_0(init_bl),
        .bl_1(display_bl),
        .bl(bl),
        .rst_0(init_rst),
        .rst_1(display_rst),
        .rst(rst),
        .dc_0(init_dc),
        .dc_1(display_dc),
        .dc(dc),
        .din_0(init_din),
        .din_1(display_din),
        .din(din),
        .cs_0(init_cs),
        .cs_1(display_cs),
        .cs(cs),
        .select(system_ready)
    );
    
    assign tft_bl = bl;
    assign tft_rst = rst;
    assign tft_dc = dc;
    assign tft_cs = cs;
    assign tft_clk = sysclk_div;
    assign tft_din = din;

endmodule
