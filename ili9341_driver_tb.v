`timescale 1ns / 1ps

module ili9341_driver_tb;

reg sysclk_i = 1'b0;
reg [1:0] btn_i = 2'b0;

wire tft_bl_o;
wire tft_rst_o;
wire tft_dc_o;
wire tft_cs_o;
wire tft_clk_o;
wire tft_din_o;

wire [9:0] debug_ram_ptr;
wire [2:0] debug_ram_out_ptr;
wire [7:0] debug_ram_out;

ili9341_driver_top UUT ( 
    .sysclk(sysclk_i), 
    .btn(btn_i), 
    .tft_bl(tft_bl_o), 
    .tft_rst(tft_rst_o), 
    .tft_dc(tft_dc_o),
    .tft_cs(tft_cs_o), 
    .tft_clk(tft_clk_o), 
    .tft_din(tft_din_o),
    .debug_ram_ptr(debug_ram_ptr),
    .debug_ram_out_ptr(debug_ram_out_ptr),
    .debug_ram_out(debug_ram_out)
);

initial begin
#100;

repeat (10000000)
begin
    #10
    sysclk_i = ~sysclk_i;
end

end
endmodule
