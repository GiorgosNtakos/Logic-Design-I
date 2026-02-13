`timescale 1ns/1ps

// ============================================================
// (1) Full Adder (FA) with output delays:
//     Sum delay = 80 time units
//     Cout delay = 45 time units
// ============================================================
module FA_delayed (
  input  wire A,
  input  wire B,
  input  wire CIN,
  output wire S,
  output wire COUT
);
  // Sum
  assign #80 S    = A ^ B ^ CIN;

  // Carry out (majority function)
  // Delay requirement is on the output itself (45).
  assign #45 COUT = (A & B) | (A & CIN) | (B & CIN);
endmodule


// ============================================================
// (2) 4-bit ripple-carry adder using FA_delayed
// Inputs:  A[3:0], B[3:0], cin
// Outputs: S[3:0], cout
//
// Delay analysis (worst-case):
//  - carry out (cout): 4 carry stages * 45 = 180
//  - S[0]: 80
//  - S[1]: carry into bit1 max 45, then sum 80 => 125
//  - S[2]: 90 + 80 = 170
//  - S[3]: 135 + 80 = 215
// => Worst-case time for S vector to be fully valid: 215
// ============================================================
module ADD4_ripple (
  input  wire [3:0] A,
  input  wire [3:0] B,
  input  wire       cin,
  output wire [3:0] S,
  output wire       cout
);
  wire c1, c2, c3;

  FA_delayed fa0 (.A(A[0]), .B(B[0]), .CIN(cin), .S(S[0]), .COUT(c1));
  FA_delayed fa1 (.A(A[1]), .B(B[1]), .CIN(c1 ), .S(S[1]), .COUT(c2));
  FA_delayed fa2 (.A(A[2]), .B(B[2]), .CIN(c2 ), .S(S[2]), .COUT(c3));
  FA_delayed fa3 (.A(A[3]), .B(B[3]), .CIN(c3 ), .S(S[3]), .COUT(cout));
endmodule


// ============================================================
// (3) BCD Full Adder (BCD FA)
// Inputs:  D[3:0], E[3:0], c
// Outputs: T[3:0] (BCD digit), r (carry to next BCD digit)
//
// Implementation rules satisfied:
//  - Uses copies of ADD4_ripple
//  - Additional logic ONLY with 2-input gates, each with #10
//
// Steps:
//  1) Binary add: S = D + E + c, cout1
//  2) r = cout1 OR (s3 AND (s2 OR s1))
//  3) Correction: T = S + (r ? 6 : 0)  where 6 = 4'b0110
//
// Delay analysis (worst-case, from inputs/c to outputs):
//  From ADD4_ripple:
//   - cout1 worst ~ 180
//   - s3 worst  ~ 215
//   - s2 worst  ~ 170
//   - s1 worst  ~ 125
//
//  r path:
//   t_or_s2s1  = max(s2,s1) + 10 = max(170,125)+10 = 180
//   t_and      = max(s3, t_or_s2s1) + 10 = max(215,180)+10 = 225
//   r          = max(cout1, t_and) + 10 = max(180,225)+10 = 235
//   => r worst-case ~ 235
//
//  T path (worst-case dominated by r feeding correction adder and ripple inside it):
//   r arrives ~235 into bits1/2 of correction addend
//   carry chain (bit1->bit2->bit3) adds up to about 2*45 = 90 after r affects bit1
//   then sum bit3 adds 80
//   rough worst-case: 235 + 45 + 45 + 80 = 405
//   => T worst-case ~ 405
// ============================================================
module BCD_FA (
  input  wire [3:0] D,
  input  wire [3:0] E,
  input  wire       c,
  output wire [3:0] T,
  output wire       r
);
  // 1) First 4-bit add: D + E + c
  wire [3:0] Sbin;
  wire       cout1;
  ADD4_ripple add_bin (.A(D), .B(E), .cin(c), .S(Sbin), .cout(cout1));

  // 2) r = cout1 OR (s3 AND (s2 OR s1)) using ONLY 2-input gates with #10
  wire s2_or_s1;
  wire s3_and_mid;

  or  #10 g_or1   (s2_or_s1,  Sbin[2], Sbin[1]);
  and #10 g_and1  (s3_and_mid, Sbin[3], s2_or_s1);
  or  #10 g_or2   (r,          cout1,   s3_and_mid);

  // 3) Correction: add 0110 when r=1 else 0000
  // corr = {0, r, r, 0} == (r ? 4'b0110 : 4'b0000)
  wire [3:0] corr;
  assign corr = {1'b0, r, r, 1'b0};

  wire dummy_cout2;
  ADD4_ripple add_corr (.A(Sbin), .B(corr), .cin(1'b0), .S(T), .cout(dummy_cout2));
endmodule


// ============================================================
// (4) 3-digit BCD parallel adder (ripple across BCD digits)
// Inputs:  M[11:0], N[11:0], p
// Outputs: Q[11:0], w
//
// Delay analysis (worst-case):
//  - Each BCD_FA carry r worst ~ 235 (see above)
//  - Final carry w: 3 stages => 3*235 = 705
//  - Q[3:0]  worst ~ 405
//  - Q[7:4]  worst ~ 235 + 405 = 640
//  - Q[11:8] worst ~ 2*235 + 405 = 875
//  => Worst-case overall output time ~ 875 (Q[11:8])
// ============================================================
module BCD3_ADDER (
  input  wire [11:0] M,
  input  wire [11:0] N,
  input  wire        p,
  output wire [11:0] Q,
  output wire        w
);
  wire c1, c2;

  BCD_FA d0 (.D(M[3:0]),   .E(N[3:0]),   .c(p),  .T(Q[3:0]),   .r(c1));
  BCD_FA d1 (.D(M[7:4]),   .E(N[7:4]),   .c(c1), .T(Q[7:4]),   .r(c2));
  BCD_FA d2 (.D(M[11:8]),  .E(N[11:8]),  .c(c2), .T(Q[11:8]),  .r(w));
endmodule


// ============================================================
// Testbenches (same file, choose which one is "top" each run)
// ============================================================

// -------------------- TB for (1) FA -------------------------
module tb1_fa();
  reg  A, B, CIN;
  wire S, COUT;

  FA_delayed dut (.A(A), .B(B), .CIN(CIN), .S(S), .COUT(COUT));

  initial begin
    A=0; B=0; CIN=0;
    #100 A=1;
    #100 B=1;
    #100 CIN=1;
    #200 A=0; B=0; CIN=0;
    #200 $finish;
  end
endmodule


// ---------------- TB for (2) 4-bit ripple adder --------------
module tb2_add4();
  reg  [3:0] A, B;
  reg        cin;
  wire [3:0] S;
  wire       cout;

  ADD4_ripple dut (.A(A), .B(B), .cin(cin), .S(S), .cout(cout));

  initial begin
    A=0; B=0; cin=0;

    // Example to trigger ripple: 0xF + 0x1
    #200 A=4'hF; B=4'h1; cin=1'b0;

    #600 A=4'h7; B=4'h8; cin=1'b1;

    #800 $finish;
  end
endmodule


// -------------- TB for (3) BCD FA ---------

module tb_bcd_fa_exhaustive_worst();

  reg  [3:0] D, E;
  reg        c;
  wire [3:0] T;
  wire       r;

  BCD_FA dut (.D(D), .E(E), .c(c), .T(T), .r(r));

  // --- time variables ---
  time t_apply;
  time t_last_T_change;
  time t_last_r_change;
  time settleT;
  time settler;
  time worst_T;
  time worst_r;

  integer worst_D_T, worst_E_T, worst_c_T;
  integer worst_D_r, worst_E_r, worst_c_r;

  integer d_i, e_i, c_i;

  // track last changes
  always @(T) t_last_T_change = $realtime;
  always @(r) t_last_r_change = $realtime;

  initial begin
    $timeformat(-9, 0, " ns", 10);

    // init
    D = 0; E = 0; c = 0;
    worst_T = 0;
    worst_r = 0;

    #5;

    for (d_i = 0; d_i <= 9; d_i = d_i + 1) begin
      for (e_i = 0; e_i <= 9; e_i = e_i + 1) begin
        for (c_i = 0; c_i <= 1; c_i = c_i + 1) begin

          // ---- RESET timestamps BEFORE apply ----
          t_last_T_change = $realtime;
          t_last_r_change = $realtime;

          // apply vector
          t_apply = $realtime;
          D = d_i[3:0];
          E = e_i[3:0];
          c = c_i[0];

          // wait to settle
          #1000;

          // compute settle times
          settleT = t_last_T_change - t_apply;
          settler = t_last_r_change - t_apply;

          // update worst T
          if (settleT > worst_T) begin
            worst_T   = settleT;
            worst_D_T = d_i;
            worst_E_T = e_i;
            worst_c_T = c_i;
          end

          // update worst r
          if (settler > worst_r) begin
            worst_r   = settler;
            worst_D_r = d_i;
            worst_E_r = e_i;
            worst_c_r = c_i;
          end

        end
      end
    end

    $display("\n==== EXHAUSTIVE RESULTS ====");
    $display("Worst T settle = %0t ns at D=%0d E=%0d c=%0d",
             worst_T, worst_D_T, worst_E_T, worst_c_T);

    $display("Worst r settle = %0t ns at D=%0d E=%0d c=%0d",
             worst_r, worst_D_r, worst_E_r, worst_c_r);

    $finish;
  end

endmodule

// ---------------- TB for (4) 3-digit BCD adder ----------------

`timescale 1ns/1ps

module tb_bcd3_show_worst_transition;

  reg  [11:0] M, N;
  reg         p;
  wire [11:0] Q;
  wire        w;

  BCD3_ADDER dut (.M(M), .N(N), .p(p), .Q(Q), .w(w));

  initial begin
    // prev: M=002, N=773, p=1
    M = {4'd0,4'd0,4'd2};
    N = {4'd7,4'd7,4'd3};
    p = 1'b1;
    #3000; // άσε να σταθεροποιηθεί

    // worst: M=002, N=774, p=0
    M = {4'd0,4'd0,4'd2};
    N = {4'd7,4'd7,4'd4};
    p = 1'b0;
    #3000;

    $finish;
  end

endmodule