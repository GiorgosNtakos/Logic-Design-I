// 5_1.v
`timescale 1ns/1ps

module mux4_2_1_struct(input A,B,C,D,input S,T,output O);
  wire nS, nT;
  not (nS,S); not(nT,T);
  wire p1,p2,p3,p4;
  and (p1, nS, nT, A);
  and (p2, nS,  T, B);
  and (p3,  S, nT, C);
  and (p4,  S,  T, D);
  or  (O, p1,p2,p3,p4);
endmodule

module mux4_2_1_equations(input A,B,C,D,input S,T,output O);
  assign O = (~S) ? ((~T)?A:B) : ((~T)?C:D);
endmodule

module mux4_2_1_behavioral(input A,B,C,D,input S,T,output reg O);
  always @(*) begin
    case ({S,T})
      2'b00: O=A;
      2'b01: O=B;
      2'b10: O=C;
      2'b11: O=D;
    endcase
  end
endmodule

module testall;
  reg A,B,C,D;
  reg S,T;
  wire O1,O2,O3;

  mux4_2_1_struct     i0 (A,B,C,D,S,T,O1);
  mux4_2_1_equations  i1 (A,B,C,D,S,T,O2);
  mux4_2_1_behavioral i2 (A,B,C,D,S,T,O3);

  initial begin A=0;B=0;C=0;D=0;S=0;T=0; end
  always #20  A=~A;
  always #40  B=~B;
  always #80  C=~C;
  always #160 D=~D;

  always #1000 T=~T;
  always #2000 S=~S;
endmodule
