import pixel_pkg::*;

module median_filter #(
  parameter int IMAGE_LEN    = 1080,
  parameter int IMAGE_HEIGHT = 720
) (
  input logic clk,
  input logic rst, //synchronous reset high
  input logic start_i, //starting a new frame
  input logic pixel_valid_i, //current input pixel is valid
  input       pixel_t pixel_i, //input pixel data

  output logic done_o, //the whole image is filtered
  output logic pixel_valid_o, //current output pixel is valid
  output       pixel_t pixel_o //output pixel data
);

  // Local parameters
  localparam int X_COUNTER_W = $clog2(IMAGE_LEN);
  localparam int Y_COUNTER_W = $clog2(IMAGE_HEIGHT);
  localparam int SHIFT_REG_W = IMAGE_LEN + KERNEL_LEN - 1;

  // FSM States
  typedef enum logic [1:0] {IDLE, COMPUTE} state_t;
  state_t state_d, state_q;

  // Row/Col Counters
  logic [X_COUNTER_W-1:0] x_counter_d;
  logic [X_COUNTER_W-1:0] x_counter_q;

  logic [Y_COUNTER_W-1:0] y_counter_d;
  logic [Y_COUNTER_W-1:0] y_counter_q;

  // Storage Buffer to hold pixels
  pixel_t                 pixel_shift_reg_d[SHIFT_REG_W];
  pixel_t                 pixel_shift_reg_q[SHIFT_REG_W];
  pixel_t                 kernel           [KERNEL_LEN][KERNEL_LEN];
  pixel_t                 pixel_d;

  // Control Signals
  logic x_inbounds;
  logic y_inbounds;
  logic kernel_valid;

  logic done_d;

  // Always check whether we are inbounds
  always_comb begin
    x_inbounds = x_counter_q != 0;
    y_inbounds = y_counter_q != 0;
  end

  // Always shift in a new pixel if it is valid
  always_comb begin
    pixel_shift_reg_d = pixel_shift_reg_q;

    if (pixel_valid_i) begin
      pixel_shift_reg_d[0] = pixel_i;

      pixel_shift_reg_d[1:SHIFT_REG_W-1] = pixel_shift_reg_q[0:SHIFT_REG_W-2];
    end
  end
  
  // Compute next State
  always_comb begin
    // Default values
    kernel_valid = '0;
    done_d       = '0;
    x_counter_d  = x_counter_q;
    y_counter_d  = y_counter_q;
    state_d      = state_q;

    unique case (state_q)
      IDLE: begin
        x_counter_d = '0;
        y_counter_d = '0;

        if (start_i) begin
          state_d = COMPUTE;
        end
      end

      COMPUTE: begin
        if (pixel_valid_i) begin
          x_counter_d  = x_counter_q + 1;
          kernel_valid = x_inbounds && y_inbounds;

          if (x_counter_q == IMAGE_LEN - 1) begin
            x_counter_d = '0;
            y_counter_d = y_counter_q + 1;

            if (y_counter_q == IMAGE_HEIGHT - 1) begin
              y_counter_d = '0;
              done_d      = 1'b1;
              state_d     = IDLE;
            end
          end
        end
      end
    endcase
  end

  // Mask the kernel to make things easier to read 
  always_comb begin
    kernel[0][0] = pixel_shift_reg_q[SHIFT_REG_W-1];
    kernel[0][1] = pixel_shift_reg_q[SHIFT_REG_W-2];
    kernel[1][0] = pixel_shift_reg_q[0];
    kernel[1][1] = pixel_i;
  end

  // Always compute an output pixel, it dosen't have to be valid
  median_kernel_calc median_kernel_calc_inst(
      .kernel_i(kernel),
      .pixel_o(pixel_d)
  );

  // Clocked Update Block
  always_ff @(posedge clk) begin
    if (rst) begin
      state_q       <= IDLE;
      x_counter_q   <= '0;
      y_counter_q   <= '0;
      done_o        <= '0;
      pixel_valid_o <= '0;
    end else begin
      state_q           <= state_d;
      x_counter_q       <= x_counter_d;
      y_counter_q       <= y_counter_d;
      pixel_shift_reg_q <= pixel_shift_reg_d;
      pixel_o           <= pixel_d;
      done_o            <= done_d;
      pixel_valid_o     <= kernel_valid; // If our kernel is valid, the computed pixel is valid
    end
  end

endmodule
