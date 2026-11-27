class item;
  rand bit [7:0] data;
  rand bit en_parity;
  rand bit even_parity;

  rand bit err_parity;
  rand bit err_frame;
endclass
module tb_uart_rx ();
  import uart_pkg::*;
  parameter int SYS_FREQ = 100_000_000;
  parameter int BDRATE_X_OSR = 50_000_000;
  int count, err;
  item exp_q[$];

  states_e state;
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
  final begin
    $display("[RESULT] total %0d test, total error: %0d", count, err);
  end
  assign uif.cfg_divisor = SYS_FREQ / BDRATE_X_OSR;
  // Inst DUT and IF
  uart_int_if uif (
      .clk,
      .rst
  );
  uart_bdgen u_bdgen (.uif_b(uif.bg));
  uart_rx dut (
      .clk,
      .rst,
      .uif_r(uif.rx)
  );
  task automatic driver();
    item t;
    forever begin
      wait (!rst);
      t = new();
      t.randomize();
      exp_q.push_back(t);
      uif.cfg_en_parity <= t.en_parity;
      uif.cfg_even_parity <= t.even_parity;
      // start
      uif.data_rx_ser <= 0;
      state <= START;
      repeat (16) @(posedge uif.baud_tick);
      // data
      state <= DATA;
      for (int i = 0; i < 8; i = i + 1) begin
        uif.data_rx_ser <= t.data[i];
        repeat (16) @(posedge uif.baud_tick);
      end
      // parity
      if (t.en_parity == 1) begin
        state <= PARITY;
        if (t.err_parity) uif.data_rx_ser <= ^{t.data, t.even_parity};
        else uif.data_rx_ser <= ~^{t.data, t.even_parity};
        repeat (16) @(posedge uif.baud_tick);
      end
      //stop
      uif.data_rx_ser <= (!t.err_frame);
      state <= STOP;
      repeat (16) @(posedge uif.baud_tick);
      uif.data_rx_ser <= 1;
      repeat (16) @(posedge uif.baud_tick);
    end
  endtask
  task automatic monitor();
    bit [7:0] rcvd;
    forever begin
      item t = new();
      wait (exp_q.size() != 0);
      t = exp_q.pop_front();
      wait (uif.flag_rx_done);
      rcvd = uif.data_rx_par;
      if (t.en_parity == 1) begin
        if (t.err_parity != uif.flag_parity_error) begin
          $error("[MISMATCH]: [%t] En parity : %0b Expected Parity = %0b, Actual = %0b", $time,
                 t.en_parity, t.err_parity, uif.flag_parity_error);
          err++;
        end
      end
      if (t.err_frame != uif.flag_frame_error) begin
        $error("[MISMATCH]: Expected Frame= %0b, Actual = %0b", t.err_frame, uif.flag_frame_error);
        err++;
      end
      if (t.data != rcvd) begin
        $error("[MISMATCH]: Expected Data : %h, Actual Data = %h", t.data, rcvd);
        err++;
      end
      count++;
    end
  endtask

  // Dump Waves
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0);
  end

endmodule
