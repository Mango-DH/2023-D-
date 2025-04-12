//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Thu Apr 10 03:09:17 2025
//Host        : GL_PC running 64-bit major release  (build 9200)
//Command     : generate_target dds_wrapper.bd
//Design      : dds_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module dds_wrapper
   (aclk_0,
    am_wave_signed_8bit,
    sin_1k,
    sin_2m);
  input aclk_0;
  output [7:0]am_wave_signed_8bit;
  output [15:0]sin_1k;
  output [15:0]sin_2m;

  wire aclk_0;
  wire [7:0]am_wave_signed_8bit;
  wire [15:0]sin_1k;
  wire [15:0]sin_2m;

  dds dds_i
       (.aclk_0(aclk_0),
        .am_wave_signed_8bit(am_wave_signed_8bit),
        .sin_1k(sin_1k),
        .sin_2m(sin_2m));
endmodule
