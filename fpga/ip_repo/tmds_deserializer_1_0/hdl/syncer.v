/*********************************************************************************
 * Company: Antmicro Ltd
 * Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
 *
 * Based heavily on HDMI-RX project by Digilent-Maker.
 ********************************************************************************/

`timescale 1ns / 1ps
module syncer (
  input  wire pclk_x5_in,
  input  wire pclk_x1_in,
  input  wire locked,

  input  wire din_p,
  input  wire din_n,

  input  wire other_ch0_vld, //other channel0 has valid data now
  input  wire other_ch1_vld, //other channel1 has valid data now
  input  wire other_ch0_rdy, //other channel0 has detected a valid starting pixel
  input  wire other_ch1_rdy, //other channel1 has detected a valid starting pixel
  output wire iamvld,        //I have valid data now
  output wire iamrdy,        //I have detected a valid new pixel

  output wire [9:0] vdout,   //10 bit video data out

  input  wire rst_fsm
);
assign iamvld  = phasealigned;

wire pclk_raw, refclk;
reg  searchdone_q;
reg  fStartCnt;
reg  [1:0] CntReset;
wire wIntReset;
wire wSearchDone, searchdone_pls;
reg  bitslip;
wire pclk;
wire [4:0] idelay_cnt;
wire phasealigned;
wire [9:0] data_raw;
wire [9:0] sdata;
wire ps_ce;
wire ps_inc;
wire ps_overflow;
wire reset;
wire psalgnerr;
wire found_vld_openeye;
wire [9:0] openeye_length;
reg  [3:0] bitslip_cntr;

assign reset = ~locked;

// Input buffers and deserializers
ibuffs #(
  .sys_w(1),
  .dev_w(10))
IBuffs (
  .RESET(reset),
  .DATA_IN_FROM_PINS_P(din_p),
  .DATA_IN_FROM_PINS_N(din_n),
  .DATA_IN_TO_DEVICE(data_raw),
  .IN_DELAY_RESET(rst_fsm),
  .IN_DELAY_DATA_CE(ps_ce),
  .IN_DELAY_DATA_INC(ps_inc),
  .CNTVALUE_O(idelay_cnt),
  .BITSLIP(bitslip),
  .PCLK_X5_IN(pclk_x5_in),
  .PCLK_X1_IN(pclk_x1_in)
);

assign pclk = pclk_x1_in;

// idelay overflow flag (tap 31)
assign ps_overflow = (idelay_cnt == 5'b11111) ? 1'b1 : 1'b0;

// Phase alignment block
phasealign #(
  .CTKNCNTWD(4),
  .SRCHTIMERWD(19))
PhaseAlignment (
  .rst(rst_fsm || wIntReset),
  .clk(pclk),
  .sdata(data_raw),
  .psdone(1'b1),
  .dcm_ovflw(ps_overflow),
  .found_vld_openeye(found_vld_openeye),
  .psen(ps_ce),
  .psincdec(ps_inc),
  .psaligned(phasealigned),
  .psalgnerr(psalgnerr),
  .openeye_length(openeye_length)
);

// One search cycle done
assign wSearchDone = ((ps_overflow == 1'b1) && (psalgnerr == 1'b1)) ? 1'b1 : 1'b0;

always @ (posedge pclk) begin
   searchdone_q <= wSearchDone;
end

// Search done pulse
assign searchdone_pls = !searchdone_q & wSearchDone;

// Generate the bitslip signal at the end of every attempt to shift phase
always @ (posedge pclk) begin
   if(searchdone_pls)
      bitslip <= 1'b1;
   else
      bitslip <= 1'b0;
end

wire lockRst;
assign lockRst = !locked;
always @ (posedge pclk or posedge lockRst) begin
  if(lockRst)
    bitslip_cntr <= 4'b0000;
  else if (searchdone_pls)
    bitslip_cntr <= bitslip_cntr + 4'b0001;
end

// Start reset counter flag
always @ (posedge pclk) begin
  if(searchdone_pls)
    fStartCnt <= 1'b1;
  else if(CntReset == 2'b10)
    fStartCnt <= 1'b0;
end

assign wIntReset = fStartCnt;

// Reset counter
always @ (posedge pclk) begin
  if(fStartCnt)
    CntReset <= CntReset + 2'b01;
  else
    CntReset <= 2'b00;
end

chnlbond ChannelBond (
  .clk(pclk),
  .rawdata(data_raw),
  .iamvld(phasealigned),
  .other_ch0_vld(other_ch0_vld),
  .other_ch1_vld(other_ch1_vld),
  .other_ch0_rdy(other_ch0_rdy),
  .other_ch1_rdy(other_ch1_rdy),
  .iamrdy(iamrdy),
  .sdata(sdata)
);

assign vdout = sdata;
endmodule
