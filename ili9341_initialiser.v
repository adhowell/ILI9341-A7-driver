`timescale 1ns / 1ps

module ili9341_initialiser( clk, bl, rst, dc, cs, din, ready
, debug_ram_out, debug_ram_out_addr );
    input clk;
    output bl;
    output rst;
    output dc;
    output cs;
    output din;
    output ready;
    
    output [9:0] debug_ram_out;
    output [2:0] debug_ram_out_addr;

    reg int_rst = 1'b1;
    reg int_dc = 1'bx;
    reg int_din = 1'bx;
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
    
    assign bl = 1'b0;
    assign rst = int_rst;
    assign dc = int_dc;
    assign cs = int_cs;
    assign din = int_din;
    assign ready = system_ready;
    
    assign debug_ram_out = ram_out;
    assign debug_ram_out_addr = ram_out_addr;

    always @ (negedge clk)
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
