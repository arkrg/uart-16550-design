task automatic reset();
  begin
    rstn <= 0;
    repeat (2) @(posedge clk);
    rstn <= 1;
  end
endtask
task automatic sel_divisor(int SYS_FREQ);
  divisor_item item;
  begin
    item = new();
    if (!item.randomize() with {
          baudrate inside {9600, 12500};
          divisor inside {[0 : 3], SYS_FREQ / baudrate};
        })
      $error("Randomization Failed.");
    divisor = item.divisor;
    $display("--- Testing divisor = %d ---", item.divisor);
  end
endtask
task automatic meas_bdrate(int SYS_FREQ, int MIN_BDR);
  shortint meas = 0;
  wait (rstn == 1);
  if (divisor < 2) begin
    repeat (SYS_FREQ / MIN_BDR) @(posedge clk);
  end else begin
    fork
      begin
        @(posedge uif.baud_tick);
        fork
          @(posedge uif.baud_tick);
          forever @(posedge clk) meas++;
        join_any
        if (meas == divisor) begin
          $display("[PASS] Measured: %0d , Expected: %0d.", meas, divisor);
        end else begin
          $error("[FAIL] Measured: %0d , Expected: %0d.", meas, divisor);
        end
      end
      begin
        repeat (divisor * 3) @(posedge clk);
        $display("Error: Tick signal not generated.");
      end
    join_any
    disable fork;
  end
endtask
