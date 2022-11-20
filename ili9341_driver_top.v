`timescale 1ns / 1ps

module clk_half_divider ( clk_in, clk_out );
    input clk_in;
    output clk_out;
    
    reg int_clk = 1'b0;
    reg clk_out_reg = 1'b0;
    assign clk_out = clk_out_reg;
    
    always @ (posedge clk_in)
    begin
        int_clk <= ~int_clk;
        if (int_clk == 1'b1)
        begin
            clk_out_reg <= 1'b0;
        end
        else
            clk_out_reg <= 1'b1;
    end
endmodule

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;

    // Half the clock rate
    wire sysclk_div;
    clk_half_divider clk_half ( 
        .clk_in(sysclk),
        .clk_out(sysclk_div)
    );

    reg int_rst = 1'b0;
    reg int_dc = 1'b0;
    reg int_din = 1'b0;

    reg [15:0] data_out_reg = 16'b0;
    reg [3:0] ptr = 4'b0;
    
    // Initial state 
    reg [9:0] ram_ptr = 10'b0;
    reg [2:0] ram_out_ptr = 3'b0;
    wire [7:0] ram_out;
    localparam INIT = 1'b0, NORM = 1'b1;
    reg state = INIT;
    // Loaded with init_commands.coe
    dist_mem_gen_0 init_ram (
        .a(ram_ptr),
        .spo(ram_out)
    );
    
    assign tft_bl = btn[0];
    assign tft_rst = int_rst;
    assign tft_dc = int_dc;
    assign tft_cs = 1'b0;
    assign tft_clk = sysclk_div;
    assign tft_din = int_din;

    always @ (posedge sysclk_div)
    begin            
        case (state)
        INIT:
        begin
            int_dc <= 1'b1;
            int_rst <= 1'b1;
            
            if (ram_out_ptr == 3'b100)
            begin
                ram_out_ptr <= 3'b0;
                ram_ptr <= ram_ptr + 8;
                if (ram_ptr == 880)
                    state <= NORM;
            end
            else
                ram_out_ptr <= ram_out_ptr + 1;

            int_din <= ram_out[ram_out_ptr];
        end
        NORM:
        begin
            int_dc <= 1'b0;
            int_rst <= 1'b1;
            
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
