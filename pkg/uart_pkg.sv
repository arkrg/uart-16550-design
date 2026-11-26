package uart_pkg;
  localparam int OSR = 16;
  localparam int WIDTH_UART_DATA = 8;

  typedef enum {
    IDLE,
    START,
    DATA,
    PARITY,
    STOP,
    WAIT_STOP
  } states_e;
  // register map
  localparam bit [31:0] ADDR_LSR = 32'h1000_4014;
  localparam bit [31:0] ADDR_LCR = 32'h1000_400C;
  localparam bit [31:0] ADDR_DLH = 32'h1000_4004;
  localparam bit [31:0] ADDR_DLL = 32'h1000_4000;
  localparam bit [31:0] ADDR_THR = 32'h1000_4000, ADDR_RBR = 32'h1000_4000;
endpackage
import uart_pkg::*;
