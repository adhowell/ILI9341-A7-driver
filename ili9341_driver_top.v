`timescale 1ns / 1ps

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;
    
    reg int_clk = 1'b0;

    reg int_rst = 1'b0;
    reg int_dc = 1'b0;
    reg int_din = 1'b0;

    reg [15:0] data_out_reg = 16'b0;
    reg [3:0] ptr = 4'b0;
    
    assign tft_bl = btn[0];
    assign tft_rst = int_rst;
    assign tft_dc = int_dc;
    assign tft_cs = 1'b0;
    assign tft_clk = int_clk;
    assign tft_din = int_din;

    always @ (posedge sysclk)
    begin
        if (int_clk == 1'b1)
        begin
            int_clk <= 1'b0;
            int_rst <= 1'b1;
            int_dc <= 1'b1;
            if (ptr == 4'b1)
                ptr <= 4'b0;
            if (data_out_reg == 32'b1)
                data_out_reg <= 32'b0;
            ptr <= ptr + 1'b1;
            data_out_reg <= data_out_reg + 1'b1;
            int_din = data_out_reg[ptr];
        end
        else
            int_clk <= 1'b1;
    end
endmodule
