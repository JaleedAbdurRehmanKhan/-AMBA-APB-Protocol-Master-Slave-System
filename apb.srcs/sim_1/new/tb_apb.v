`timescale 1ns / 1ps

module tb_apb();

    // System Signals
    reg pclk;
    reg presetn;
    
    // Frontend Signals (TB to Master)
    reg transfer_req;
    reg [31:0] tb_paddr;
    reg [31:0] tb_pwdata;
    reg tb_pwrite;
    wire ready_for_next;
    wire [31:0] tb_prdata;
    
    // APB Bus Signals (Master to Slave)
    wire psel;
    wire penable;
    wire pwrite;
    wire [31:0] paddr;
    wire [31:0] pwdata;
    wire pready;
    wire [31:0] prdata;

    // Instantiate Master
    apb_master u_master (
        .pclk(pclk),
        .presetn(presetn),
        .transfer_req(transfer_req),
        .tb_paddr(tb_paddr),
        .tb_pwdata(tb_pwdata),
        .tb_pwrite(tb_pwrite),
        .ready_for_next(ready_for_next),
        .tb_prdata(tb_prdata),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .pready(pready),
        .prdata(prdata)
    );

    // Instantiate Slave
    apb_slave u_slave (
        .pclk(pclk),
        .presetn(presetn),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .pready(pready),
        .prdata(prdata)
    );

    // Clock Generation (100MHz)
    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk; 
    end

    // Stimulus
    initial begin
            // 1. Initialize all inputs
            presetn = 1;          // <--- START IT HIGH
            transfer_req = 0;
            tb_paddr = 0;
            tb_pwdata = 0;
            tb_pwrite = 0;
            
            // 2. Apply Reset
            #5;                  // Wait a few nanoseconds
            presetn = 0;         // <--- NOW DROP IT TO 0 (This triggers the negedge!)
            #20;
            presetn = 1;         // Release reset back to 1
            #20;
        
        // 3. Perform a WRITE transaction
        // Wait until master is ready
        wait(ready_for_next == 1'b1);
        @(posedge pclk);
        transfer_req = 1;
        tb_paddr = 32'h0000_0004; // Address 4
        tb_pwdata = 32'hDEADBEEF; // Data to write
        tb_pwrite = 1;            // 1 = Write
        
        // Wait one clock cycle, then drop the request
        @(posedge pclk);
        transfer_req = 0;
        
        // 4. Wait for the write to finish
        wait(ready_for_next == 1'b1);
        #20;
        
        // 5. Perform a READ transaction from the same address
        @(posedge pclk);
        transfer_req = 1;
        tb_paddr = 32'h0000_0004; // Address 4
        tb_pwrite = 0;            // 0 = Read
        
        @(posedge pclk);
        transfer_req = 0;
        
        // 6. Wait for the read to finish and check data
        wait(ready_for_next == 1'b1);
        #10;
        if (tb_prdata == 32'hDEADBEEF) begin
            $display("SUCCESS: Data matched!");
        end else begin
            $display("FAILED: Expected DEADBEEF, got %h", tb_prdata);
        end
        
        #50;
        $finish;
    end

endmodule