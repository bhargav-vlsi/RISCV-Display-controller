

// 
// Module: tb
// 
// Notes:
// - Top level simulation testbench.
//

//`timescale 1ns/1ns
//`define WAVES_FILE "./work/waves-rx.vcd"

module tb();
    
reg        clk          ; // Top level system clock input.
reg rst;
reg neg_clk; 
reg neg_rst ; 
reg        resetn       ;
reg        uart_rxd     ; // UART Recieve pin.

reg        uart_rx_en   ; // Recieve enable
//wire [8:0] res;
wire       uart_rx_break; // Did we get a BREAK message?
wire       uart_rx_valid; // Valid data recieved and available.
wire [7:0] uart_rx_data ; // The recieved data.
wire [31:0] inst ; 
wire [31:0] inst_mem ; 

reg rst_pin ; 
wire write_done ; 


// Bit rate of the UART line we are testing.
localparam BIT_RATE = 9600;
localparam BIT_P    = (1000000000/BIT_RATE);


// Period and frequency of the system clock.
localparam CLK_HZ   = 50000000;
localparam CLK_P    = 1000000000/ CLK_HZ;

reg slow_clk = 0;


// Make the clock tick.
always begin #(CLK_P/2) clk  = ~clk; end   
always begin #(CLK_P/2) neg_clk  = ~neg_clk; end     
always begin #(CLK_P*2) slow_clk <= !slow_clk;end



task write_instruction;
    input [31:0] instruction;
    begin
            @(posedge clk);
            send_byte(instruction[7:0]);
            check_byte(instruction[7:0]);
            @(posedge clk);
            send_byte(instruction[15:8]);
            check_byte(instruction[15:8]);
            
            @(posedge clk);
            send_byte(instruction[23:16]);
            check_byte(instruction[23:16]);
            
            @(posedge clk);
            send_byte(instruction[31:24]);
            check_byte(instruction[31:24]);
    end
    endtask

task send_byte;
    input [7:0] to_send;
    integer i;
    begin


        #BIT_P;  uart_rxd = 1'b0;
        for(i=0; i < 8; i = i+1) begin
            #BIT_P;  uart_rxd = to_send[i];
        end
        #BIT_P;  uart_rxd = 1'b1;
        #1000;
    end
endtask


