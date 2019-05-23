/*********************************************************************************
 * Company: Antmicro Ltd
 * Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
 ********************************************************************************/

`timescale 1ns / 1ps

module decoder
(
  input  wire clk,

  input  wire [9:0] data_raw,

  input  wire data_ready,
  output reg  c0,
  output reg  c1,
  output reg  vde,

  output reg [7:0] vdout
);

localparam  BLANK_TOKEN = 10'b1101010100;
localparam  HSYNC_TOKEN = 10'b0010101011;
localparam  VSYNC_TOKEN = 10'b0101010100;
localparam VHSYNC_TOKEN = 10'b1010101011; /* Overlapping syncs */

wire [7:0] data;
assign data = (data_raw[9]) ? ~data_raw[7:0] : data_raw[7:0];

always @ (posedge clk) begin
  if(data_ready) begin
    case (data_raw)
      BLANK_TOKEN: begin
        c0 <= 1'b0;
        c1 <= 1'b0;
        vde <= 1'b0;
      end
      HSYNC_TOKEN: begin
        c0 <= 1'b1;
        c1 <= 1'b0;
        vde <= 1'b0;
      end
      VSYNC_TOKEN: begin
        c0 <= 1'b0;
        c1 <= 1'b1;
        vde <= 1'b0;
      end
      VHSYNC_TOKEN: begin
        c0 <= 1'b1;
        c1 <= 1'b1;
        vde <= 1'b0;
      end
      default: begin
        vdout[0] <= data[0];
        vdout[1] <= (data_raw[8]) ? (data[1] ^ data[0]) : (data[1] ~^ data[0]);
        vdout[2] <= (data_raw[8]) ? (data[2] ^ data[1]) : (data[2] ~^ data[1]);
        vdout[3] <= (data_raw[8]) ? (data[3] ^ data[2]) : (data[3] ~^ data[2]);
        vdout[4] <= (data_raw[8]) ? (data[4] ^ data[3]) : (data[4] ~^ data[3]);
        vdout[5] <= (data_raw[8]) ? (data[5] ^ data[4]) : (data[5] ~^ data[4]);
        vdout[6] <= (data_raw[8]) ? (data[6] ^ data[5]) : (data[6] ~^ data[5]);
        vdout[7] <= (data_raw[8]) ? (data[7] ^ data[6]) : (data[7] ~^ data[6]);
        vde <= 1'b1;
      end
    endcase
  end else begin
    c0 <= 1'b0;
    c1 <= 1'b0;
    vde <= 1'b0;
    vdout <= 8'b00000000;
  end
end

endmodule
