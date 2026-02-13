// 5_2.v
`timescale 1ns/1ps

module decoder2_2_4(input S1,input S0,output O0,output O1,output O2,output O3);
  assign O0 = ~S1 & ~S0;
  assign O1 = ~S1 &  S0;
  assign O2 =  S1 & ~S0;
  assign O3 =  S1 &  S0;
endmodule

module mux4_2_1_decoder_based(input A,B,C,D,input S,T,output O);
  wire D0,D1,D2,D3;
  wire P1,P2,P3,P4;
  decoder2_2_4 dec (S,T,D0,D1,D2,D3);
  and (P1, D0, A);
  and (P2, D1, B);
  and (P3, D2, C);
  and (P4, D3, D);
  or  (O, P1,P2,P3,P4);
endmodule

module testhier;
  reg A,B,C,D;
  reg S,T;
  wire O;

  mux4_2_1_decoder_based dut (A,B,C,D,S,T,O);

  initial begin A=0;B=0;C=0;D=0;S=0;T=0; end
  always #20  A=~A;
  always #40  B=~B;
  always #80  C=~C;
  always #160 D=~D;

  always #1000 T=~T;
  always #2000 S=~S;
endmodule
