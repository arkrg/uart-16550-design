class item;
  rand bit [7:0] data;
  rand bit en_parity;
  rand bit even_parity;
endclass
module tb_uart_tx ();
  import uart_pkg::*;
  parameter int SYS_FREQ = 100_000_000;
  parameter int BDRATE_X_OSR = 50_000_000;
  int  count;
  item exp_q [$];

  logic clk, rst;
  // Clock and Reset
  initial clk = 0;
  always #5 clk <= ~clk;
  // Reset
  initial reset();
  task automatic reset();
    begin
      rst <= 1;
      repeat (2) @(posedge clk);
      rst <= 0;
      uif.cmd_tx_start <= 0;
      uif.cfg_en_parity <= 0;
      uif.cfg_even_parity <= 0;
    end
  endtask
  initial begin
    fork
      driver();
      monitor();
      forever begin
        @(posedge clk);
        if (count == 100) $finish;
      end
    join_any
    disable fork;
    $finish;

  end
  assign uif.cfg_divisor = SYS_FREQ / BDRATE_X_OSR;
  // Inst DUT and IF
  uart_int_if uif (
      .clk,
      .rst
  );
  uart_bdgen u_bdgen (.uif_b(uif.bg));
  uart_tx dut (.uif_t(uif.tx));
  task automatic driver();
    item t;
    forever begin
      wait (!rst);
      t = new();
      t.randomize();
      exp_q.push_back(t);
      uif.data_tx_par <= t.data;
      uif.cfg_en_parity <= t.en_parity;
      uif.cfg_even_parity <= t.even_parity;
      @(posedge clk);
      uif.cmd_tx_start <= 1;
      @(posedge clk);
      uif.cmd_tx_start <= 0;
      @(negedge uif.flag_tx_busy);
    end
  endtask
  task automatic monitor();
    bit [7:0] rcvd;
    bit parity;
    forever begin
      item t = new();
      @(posedge uif.flag_tx_busy);
      repeat (uif.cfg_divisor << 3) @(posedge clk);
      repeat (8) begin
        repeat (uif.cfg_divisor << 4) @(posedge clk);
        rcvd = {uif.data_tx_ser, rcvd[7:1]};
      end
      t = exp_q.pop_front();
      if (t.en_parity) begin
        repeat (uif.cfg_divisor << 4) @(posedge clk);
        parity = uif.data_tx_ser;
      end
      count++;
      if (t.data != rcvd) begin
        $error("Mismatch: Expected Data : %h, Actual Data = %h", t.data, rcvd);
      end
      if (t.en_parity) begin
        if (t.even_parity == ~^{rcvd, parity}) $error("Mismatch: Parity ");
        parity = 0;
      end
    end
  endtask

  // Dump Waves
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0);
  end
endmodule
