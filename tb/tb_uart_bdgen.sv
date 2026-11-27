// Testbench for uart_bdgen
// problem: below assertion doesn't work here, 
// action item: check this at EDA playground or reserch alt statement
// ------------------------------------------------------------------
// WARNING: [XSIM 43-4477] Line 46 : Delay Control inside Assertion action block is not supported
// WARNING: [XSIM 43-4127] Line 43 : The "System Verilog Assertion" is not supported yet for simulation. The statement will be iupport 
// property p_stable_zero_divisor;
//   @(posedge clk iff (!rst) & (divisor == 0)) $stable(
//       dut.c_count
//   );
// endproperty
// assert_zero_divisor :
// assert property (p_stable_zero_divisor)
// else begin
//   $error(" ===== internal counter changed. =====");
//   #10;
//   $finish;
// end
// ------------------------------------------------------------------
class divisor_item;
  rand shortint divisor;
  rand int baudrate;

  constraint solve_c {solve baudrate before divisor;}
endclass

module tb_uart_bdgen;
  import uart_pkg::*;
  parameter int SYS_FREQ = 100_000_000;
  parameter int MIN_BDR = 9600;
  shortint divisor;
  logic rstn, clk;

  initial clk = 0;
  always #5 clk <= ~clk;

  `include "tb_tasks.svh"

uart_int_if uif ();
  uart_bdgen dut (
      .clk,
      .rstn,
      .uif_b(uif.bg)
  );
  assign uif.cfg_divisor = divisor;

  initial begin
    divisor <= 0;
    reset();
    $display("===== Start! =====");
    repeat (4) begin
      sel_divisor(SYS_FREQ);
      meas_bdrate(SYS_FREQ, MIN_BDR);
      reset();
    end
    $display("===== All Tests finish! =====");
    $finish;
  end


  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0);
  end
endmodule
