----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity tmds_deserializer_v1_0 is
  port (
    ext_rst       : in std_logic;
    sysclk        : in std_logic;
    tmds_in_clk_p : in std_logic;
    tmds_in_clk_n : in std_logic;

    tmds_in_d0_p  : in std_logic;
    tmds_in_d0_n  : in std_logic;

    tmds_in_d1_p  : in std_logic;
    tmds_in_d1_n  : in std_logic;

    tmds_in_d2_p  : in std_logic;
    tmds_in_d2_n  : in std_logic;

    tmds_clk      : out std_logic;

    tmds_d0       : out std_logic_vector(9 downto 0);
    tmds_d1       : out std_logic_vector(9 downto 0);
    tmds_d2       : out std_logic_vector(9 downto 0);

    data_valid    : out std_logic;
    data_ready    : out std_logic
  );
end tmds_deserializer_v1_0;

architecture arch_imp of tmds_deserializer_v1_0 is

component hdmi_clk
  port (
    clk_in_p   : in  std_logic;
    clk_in_n   : in  std_logic;
    clk_out_1x : out std_logic;
    clk_out_5x : out std_logic;
    reset      : in  std_logic;
    locked     : out std_logic
);
end component;

component syncer
  port(
    pclk_x5_in        : in std_logic;
    pclk_x1_in        : in std_logic;
    locked            : in std_logic;
    din_p             : in std_logic;
    din_n             : in std_logic;
    other_ch0_vld     : in std_logic;
    other_ch1_vld     : in std_logic;
    other_ch0_rdy     : in std_logic;
    other_ch1_rdy     : in std_logic;
    iamvld            : out std_logic;
    iamrdy            : out std_logic;
    vdout             : out std_logic_vector(9 downto 0);
    rst_fsm           : in std_logic
);
end component;

signal refclklckd : std_logic;
signal refclk, lckd, clklckd, delaylckd, pclk, clk_1x, clk_5x, clk_5x_mid : std_logic;
signal blue_rdy, green_rdy, red_rdy : std_logic;
signal blue_vld, green_vld, red_vld : std_logic;
signal red_int, green_int, blue_int : std_logic_vector(7 downto 0);
signal sysrst : std_logic;
signal pclk_x5, int_pclk, int_pclk_x5, int_sysclk : std_logic;

attribute iodelay_group : string;
attribute iodelay_group of delayctrl : label is "ibuffs_group";

begin

tmds_clk <= clk_1x;

sysrst <= ext_rst or (not delaylckd);

refclk <= sysclk;

data_valid <= blue_vld and green_vld and red_vld;
data_ready <= blue_rdy and green_rdy and red_rdy;

delayctrl : idelayctrl
port map (
  rdy         => delaylckd,
  refclk      => refclk,
  rst         => '0'
);

pclkgen : hdmi_clk
port map(
  clk_in_p => tmds_in_clk_p,
  clk_in_n => tmds_in_clk_n,
  clk_out_1x => int_pclk,
  clk_out_5x => int_pclk_x5,
  reset  => sysrst,
  locked => clklckd
);

bufg_i : bufg
port map (
  o => clk_1x,
  i => int_pclk
);

bufg_ii : bufg
port map (
  o => clk_5x,
  i => int_pclk_x5
);

lckd <= clklckd and delaylckd;

bluesyncer : syncer
port map (
  pclk_x5_in        => clk_5x,
  pclk_x1_in        => clk_1x,
  locked            => lckd,
  din_p             => tmds_in_d0_p,
  din_n             => tmds_in_d0_n,
  other_ch0_vld     => green_vld,
  other_ch1_vld     => red_vld,
  other_ch0_rdy     => green_rdy,
  other_ch1_rdy     => red_rdy,
  iamvld            => blue_vld,
  iamrdy            => blue_rdy,
  vdout             => tmds_d0,
  rst_fsm           => sysrst
);

greensyncer : syncer
port map (
  pclk_x5_in        => clk_5x,
  pclk_x1_in        => clk_1x,
  locked            => lckd,
  din_p             => tmds_in_d1_p,
  din_n             => tmds_in_d1_n,
  other_ch0_vld     => blue_vld,
  other_ch1_vld     => red_vld,
  other_ch0_rdy     => blue_rdy,
  other_ch1_rdy     => red_rdy,
  iamvld            => green_vld,
  iamrdy            => green_rdy,
  vdout             => tmds_d1,
  rst_fsm           => sysrst
);

redsyncer : syncer
port map (
  pclk_x5_in        => clk_5x,
  pclk_x1_in        => clk_1x,
  locked            => lckd,
  din_p             => tmds_in_d2_p,
  din_n             => tmds_in_d2_n,
  other_ch0_vld     => blue_vld,
  other_ch1_vld     => green_vld,
  other_ch0_rdy     => blue_rdy,
  other_ch1_rdy     => green_rdy,
  iamvld            => red_vld,
  iamrdy            => red_rdy,
  vdout             => tmds_d2,
  rst_fsm           => sysrst
);
end arch_imp;
