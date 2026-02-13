// 2_1.v
`timescale 1ns/1ps

module myand(input A, input B, output C);
  and (C, A, B);
endmodule

module myand_test;
  reg X, Y;
  wire Z;

  myand dut (X, Y, Z);

  initial begin
    X=0; Y=0;
    #100 X=0; Y=1;
    #100 X=1; Y=0;
    #100 X=1; Y=1;
    #100 $stop;
  end
endmodule
