interface uart_int_if ();
  import uart_pkg::*;
  logic baud_tick;
  logic [WIDTH_UART_DATA-1:0] data_tx_par;
  logic cmd_tx_start;
  logic data_rx_ser;
  logic data_tx_ser;
  logic flag_tx_busy;
  logic [WIDTH_UART_DATA-1:0] data_rx_par;
  logic flag_rx_busy;
  logic flag_rx_done;
  logic flag_parity_error;
  logic flag_frame_error;
  logic [15:0] cfg_divisor;
  logic cfg_en_parity;
  logic cfg_even_parity;

  modport bg(input cfg_divisor, output baud_tick);
  modport tx(
      input baud_tick,
      input data_tx_par,
      input cmd_tx_start,
      input cfg_en_parity,
      input cfg_even_parity,
      output data_tx_ser,
      output flag_tx_busy
  );
  modport rx(
      input baud_tick,
      input data_rx_ser,
      input cfg_en_parity,
      input cfg_even_parity,
      output data_rx_par,
      output flag_frame_error,
      output flag_parity_error,
      output flag_rx_busy,
      output flag_rx_done
  );
endinterface