// Checks that the output of the UART is the value we expect.
integer passes = 0;
integer fails  = 0;
task check_byte;
    input [7:0] expected_value;
    begin
        if(uart_rx_data == expected_value) begin
            passes = passes + 1;
            $display("%d/%d/%d [PASS] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end else begin
            fails  = fails  + 1;
            $display("%d/%d/%d [FAIL] Expected %b and got %b", 
                     passes,fails,passes+fails,
                     expected_value, uart_rx_data);
        end
    end
endtask


initial 
begin 
    $dumpfile("waveform.vcd");
    $dumpvars(0,tb);
end 

wire [3:0] keypad_row;
reg [3:0] keypad_col;
reg input_display,next,delay;
wire mode_led;
wire [6:0]display;
wire [2:0] pc ; 


reg [7:0] to_send;
initial begin
    delay=1;
    rst=1;
    rst_pin=1; 
    neg_rst = 1; 
    resetn  = 1'b0;
    clk     = 1'b0;
    neg_clk = 1; 
    neg_rst = ~clk ;
    uart_rxd = 1'b1;
    neg_clk = 1'b1; 
     #4000
    resetn = 1'b1;
    rst=0;
    neg_rst = 0; 
    rst_pin = 0 ; 
    #300
    input_display=1;
    next=0;
    
    
   
 
    
  

    uart_rx_en = 1'b1;
    /*@(posedge slow_clk);write_instruction(32'h00000000); 
    @(posedge slow_clk);write_instruction(32'h00000000); 
    @(posedge slow_clk);write_instruction(32'hfb010113); 
    @(posedge slow_clk);write_instruction(32'h04112623); 
    @(posedge slow_clk);write_instruction(32'h04812423); 
    @(posedge slow_clk);write_instruction(32'h05010413); 
    @(posedge slow_clk);write_instruction(32'hfe042423); 
    @(posedge slow_clk);write_instruction(32'hfe042223); 
    @(posedge slow_clk);write_instruction(32'hfe042023); 
    @(posedge slow_clk);write_instruction(32'hfc042e23); 
    @(posedge slow_clk);write_instruction(32'hfc042c23); 
    @(posedge slow_clk);write_instruction(32'hfc042a23); 
    @(posedge slow_clk);write_instruction(32'hfc042823); 
    @(posedge slow_clk);write_instruction(32'hfc042623); 
    @(posedge slow_clk);write_instruction(32'hfc042423); 
    @(posedge slow_clk);write_instruction(32'hfc042223); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'hf0000793); 
    @(posedge slow_clk);write_instruction(32'hfaf42e23); 
    @(posedge slow_clk);write_instruction(32'h00100513); 
    @(posedge slow_clk);write_instruction(32'h62c000ef); 
    @(posedge slow_clk);write_instruction(32'h5fc000ef); 
    @(posedge slow_clk);write_instruction(32'hfaa42c23); 
    @(posedge slow_clk);write_instruction(32'hfb842503); 
    @(posedge slow_clk);write_instruction(32'h664000ef); 
    @(posedge slow_clk);write_instruction(32'hfb842703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h14f71c63); 
    @(posedge slow_clk);write_instruction(32'h338000ef); 
    @(posedge slow_clk);write_instruction(32'hfaa42823); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfc078ce3); 
    @(posedge slow_clk);write_instruction(32'hfc042783); 
    @(posedge slow_clk);write_instruction(32'h00079863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'h0ec0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfef42223); 
    @(posedge slow_clk);write_instruction(32'h0d40006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00200793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfef42023); 
    @(posedge slow_clk);write_instruction(32'h0bc0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00300793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42e23); 
    @(posedge slow_clk);write_instruction(32'h0a40006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00400793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42c23); 
    @(posedge slow_clk);write_instruction(32'h08c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00500793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42a23); 
    @(posedge slow_clk);write_instruction(32'h0740006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00600793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42823); 
    @(posedge slow_clk);write_instruction(32'h05c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00700793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42623); 
    @(posedge slow_clk);write_instruction(32'h0440006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00800793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42423); 
    @(posedge slow_clk);write_instruction(32'h02c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00900793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'hfb042783); 
    @(posedge slow_clk);write_instruction(32'hfcf42223); 
    @(posedge slow_clk);write_instruction(32'h0140006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00a00793); 
    @(posedge slow_clk);write_instruction(32'h00f71463); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'hfb042703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h02f70c63); 
    @(posedge slow_clk);write_instruction(32'hfc042783); 
    @(posedge slow_clk);write_instruction(32'h00178793); 
    @(posedge slow_clk);write_instruction(32'hfcf42023); 
    @(posedge slow_clk);write_instruction(32'hfb042503); 
    @(posedge slow_clk);write_instruction(32'h4e4000ef); 
    @(posedge slow_clk);write_instruction(32'h594000ef); 
    @(posedge slow_clk);write_instruction(32'hfea42623); 
    @(posedge slow_clk);write_instruction(32'h00c0006f); 
    @(posedge slow_clk);write_instruction(32'h588000ef); 
    @(posedge slow_clk);write_instruction(32'hfea42623); 
    @(posedge slow_clk);write_instruction(32'hfec42783); 
    @(posedge slow_clk);write_instruction(32'hfe078ae3); 
    @(posedge slow_clk);write_instruction(32'he9dff06f); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'he95ff06f); 
    @(posedge slow_clk);write_instruction(32'hfb842783); 
    @(posedge slow_clk);write_instruction(32'he80796e3); 
    @(posedge slow_clk);write_instruction(32'h538000ef); 
    @(posedge slow_clk);write_instruction(32'hfaa42a23); 
    @(posedge slow_clk);write_instruction(32'hfb442703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'he6f71ce3); 
    @(posedge slow_clk);write_instruction(32'hfc042783); 
    @(posedge slow_clk);write_instruction(32'h02079263); 
    @(posedge slow_clk);write_instruction(32'hfe842703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h1ac0006f); 
    @(posedge slow_clk);write_instruction(32'hfe842503); 
    @(posedge slow_clk);write_instruction(32'h47c000ef); 
    @(posedge slow_clk);write_instruction(32'h1940006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfe442703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h1800006f); 
    @(posedge slow_clk);write_instruction(32'hfe442503); 
    @(posedge slow_clk);write_instruction(32'h450000ef); 
    @(posedge slow_clk);write_instruction(32'h1680006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00200793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfe042703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h1540006f); 
    @(posedge slow_clk);write_instruction(32'hfe042503); 
    @(posedge slow_clk);write_instruction(32'h424000ef); 
    @(posedge slow_clk);write_instruction(32'h13c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00300793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfdc42703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h1280006f); 
    @(posedge slow_clk);write_instruction(32'hfdc42503); 
    @(posedge slow_clk);write_instruction(32'h3f8000ef); 
    @(posedge slow_clk);write_instruction(32'h1100006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00400793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfd842703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0fc0006f); 
    @(posedge slow_clk);write_instruction(32'hfd842503); 
    @(posedge slow_clk);write_instruction(32'h3cc000ef); 
    @(posedge slow_clk);write_instruction(32'h0e40006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00500793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfd442703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0d00006f); 
    @(posedge slow_clk);write_instruction(32'hfd442503); 
    @(posedge slow_clk);write_instruction(32'h3a0000ef); 
    @(posedge slow_clk);write_instruction(32'h0b80006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00600793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfd042703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0a40006f); 
    @(posedge slow_clk);write_instruction(32'hfd042503); 
    @(posedge slow_clk);write_instruction(32'h374000ef); 
    @(posedge slow_clk);write_instruction(32'h08c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00700793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfcc42703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0780006f); 
    @(posedge slow_clk);write_instruction(32'hfcc42503); 
    @(posedge slow_clk);write_instruction(32'h348000ef); 
    @(posedge slow_clk);write_instruction(32'h0600006f); 
    @(posedge slow_clk);write_instruction(32'hfc042783); 
    @(posedge slow_clk);write_instruction(32'h02079263); 
    @(posedge slow_clk);write_instruction(32'hfc842703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0500006f); 
    @(posedge slow_clk);write_instruction(32'hfc842503); 
    @(posedge slow_clk);write_instruction(32'h320000ef); 
    @(posedge slow_clk);write_instruction(32'h0380006f); 
    @(posedge slow_clk);write_instruction(32'hfc042703); 
    @(posedge slow_clk);write_instruction(32'h00800793); 
    @(posedge slow_clk);write_instruction(32'h02f71263); 
    @(posedge slow_clk);write_instruction(32'hfc442703); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0240006f); 
    @(posedge slow_clk);write_instruction(32'hfc442503); 
    @(posedge slow_clk);write_instruction(32'h2f4000ef); 
    @(posedge slow_clk);write_instruction(32'h00c0006f); 
    @(posedge slow_clk);write_instruction(32'hfc042023); 
    @(posedge slow_clk);write_instruction(32'h0100006f); 
    @(posedge slow_clk);write_instruction(32'hfc042783); 
    @(posedge slow_clk);write_instruction(32'h00178793); 
    @(posedge slow_clk);write_instruction(32'hfcf42023); 
    @(posedge slow_clk);write_instruction(32'hcb1ff06f); 
    @(posedge slow_clk);write_instruction(32'hfe010113); 
    @(posedge slow_clk);write_instruction(32'h00812e23); 
    @(posedge slow_clk);write_instruction(32'h02010413); 
    @(posedge slow_clk);write_instruction(32'hfe042423); 
    @(posedge slow_clk);write_instruction(32'hff000793); 
    @(posedge slow_clk);write_instruction(32'hfef42223); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'h02079663); 
    @(posedge slow_clk);write_instruction(32'hfe442783); 
    @(posedge slow_clk);write_instruction(32'h00ff7f33); 
    @(posedge slow_clk);write_instruction(32'h00ef6f13); 
    @(posedge slow_clk);write_instruction(32'h0f0f7793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0f000793); 
    @(posedge slow_clk);write_instruction(32'h00f70663); 
    @(posedge slow_clk);write_instruction(32'h00e00793); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'h02079663); 
    @(posedge slow_clk);write_instruction(32'hfe442783); 
    @(posedge slow_clk);write_instruction(32'h00ff7f33); 
    @(posedge slow_clk);write_instruction(32'h00df6f13); 
    @(posedge slow_clk);write_instruction(32'h0f0f7793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0f000793); 
    @(posedge slow_clk);write_instruction(32'h00f70663); 
    @(posedge slow_clk);write_instruction(32'h00d00793); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'h02079663); 
    @(posedge slow_clk);write_instruction(32'hfe442783); 
    @(posedge slow_clk);write_instruction(32'h00ff7f33); 
    @(posedge slow_clk);write_instruction(32'h00bf6f13); 
    @(posedge slow_clk);write_instruction(32'h0f0f7793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0f000793); 
    @(posedge slow_clk);write_instruction(32'h00f70663); 
    @(posedge slow_clk);write_instruction(32'h00b00793); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'h02079663); 
    @(posedge slow_clk);write_instruction(32'hfe442783); 
    @(posedge slow_clk);write_instruction(32'h00ff7f33); 
    @(posedge slow_clk);write_instruction(32'h007f6f13); 
    @(posedge slow_clk);write_instruction(32'h0f0f7793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0f000793); 
    @(posedge slow_clk);write_instruction(32'h00f70663); 
    @(posedge slow_clk);write_instruction(32'h00700793); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'h00079663); 
    @(posedge slow_clk);write_instruction(32'h00000793); 
    @(posedge slow_clk);write_instruction(32'h1b40006f); 
    @(posedge slow_clk);write_instruction(32'hfe842703); 
    @(posedge slow_clk);write_instruction(32'h00e00793); 
    @(posedge slow_clk);write_instruction(32'h06f71263); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0e000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h03000793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h18c0006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0d000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h06d00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h1740006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0b000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h07900793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h15c0006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h07000793); 
    @(posedge slow_clk);write_instruction(32'h14f71863); 
    @(posedge slow_clk);write_instruction(32'h07700793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h1440006f); 
    @(posedge slow_clk);write_instruction(32'hfe842703); 
    @(posedge slow_clk);write_instruction(32'h00d00793); 
    @(posedge slow_clk);write_instruction(32'h06f71263); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0e000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h03300793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h1200006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0d000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h05b00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h1080006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0b000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h05e00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0f00006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h07000793); 
    @(posedge slow_clk);write_instruction(32'h0ef71263); 
    @(posedge slow_clk);write_instruction(32'h01f00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0d80006f); 
    @(posedge slow_clk);write_instruction(32'hfe842703); 
    @(posedge slow_clk);write_instruction(32'h00b00793); 
    @(posedge slow_clk);write_instruction(32'h06f71263); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0e000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h07000793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0b40006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0d000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h07f00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h09c0006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0b000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h07300793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0840006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h07000793); 
    @(posedge slow_clk);write_instruction(32'h06f71c63); 
    @(posedge slow_clk);write_instruction(32'h04e00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h06c0006f); 
    @(posedge slow_clk);write_instruction(32'hfe842703); 
    @(posedge slow_clk);write_instruction(32'h00700793); 
    @(posedge slow_clk);write_instruction(32'h06f71063); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0e000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0480006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0d000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h07f00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0300006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h0b000793); 
    @(posedge slow_clk);write_instruction(32'h00f71863); 
    @(posedge slow_clk);write_instruction(32'h00100793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'h0180006f); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h07000793); 
    @(posedge slow_clk);write_instruction(32'h00f71663); 
    @(posedge slow_clk);write_instruction(32'h03d00793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42783); 
    @(posedge slow_clk);write_instruction(32'h00078513); 
    @(posedge slow_clk);write_instruction(32'h01c12403); 
    @(posedge slow_clk);write_instruction(32'h02010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hfe010113); 
    @(posedge slow_clk);write_instruction(32'h00812e23); 
    @(posedge slow_clk);write_instruction(32'h02010413); 
    @(posedge slow_clk);write_instruction(32'h01ff5513); 
    @(posedge slow_clk);write_instruction(32'h00157793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42783); 
    @(posedge slow_clk);write_instruction(32'h00078513); 
    @(posedge slow_clk);write_instruction(32'h01c12403); 
    @(posedge slow_clk);write_instruction(32'h02010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hfd010113); 
    @(posedge slow_clk);write_instruction(32'h02812623); 
    @(posedge slow_clk);write_instruction(32'h03010413); 
    @(posedge slow_clk);write_instruction(32'hfca42e23); 
    @(posedge slow_clk);write_instruction(32'hffff87b7); 
    @(posedge slow_clk);write_instruction(32'h0ff78793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfdc42783); 
    @(posedge slow_clk);write_instruction(32'h00879793); 
    @(posedge slow_clk);write_instruction(32'hfef42423); 
    @(posedge slow_clk);write_instruction(32'hfe842783); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h00ef7f33); 
    @(posedge slow_clk);write_instruction(32'h00ff6f33); 
    @(posedge slow_clk);write_instruction(32'h00000013); 
    @(posedge slow_clk);write_instruction(32'h02c12403); 
    @(posedge slow_clk);write_instruction(32'h03010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hfd010113); 
    @(posedge slow_clk);write_instruction(32'h02812623); 
    @(posedge slow_clk);write_instruction(32'h03010413); 
    @(posedge slow_clk);write_instruction(32'hfca42e23); 
    @(posedge slow_clk);write_instruction(32'hfe0007b7); 
    @(posedge slow_clk);write_instruction(32'hfff78793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfdc42783); 
    @(posedge slow_clk);write_instruction(32'hfec42703); 
    @(posedge slow_clk);write_instruction(32'h00ef7f33); 
    @(posedge slow_clk);write_instruction(32'h01979513); 
    @(posedge slow_clk);write_instruction(32'h00af6f33); 
    @(posedge slow_clk);write_instruction(32'h00000013); 
    @(posedge slow_clk);write_instruction(32'h02c12403); 
    @(posedge slow_clk);write_instruction(32'h03010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hfe010113); 
    @(posedge slow_clk);write_instruction(32'h00812e23); 
    @(posedge slow_clk);write_instruction(32'h02010413); 
    @(posedge slow_clk);write_instruction(32'h01df5513); 
    @(posedge slow_clk);write_instruction(32'h00157793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42783); 
    @(posedge slow_clk);write_instruction(32'h00078513); 
    @(posedge slow_clk);write_instruction(32'h01c12403); 
    @(posedge slow_clk);write_instruction(32'h02010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hfe010113); 
    @(posedge slow_clk);write_instruction(32'h00812e23); 
    @(posedge slow_clk);write_instruction(32'h02010413); 
    @(posedge slow_clk);write_instruction(32'h01bf5513); 
    @(posedge slow_clk);write_instruction(32'h00157793); 
    @(posedge slow_clk);write_instruction(32'hfef42623); 
    @(posedge slow_clk);write_instruction(32'hfec42783); 
    @(posedge slow_clk);write_instruction(32'h00078513); 
    @(posedge slow_clk);write_instruction(32'h01c12403); 
    @(posedge slow_clk);write_instruction(32'h02010113); 
    @(posedge slow_clk);write_instruction(32'h00008067); 
    @(posedge slow_clk);write_instruction(32'hffffffff); 
    @(posedge slow_clk);write_instruction(32'hffffffff); */

     $display("Test Results:");
     $display("    PASSES: %d", passes);
     $display("    FAILS : %d", fails);
    #50000
    $display("Finish simulation at time %d", $time);
    $finish;
end



initial
begin
#6030
keypad_col=4'b1110;
#2300
keypad_col=4'b1111;
next=1;
#320
next=0;
end


initial
begin
#9990
keypad_col=4'b1101;
#2300
keypad_col=4'b1111;
#320
next=1;
#250
next=0;
end

initial
begin
#14680
keypad_col=4'b1101;
#2700
keypad_col=4'b1111;
#300
next=1;
#250
next=0;
end

initial
begin
#20400
keypad_col=4'b1110;
#700
keypad_col=4'b1111;
#300
next=1;
#250
next=0;
end

initial
begin
#25430
input_display=0;
end

initial
begin
#23000 
next=1;
end



 wrapper dut (
.clk        (clk          ), // Top level system clock input.
.resetn       (resetn       ), // Asynchronous active low reset.
.uart_rxd     (uart_rxd     ), // UART Recieve pin.
.uart_rx_en   (uart_rx_en   ), // Recieve enable
.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
.uart_rx_data (uart_rx_data ), 
.keypad_row(keypad_row), 
.keypad_col(keypad_col),
.input_display(input_display), 
.next(next),
.delay(delay),
.mode_led(mode_led),
.display(display),
.write_done(write_done)
); 



endmodule
