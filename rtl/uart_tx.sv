module uart_tx (
    input clk,
    input rstn,
    uart_int_if.tx uif_t
);
  import uart_pkg::*;
  localparam int WIDTH_TICKCNT = $clog2(OSR);
  localparam int WIDTH_BITCNT = $clog2(WIDTH_DATA);

  states_e c_state, n_state;
  logic [WIDTH_BITCNT-1:0] c_bitcnt, n_bitcnt;
  logic [WIDTH_TICKCNT-1:0] c_tickcnt, n_tickcnt;
  logic [WIDTH_DATA-1:0] c_txsr, n_txsr;
  logic n_tx, c_tx, n_busy, c_busy;
  logic xor_data;

  assign uif_t.data_tx_ser  = c_tx;
  assign uif_t.flag_tx_busy = c_busy;

  always @(posedge clk or negedge rstn) begin
    if (rstn) begin
      c_state   <= IDLE;
      c_tx      <= 1;
      c_bitcnt  <= 0;
      c_tickcnt <= 0;
      c_busy    <= 0;
      c_txsr    <= 0;
      xor_data  <= 0;
    end else begin
      c_state   <= n_state;
      c_tx      <= n_tx;
      c_bitcnt  <= n_bitcnt;
      c_tickcnt <= n_tickcnt;
      c_busy    <= n_busy;
      c_txsr    <= n_txsr;
      // for parity calc
      if (uif_t.cfg_en_parity == 1 && uif_t.cmd_tx_start == 1) xor_data <= ^uif_t.data_tx_par;
    end
  end

  always_comb begin
    n_state   = c_state;
    n_tx      = c_tx;
    n_bitcnt  = c_bitcnt;
    n_tickcnt = c_tickcnt;
    n_txsr    = c_txsr;
    n_busy    = c_busy;
    case (c_state)
      IDLE: begin
        n_tx = 1;
        if (uif_t.cmd_tx_start) begin
          n_state = START;
          n_busy  = 1;
          n_txsr  = uif_t.data_tx_par;
        end
      end
      START: begin
        n_tx = 0;
        // n_busy = 1;
        if (uif_t.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_state   = DATA;
            n_tickcnt = 0;
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      DATA: begin
        n_tx = c_txsr[0];
        if (uif_t.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_tickcnt = 0;
            if (c_bitcnt == WIDTH_DATA - 1) begin
              n_bitcnt = 0;
              n_state  = uif_t.cfg_en_parity ? PARITY : STOP;
            end else begin
              n_bitcnt = c_bitcnt + 1;
              n_txsr   = c_txsr >> 1;
            end
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      PARITY: begin
        n_tx = ~xor_data ^ uif_t.cfg_even_parity;
        if (uif_t.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_state   = STOP;
            n_tickcnt = 0;
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
      STOP: begin
        n_tx = 1;
        if (uif_t.baud_tick) begin
          if (c_tickcnt == OSR - 1) begin
            n_tickcnt = 0;
            n_state = IDLE;
            n_busy = 0;
          end else begin
            n_tickcnt = c_tickcnt + 1;
          end
        end
      end
    endcase
  end

endmodule
