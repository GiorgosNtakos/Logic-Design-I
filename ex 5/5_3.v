// 5_3.v
`timescale 1ns/1ps

module mux2_2_1_behavioral(input I0,input I1,input S0,output F);
  assign F = (~S0) ? I0 : I1;
endmodule

module mux4_2_1_behavioral(input I0,input I1,input I2,input I3,input S1,input S0,output F);
  assign F = (~S1) ? ((~S0)?I0:I1) : ((~S0)?I2:I3);
endmodule

module mux8_2_1_beh(input [7:0] I,input [2:0] S,output reg O);
  always @(*) begin
    case (S)
      0: O=I[0]; 1: O=I[1]; 2: O=I[2]; 3: O=I[3];
      4: O=I[4]; 5: O=I[5]; 6: O=I[6]; 7: O=I[7];
    endcase
  end
endmodule

module mux8_2_1_mixed(input [7:0] I,input [2:0] S,output O);
  wire F0,F1;
  mux4_2_1_behavioral m0(I[0],I[1],I[2],I[3],S[1],S[0],F0);
  mux4_2_1_behavioral m1(I[4],I[5],I[6],I[7],S[1],S[0],F1);
  assign O = S[2] ? F1 : F0;
endmodule

module mux8_2_1_struct(input [7:0] I,input [2:0] S,output O);
  wire even_odd_0, even_odd_1, even_odd_2, even_odd_3;
  wire can_0, can_1;

  mux2_2_1_behavioral c0 (I[0], I[1], S[0], even_odd_0);
  mux2_2_1_behavioral c1 (I[2], I[3], S[0], even_odd_1);
  mux2_2_1_behavioral c2 (I[4], I[5], S[0], even_odd_2);
  mux2_2_1_behavioral c3 (I[6], I[7], S[0], even_odd_3);

  mux2_2_1_behavioral c4 (even_odd_0, even_odd_1, S[1], can_0);
  mux2_2_1_behavioral c5 (even_odd_2, even_odd_3, S[1], can_1);

  mux2_2_1_behavioral c6 (can_0, can_1, S[2], O);
endmodule

module decoder2_2_4 (input S1,input S0,output O0,output O1,output O2,output O3);
  assign O0 = ~S1 & ~S0;
  assign O1 = ~S1 &  S0;
  assign O2 =  S1 & ~S0;
  assign O3 =  S1 &  S0;
endmodule

module mux4_2_1_decoder_based(input A,B,C,D,input S,input T,output O);
  wire D0,D1,D2,D3;
  wire P1,P2,P3,P4;
  decoder2_2_4 dec (S,T,D0,D1,D2,D3);
  and (P1, D0, A);
  and (P2, D1, B);
  and (P3, D2, C);
  and (P4, D3, D);
  or  (O, P1,P2,P3,P4);
endmodule

module mux8_2_1_too_many_levels(input [7:0] I,input [2:0] S,output O);
  wire F0,F1;
  mux4_2_1_decoder_based m0 (I[0],I[1],I[2],I[3],S[1],S[0],F0);
  mux4_2_1_decoder_based m1 (I[4],I[5],I[6],I[7],S[1],S[0],F1);
  mux2_2_1_behavioral    m2 (F0, F1, S[2], O);
endmodule

module test_them_all;
  reg  [7:0] DataSource;
  reg  [2:0] Select;
  wire O1,O2,O3,O4;

  mux8_2_1_beh             CUT1 (DataSource, Select, O1);
  mux8_2_1_mixed           CUT2 (DataSource, Select, O2);
  mux8_2_1_struct          CUT3 (DataSource, Select, O3);
  mux8_2_1_too_many_levels CUT4 (DataSource, Select, O4);

  initial begin DataSource=0; Select=0; end
  always  #10   DataSource = DataSource + 1;
  always #2000  Select     = Select + 1;

  always #5 if ((O1!=O2) | (O1!=O3) | (O1!=O4) | (O2!=O3) | (O2!=O4) | (O3!=O4)) $stop();
endmodule
