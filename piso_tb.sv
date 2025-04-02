`timescale 1ns / 1ns
// Author: Dylan Boland
//
// Module: Testbench for the PISO module.
// The PISO module acts as a Parallel-In-Serial-Out (PISO) interface.

module PISO_tb; // an empty port list

	// ==== Define the testbench stimulus signals - these connect to the device under test (dut) ====
	localparam PKT_SIZE = 8;
	logic clk;
	logic rst_n;
	logic [PKT_SIZE-1:0] tx_pkt; // the data to be transmitted
	logic valid_in;
	logic tx_bit;
	logic valid_out;
	logic busy;
	logic [PKT_SIZE-1:0] expected_data;

	// ==== Some Variables used for Checking Purposes ====
	integer pass_count = 0;
	integer error_count = 0;

	// ==== Instantiate the Design Under Test (DUT) ====
	PISO # (.DATA_WIDTH(PKT_SIZE)) dut
		(
		// ==== Inputs ====
		.clk(clk),
		.rst_n(rst_n),
		.data_in(tx_pkt),
		.valid_in(valid_in),
		// ==== Outputs ====
		.data_out(data_out),
		.valid_out(valid_out),
		.busy(busy)
		);

	// ==== Generate the Clock (clk) Signal ====
	// 50 MHz clock should have a period of 20 ns, meaning the value
	// should change every 10 ns:
	initial
		begin
			clk = 1'b0; // clk starts at 0
			forever
				#10 clk = ~clk; // invert clk's value every 10 ns
		end

	// ==== Tasks & Functions ====
	//
	// Task to reset the module:
	task reset;
		begin
			@(posedge clk);
			#1;
			// The reset is active-low, so we need
			// to deassert it to 'activate'
			// the signal and reset the design:
			rst_n = 1'b0;
			// We make the reset high again *just after*
			// (e.g., one time unit) the clock edge
			@(posedge clk);
			#1;
			rst_n = 1'b1;
		end
	endtask

	// Task to start a transaction:
	task send_packet (input [PKT_SIZE-1:0] data);
		begin
			@(posedge clk);
			if (!busy) begin
				#1;
				valid_in = 1'b1;
				tx_pkt = data;
				@(posedge clk);
				#1;
				valid_in = 1'b0;
				tx_pkt = {PKT_SIZE{1'b0}};
			end else begin
				// Otherwise, the PISO module is busy sending
				// another packet. Wait until it's done (i.e., not busy) and
				// then start the next transfer:
				wait (!busy)
				#1;
				valid_in = 1'b1;
				tx_pkt = data;
				@(posedge clk);
				#1;
				valid_in = 1'b0;
				tx_pkt = {PKT_SIZE{1'b0}};
			end
		end
	endtask

	// ==== TODO: Add the Output-Checking Logic Here ====

	// ==== Drive the Signals to the DUT ====
	initial
		begin
			// Note: we only impose initial values on the input
			// signals to the dut, not output signals
			rst_n = 1'b1;
			valid_in = 1'b0;
			tx_pkt = {PKT_SIZE{1'b0}};

			// (1) Reset the design:
			reset();

			// (2) Wait some number of clock
			// cycles (e.g., 3) before sending the first packet:
			repeat (3) begin
				@(posedge clk);
			end

			// (3) Send some packets:
			send_packet(PKT_SIZE'(16));
			send_packet(PKT_SIZE'(128));
			send_packet(PKT_SIZE'(7));
			send_packet(PKT_SIZE'(25));

			// (4) Wait some time before stopping the 
			// simulation - say, 10 clock cycles:
			repeat (10) begin
				@(posedge clk);
			end
			$stop;
		end
	
	// ==== Get the Waves ====
	initial
		begin
			$dumpfile("dump.vcd");
			$dumpvars(2);
		end

endmodule