// 3_2.v
`timescale 1ns/1ps

module circuit3_2(input A, input B, input C, output Z);
  wire K, L;
  and  (K, A, B);
  nand (L, B, C);
  xor  (Z, K, L);
endmodule

module circuit3_2_test;
  reg A, B, C;
  wire Z;

  circuit3_2 dut(A,B,C,Z);

  initial begin
    A=0; B=0; C=0;
    #100 A=0; B=0; C=1;
    #100 A=0; B=1; C=0;
    #100 A=0; B=1; C=1;
    #100 A=1; B=0; C=0;
    #100 A=1; B=0; C=1;
    #100 A=1; B=1; C=0;
    #100 A=1; B=1; C=1;
    #100 $stop;
  end
endmodule
