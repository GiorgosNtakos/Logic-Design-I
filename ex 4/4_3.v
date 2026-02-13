// 4_3.v
`timescale 1ns/1ps

module dec2_2_4_struct(input E, input S1, input S0, output O0, output O1, output O2, output O3);
  wire S0n, S1n;
  not (S0n, S0);
  not (S1n, S1);
  and (O0, E, S1n, S0n);
  and (O1, E, S1n, S0);
  and (O2, E, S1,  S0n);
  and (O3, E, S1,  S0);
endmodule

module dec2_2_4_equat(input E, input S1, input S0, output O0, output O1, output O2, output O3);
  assign O0 = E & ~S1 & ~S0;
  assign O1 = E & ~S1 &  S0;
  assign O2 = E &  S1 & ~S0;
  assign O3 = E &  S1 &  S0;
endmodule

module dec2_2_4_beh(input E, input S1, input S0, output reg O0, output reg O1, output reg O2, output reg O3);
  always @(*) begin
    {O3,O2,O1,O0} = 4'b0000;
    if (E) begin
      case ({S1,S0})
        2'b00: {O3,O2,O1,O0} = 4'b0001;
        2'b01: {O3,O2,O1,O0} = 4'b0010;
        2'b10: {O3,O2,O1,O0} = 4'b0100;
        2'b11: {O3,O2,O1,O0} = 4'b1000;
      endcase
    end
  end
endmodule

module test_all_dec;
  reg S1, S0, E;
  wire O0_1, O1_1, O2_1, O3_1;
  wire O0_2, O1_2, O2_2, O3_2;
  wire O0_3, O1_3, O2_3, O3_3;

  dec2_2_4_struct m0 (E, S1, S0, O0_1, O1_1, O2_1, O3_1);
  dec2_2_4_equat  m1 (E, S1, S0, O0_2, O1_2, O2_2, O3_2);
  dec2_2_4_beh    m2 (E, S1, S0, O0_3, O1_3, O2_3, O3_3);

  initial begin E=0; S1=0; S0=0; end
  initial begin
    #100 S0 = 1;
    #100 S1 = 1;
    #100 S0 = 0;
    #100 E  = 1;
    #100 S1 = 0;
    #100 S0 = 1;
    #100 S1 = 1;
    #100 $stop;
  end
endmodule
