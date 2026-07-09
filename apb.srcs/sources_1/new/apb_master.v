`timescale 1ns / 1ps

module apb_master (
    input wire pclk,
    input wire presetn,
    
    // --- Frontend: System/Testbench Interface ---
    input wire transfer_req,        // High to start a transaction
    input wire [31:0] tb_paddr,     // Address from TB
    input wire [31:0] tb_pwdata,    // Data to write from TB
    input wire tb_pwrite,           // 1 for Write, 0 for Read
    output reg ready_for_next,      // Master tells TB: "I am ready for a new command"
    output reg [31:0] tb_prdata,    // Master gives read data back to TB
    
    // --- Backend: Standard APB Interface ---
    output reg psel,
    output reg penable,
    output reg pwrite,
    output reg [31:0] paddr,
    output reg [31:0] pwdata,
    input wire pready,
    input wire [31:0] prdata
);

    reg [1:0] current_state;
    
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;
    
    always @(posedge pclk or negedge presetn) begin 
        if (!presetn) begin
            current_state  <= IDLE;
            paddr          <= 32'b0;
            pwdata         <= 32'b0;
            pwrite         <= 1'b0;
            psel           <= 1'b0;
            penable        <= 1'b0;
            ready_for_next <= 1'b1;
            tb_prdata      <= 32'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    penable <= 1'b0;
                    ready_for_next <= 1'b1;
                    
                    if (transfer_req) begin
                        current_state  <= SETUP;
                        ready_for_next <= 1'b0; // Busy now
                        paddr          <= tb_paddr;
                        pwdata         <= tb_pwdata;
                        pwrite         <= tb_pwrite;
                        psel           <= 1'b1; // Wake up slave
                    end else begin
                        psel <= 1'b0;
                    end
                end
                
                SETUP: begin
                    current_state <= ACCESS;
                    penable       <= 1'b1; // Start access phase
                end
                
                ACCESS: begin
                    if (pready) begin
                        // Transfer successful
                        if (!pwrite) begin
                            tb_prdata <= prdata; // Pass read data to frontend
                        end
                        
                        if (transfer_req) begin
                            // Back-to-back transfer
                            current_state <= SETUP;
                            penable       <= 1'b0;
                            paddr         <= tb_paddr;
                            pwdata        <= tb_pwdata;
                            pwrite        <= tb_pwrite;
                        end else begin
                            // Go back to sleep
                            current_state  <= IDLE;
                            psel           <= 1'b0;
                            penable        <= 1'b0;
                            ready_for_next <= 1'b1;
                        end
                    end else begin
                        // Slave is stalling (pready == 0), wait here
                        current_state <= ACCESS;
                    end
                end
                
                default: current_state <= IDLE;
            endcase
        end
    end
endmodule