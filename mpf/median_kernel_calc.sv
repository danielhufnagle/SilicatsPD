import pixel_pkg::*;

module median_kernel_calc (
    input  pixel_t kernel_i[KERNEL_LEN][KERNEL_LEN],
    output pixel_t pixel_o
);

  always_comb begin
    pixel_o.red = find_median_channel(
      kernel_i[0][0].red,
      kernel_i[0][1].red,
      kernel_i[1][0].red,
      kernel_i[1][1].red
    );

    pixel_o.green = find_median_channel(
      kernel_i[0][0].green,
      kernel_i[0][1].green,
      kernel_i[1][0].green,
      kernel_i[1][1].green
    );

    pixel_o.blue = find_median_channel(
      kernel_i[0][0].blue,
      kernel_i[0][1].blue,
      kernel_i[1][0].blue,
      kernel_i[1][1].blue
    );
  end

endmodule
