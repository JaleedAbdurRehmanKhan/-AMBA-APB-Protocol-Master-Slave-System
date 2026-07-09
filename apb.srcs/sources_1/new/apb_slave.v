`timescale 1ns / 1ps

module apb_slave #(
    parameter WAIT_STATES = 3
)(
    input wire pclk,
    input wire presetn,
    input wire psel,
    input wire penable,
    input wire pwrite,
    input wire [31:0] paddr,
    input wire [31:0] pwdata,
    output reg pready,
    output reg [31:0] prdata
);

    reg [31:0] mem [0:255];
    reg [3:0] wait_counter;
    
    // --- 1. Wait State Logic ---
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            wait_counter <= 0;
            pready       <= 1'b0; 
        end else begin
            if (psel && !penable) begin
                if (WAIT_STATES > 0) begin
                    wait_counter <= WAIT_STATES;
                    pready       <= 1'b0;
                end else begin
                    wait_counter <= 0;
                    pready       <= 1'b1;
                end
            end else if (psel && penable) begin
                if (wait_counter > 0) begin
                    wait_counter <= wait_counter - 1;
                    if (wait_counter == 1) begin
                        pready <= 1'b1; 
                    end
                end
            end else begin
                wait_counter <= 0;
                pready       <= 1'b0;
            end
        end
    end

   // READ: Combinational logic. 
        // Data is placed on the bus immediately when the Master asks for it.
        always @(*) begin
            if (psel && !pwrite) begin
                prdata = mem[paddr[9:2]];
            end else begin
                prdata = 32'b0;
            end
        end
    
        // WRITE: Sequential logic. 
        // Data is saved at the exact moment the transfer successfully finishes.
        always @(posedge pclk) begin
            if (psel && penable && pready && pwrite) begin
                mem[paddr[9:2]] <= pwdata;
            end
        end
    
    endmodule

