// Author: Dylan Boland
//
// Module: PISO
// A module that acts as a Parallel-In-Serial-Out (PISO) interface.

module PISO #
	(
	// ==== Parameters ====
	parameter DATA_WIDTH = 8 // the number of bits in a data packet
	)
	(
	// ==== Inputs ====
	input logic clk,
	input logic rst_n,                    // the asynchronous active-low reset signal
	input logic [DATA_WIDTH-1:0] data_in, // the data to be transmitted
	input logic valid_in,                 // when high, it indicates that the data input is valid
	// ==== Outputs ====
	output logic data_out,  // the output data line
	output logic valid_out, // the valid output
	output logic busy       // when high, it indicates that the interface is busy with a transaction
	);

	// ==== Local Parameters ====
	// Suppose each data packet is 8-bits wide. In that case, we
	// need to be able to count from zero to eight. If we were to simply
	// use a 3-bit (i.e., log2(8)) counter, then we would only be able to
	// count from zero to seven (that is, 3'b111). What we would need, though, is
	// a counter than is 1-bit wider so that we can count up to eight (i.e., 4'b1000).
	//
	// Therefore, we will add one to the result of log2(DATA_WIDTH):
	localparam TX_BIT_CNTR_WIDTH = $clog2(DATA_WIDTH) + 1;
	// Since we are sending the data least-significant bit (LSB) first, the
	// LSB of the transmit (TX) register will drive the output data line:
	localparam TX_BIT_POS = 0;
	localparam NUM_BITS_TO_TX = DATA_WIDTH;

	// ==== Internal Signals ====
	logic [DATA_WIDTH-1:0] tx_data; // the data to be transmitted
	logic [TX_BIT_CNTR_WIDTH-1:0] tx_bit_cntr; // a counter to track the number of bits transmitted (sent)
	logic tx_done; // a 'transaction-done' indicator
	logic tx_in_progress; // if high, it indicates that a transaction is in progress

	// ==== Logic for the TX (Transmit) Register ====
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			tx_data <= {DATA_WIDTH{1'b0}};
		end
		else if ((!tx_in_progress) && valid_in) begin
			tx_data <= data_in;
		end
		else if (!tx_done) begin
			// While we are not done, simply shift the data
			// down. The least-significant bit (LSB) of the shift
			// register drives the output data line:
			tx_data <= (tx_data >> 1);
		end
	end

	// ==== Logic for transmit-bit counter ====
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			tx_bit_cntr <= {TX_BIT_CNTR_WIDTH{1'b0}};
		end
		else if ((!tx_in_progress) && valid_in) begin
			tx_bit_cntr <= tx_bit_cntr + 1'b1;
		end
		else if (tx_in_progress && (!tx_done)) begin
			tx_bit_cntr <= tx_bit_cntr + 1'b1;
		end
		else if (tx_done) begin
			tx_bit_cntr <= {TX_BIT_CNTR_WIDTH{1'b0}};
		end
	end

	// ==== Logic for the Transmit-in-Progress Flag ====
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			tx_in_progress <= 1'b0;
		end
		else if (valid_in && (!tx_in_progress)) begin
			tx_in_progress <= 1'b1;
		end
		else if (tx_done) begin
			tx_in_progress <= 1'b0;
		end
	end

	// ==== Logic for the Transmit-Done Flag ====
	assign tx_done = (tx_bit_cntr == NUM_BITS_TO_TX); // this signal will pulse high while the last bit is sent

	// ==== Logic for generating the 'Busy' Flag ====
	assign busy = tx_in_progress;

	// ==== Logic for driving the output data line ====
	assign data_out = tx_data[TX_BIT_POS];

	// ==== Logic for generating the output valid ====
	// While there is a transaction (transmission) in progress, the
	// output data line is valid:
	assign valid_out = tx_in_progress;

endmodule
