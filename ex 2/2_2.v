// 2_2.v
`timescale 1ns/1ps

module myor(input A, input B, output C);
  or (C, A, B);
endmodule

module myor_test;
  reg X, Y;
  wire Z;

  myor dut (X, Y, Z);

  initial begin
    X=0; Y=0;
    #100 X=0; Y=1;
    #100 X=1; Y=0;
    #100 X=1; Y=1;
    #100 $stop;
  end
endmodule
