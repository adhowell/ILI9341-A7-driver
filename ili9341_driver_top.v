`timescale 1ns / 1ps

module clk_half_divider ( clk_in, clk_out );
    input clk_in;
    output clk_out;
    
    reg clk_out_reg = 1'b0;
    assign clk_out = clk_out_reg;
    
    always @ (posedge clk_in)
        clk_out_reg <= clk_out_reg + 1;
endmodule

module ili9341_driver_top( sysclk, btn, tft_bl, tft_rst, tft_dc, tft_cs, tft_clk, tft_din); //, debug_ram_addr, debug_ram_out_addr, debug_ram_out );
    input sysclk;
    input [1:0] btn;
    output tft_bl;
    output tft_rst;
    output tft_dc;
    output tft_cs;
    output tft_clk;
    output tft_din;
    
    //output [9:0] debug_ram_addr;
    //output [3:0] debug_ram_out_addr;
    //output [7:0] debug_ram_out;

    // Half the clock rate
    wire sysclk_div;
    clk_half_divider clk_half ( 
        .clk_in(sysclk),
        .clk_out(sysclk_div)
    );

    reg int_rst = 1'b1;
    reg int_dc = 1'b0;
    reg int_din = 1'b0;
    reg int_cs = 1'b1;
    reg system_ready = 1'b0;
    
    // State machines
    reg [9:0] ram_addr = 10'b0;
    reg [2:0] ram_out_addr = 3'b111;
    wire [7:0] ram_out;
    localparam DECISION = 2'b00, WRITE = 2'b01, NORM = 2'b10, WAIT = 2'b11;
    localparam LS_COMMAND = 2'b00, LS_DATA = 2'b01, LS_IDLE = 2'b10;
    reg [1:0] state = DECISION;
    reg [1:0] ls = LS_IDLE;
    reg [7:0] num_commands = 8'b0;
    
    // ROM loaded with init_commands.coe
    dist_mem_gen_0 init_ram (
        .a(ram_addr),
        .spo(ram_out)
    );

    reg [19:0] wait_counter = 20'b0;
    
    assign tft_bl = btn[0];
    assign tft_rst = int_rst;
    assign tft_dc = int_dc;
    assign tft_cs = int_cs;
    assign tft_clk = sysclk_div;
    assign tft_din = int_din;
    
    //assign debug_ram_addr = ram_addr;
    //assign debug_ram_out_addr = ram_out_addr;
    //assign debug_ram_out = ram_out;

    always @ (negedge sysclk_div)
    begin            
        case (state)
        DECISION:
        begin
            int_cs <= 1'b1;
            
            case (ls)
            LS_IDLE:
            begin
            if (ram_addr == 112)
            begin
                state <= NORM;
                int_dc <= 1'b1;
            end
            else
            begin
                state <= WRITE;
                ls <= LS_COMMAND;
                int_dc <= 1'b0;
            end
            end
            LS_COMMAND:
            begin
                if (ram_out == 8'b10000000)
                begin
                    state <= WAIT;
                    ls <= LS_IDLE;
                    ram_addr <= ram_addr + 1;
                end
                else
                begin
                    state <= WRITE;
                    ls <= LS_DATA;
                    num_commands <= ram_out;
                    ram_addr <= ram_addr + 1;
                    int_dc <= 1'b1;
                end
            end
            LS_DATA:
            begin
                if (num_commands > 1)
                begin
                    num_commands <= num_commands - 1;
                    state <= WRITE;
                end
                else
                begin
                    state <= DECISION;
                    ls <= LS_IDLE;
                end
            end
            endcase
        end
        WRITE:
        begin
            int_cs <= 1'b0;
            
            if (ram_out_addr == 3'b0)
            begin
                ram_out_addr <= 3'b111;
                ram_addr <= ram_addr + 1;
                state <= DECISION;
            end
            else
                ram_out_addr <= ram_out_addr - 1;
                
            int_din <= ram_out[ram_out_addr];
        end
        WAIT:
        begin
            int_cs <= 1'b1;
            
            // 150ms wait desired so 900,000 cycles for 6MHz clock
            if (wait_counter == 900000)
            begin
                wait_counter = 20'b0;
                state <= DECISION;
            end
            else
                wait_counter <= wait_counter + 1;
        end
        NORM:
        begin
            int_cs <= 1'b1;
            system_ready <= 1'b1;
        end
        endcase
    end
endmodule
