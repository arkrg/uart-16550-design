module uart_rx #(
) (
    input clk,
    input rstn,
    uart_int_if.rx uif_r
);
  import uart_pkg::*;
  localparam int WIDTH_TICKCNT = $clog2(OSR);
  localparam int WIDTH_BITCNT = $clog2(WIDTH_UART_DATA);
  states_e c_state, n_state;
  reg [WIDTH_UART_DATA-1:0] c_data, n_data;
  reg [WIDTH_TICKCNT-1:0] c_tickcnt, n_tickcnt;
  reg [WIDTH_BITCNT-1:0] c_bitcnt, n_bitcnt;
  reg c_done, n_done;
  reg c_busy, n_busy;
  reg c_pe, n_pe, c_fe, n_fe;

  assign uif_r.data_rx_par = c_data;
  assign uif_r.flag_rx_done = c_done;
  assign uif_r.flag_rx_busy = c_busy;
  assign uif_r.flag_parity_error = c_pe;
  assign uif_r.flag_frame_error = c_fe;

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      c_state   <= IDLE;
      c_done    <= 0;
      c_busy    <= 0;
      c_pe <= 0;
      c_fe <= 0;
      c_data    <= 0;
      c_tickcnt <= 0;
      c_bitcnt  <= 0;
    end else begin
      c_state   <= n_state;
      c_done    <= n_done;
      c_busy    <= n_busy;
      c_pe <= n_pe;
      c_fe <= n_fe;
      c_data    <= n_data;
      c_tickcnt <= n_tickcnt;
      c_bitcnt  <= n_bitcnt;
    end
  end

  always_comb begin
    n_state   = c_state;
    n_done    = c_done;
    n_busy    = c_busy;
    n_pe      = c_pe;
    n_fe      = c_fe;
    n_data    = c_data;
    n_tickcnt = c_tickcnt;
    n_bitcnt  = c_bitcnt;
    case (c_state)
      IDLE: begin
        n_state = (uif_r.data_rx_ser == 0) ? START : IDLE;
        n_done  = 0;
        n_busy  = 0;
        n_pe    = 0;
        n_fe    = 0;
      end
      START: begin
        n_busy = 1;
        if (uif_r.baud_tick) begin
          if (c_tickcnt == OSR / 2 - 1) begin
            n_tickcnt = 0;
            n_state   = DATA;
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      DATA: begin
        if (uif_r.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_tickcnt = 0;
            n_data = {uif_r.data_rx_ser, c_data[7:1]};
            if (c_bitcnt == WIDTH_UART_DATA - 1) begin
              n_bitcnt = 0;
              n_state  = (uif_r.cfg_en_parity) ? PARITY : STOP;
            end else begin
              n_bitcnt = c_bitcnt + 1;
            end
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      PARITY: begin
        if (uif_r.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_tickcnt = 0;
            n_pe = (uif_r.data_rx_ser != ~^{c_data, uif_r.cfg_even_parity});
            n_state = STOP;
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      STOP: begin
        if (uif_r.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_tickcnt = 0;
            if (uif_r.data_rx_ser == 1) begin
              n_state = IDLE;
              n_done  = 1;
              n_busy  = 0;
            end else begin
              n_state = WAIT_STOP;
              n_fe = 1;
            end
          end else n_tickcnt = c_tickcnt + 1;
        end
      end
      WAIT_STOP: begin
        if (uif_r.baud_tick) begin
          if (uif_r.data_rx_ser == 1) begin
            n_state = IDLE;
            n_tickcnt = 0;
            n_state = IDLE;
            n_done = 1;
            n_busy = 0;
          end
        end
      end
    endcase
  end
endmodule
