----------------------------------------------------------------------------------
-- This file comes from HDMI-RX project by Digilent-Maker.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity ibuffs is
generic
 (
  -- width of the data for the system
  sys_w : integer := 1;
  dev_w : integer := 10);
port
 (
  reset : in std_logic;

  -- from the system into the device
  data_in_from_pins_p : in  std_logic_vector(sys_w-1 downto 0);
  data_in_from_pins_n : in  std_logic_vector(sys_w-1 downto 0);
  data_in_to_device   : out std_logic_vector(dev_w-1 downto 0);

  -- input, output delay control signals
  in_delay_reset      : in  std_logic;
  in_delay_data_ce    : in  std_logic_vector(sys_w -1 downto 0);
  in_delay_data_inc   : in  std_logic_vector(sys_w -1 downto 0);
  cntvalue_o          : out std_logic_vector(4 downto 0);
  bitslip             : in  std_logic;

  -- clock and reset signals
  pclk_x5_in          : in  std_logic;
  pclk_x1_in          : in  std_logic);
end ibuffs;

architecture behavioral of ibuffs is

  constant clock_enable          : std_logic := '1';
  signal unused                  : std_logic;
  signal clk_div                 : std_logic;
  signal clk_div_int             : std_logic;
  signal clk_in_int_buf          : std_logic;
  signal clk_in_int_1x           : std_logic;

  signal clkfb_net               : std_logic;
  signal clk_div_fb              : std_logic;
  signal fbclk_in                : std_logic;
  signal locked                  : std_logic;
  signal io_reset                : std_logic;
  signal in_delay_reset_int      : std_logic;
  signal delay_locked            : std_logic;

  -- after the buffer
  signal data_in_from_pins_int   : std_logic;
  -- between the delay and serdes
  signal data_in_from_pins_delay : std_logic;
  signal delay_data_busy         : std_logic_vector(sys_w-1 downto 0);
  signal in_delay_ce             : std_logic;
  signal in_delay_inc_dec        : std_logic;
  signal ce_out_uc               : std_logic;
  signal inc_out_uc              : std_logic;
  signal regrst_out_uc           : std_logic;
  constant num_serial_bits       : integer := dev_w/sys_w;

  type serdarr is array (0 to 13) of std_logic_vector(sys_w-1 downto 0);

  signal iserdes_q               : serdarr := (( others => (others => '0')));
  signal serdesstrobe            : std_logic;
  signal icascade1               : std_logic_vector(sys_w-1 downto 0);
  signal icascade2               : std_logic_vector(sys_w-1 downto 0);
  signal clk_in_int_inv          : std_logic;

  signal cntvalue : std_logic_vector(4 downto 0);

  attribute iodelay_group : string;
  attribute iodelay_group of idelaye2_bus : label is "ibuffs_group";

begin

  in_delay_ce <= in_delay_data_ce(0);
  in_delay_inc_dec <= in_delay_data_inc(0);

  io_reset <= reset;--'0' when locked = '1' else '1';
  in_delay_reset_int <= reset or in_delay_reset;--'0' when locked = '1' or in_delay_reset = '1' else '1';

  -- instantiate the buffers
  ----------------------------------
  -- instantiate a buffer for every bit of the data bus
  ibufds_inst : ibufds
    generic map (
      diff_term  => true)
    port map (
      i   => data_in_from_pins_p(0),--  (pin_count),
      ib  => data_in_from_pins_n(0),--  (pin_count),
      o   => data_in_from_pins_int
    );

  -- instantiate the delay primitive
  -----------------------------------
  idelaye2_bus : idelaye2
    generic map (
      cinvctrl_sel           => "FALSE",
      delay_src              => "IDATAIN",
      high_performance_mode  => "TRUE",
      idelay_type            => "VARIABLE",
      idelay_value           => 0,
      refclk_frequency       => 200.0,
      pipe_sel               => "FALSE",
      signal_pattern         => "DATA"
    )
    port map (
      dataout                => data_in_from_pins_delay,
      datain                 => '0',
      c                      => pclk_x1_in,
      ce                     => in_delay_ce,
      inc                    => in_delay_inc_dec,
      idatain                => data_in_from_pins_int,
      ld                     => in_delay_reset_int,
      regrst                 => io_reset,
      ldpipeen               => '0',
      cntvaluein             => "00000",
      cntvalueout            => cntvalue,
      cinvctrl               => '0'
    );
  cntvalue_o <= cntvalue;

  -- instantiate the serdes primitive
  ----------------------------------

  clk_in_int_inv <= not (pclk_x5_in);

  -- declare the iserdes
  iserdese2_master : iserdese2
    generic map (
      data_rate         => "DDR",
      data_width        => 10,
      interface_type    => "NETWORKING",
      dyn_clkdiv_inv_en => "FALSE",
      dyn_clk_inv_en    => "FALSE",
      num_ce            => 2,
      ofb_used          => "FALSE",
      iobdelay          => "IFD",
      serdes_mode       => "MASTER")
    port map (
      q1                => iserdes_q(0)(0),
      q2                => iserdes_q(1)(0),
      q3                => iserdes_q(2)(0),
      q4                => iserdes_q(3)(0),
      q5                => iserdes_q(4)(0),
      q6                => iserdes_q(5)(0),
      q7                => iserdes_q(6)(0),
      q8                => iserdes_q(7)(0),
      shiftout1         => icascade1(0),
      shiftout2         => icascade2(0),
      bitslip           => bitslip,
      ce1               => clock_enable,
      ce2               => clock_enable,
      clk               => pclk_x5_in,
      clkb              => clk_in_int_inv,
      clkdiv            => pclk_x1_in,
      clkdivp           => '0',
      d                 => '0',
      ddly              => data_in_from_pins_delay,
      rst               => io_reset,
      shiftin1          => '0',
      shiftin2          => '0',
     -- unused connections
      dynclkdivsel      => '0',
      dynclksel         => '0',
      ofb               => '0',
      oclk              => '0',
      oclkb             => '0',
      o                 => open
    );

  iserdese2_slave : iserdese2
    generic map (
      data_rate         => "DDR",
      data_width        => 10,
      interface_type    => "NETWORKING",
      dyn_clkdiv_inv_en => "FALSE",
      dyn_clk_inv_en    => "FALSE",
      num_ce            => 2,
      ofb_used          => "FALSE",
      iobdelay          => "IFD",
      serdes_mode       => "SLAVE")
    port map (
      q1                => open,
      q2                => open,
      q3                => iserdes_q(8)(0),
      q4                => iserdes_q(9)(0),
      q5                => iserdes_q(10)(0),
      q6                => iserdes_q(11)(0),
      q7                => iserdes_q(12)(0),
      q8                => iserdes_q(13)(0),
      shiftout1         => open,
      shiftout2         => open,
      shiftin1          => icascade1(0), 
      shiftin2          => icascade2(0), 
      bitslip           => bitslip,
      ce1               => clock_enable,
      ce2               => clock_enable,
      clk               => pclk_x5_in,
      clkb              => clk_in_int_inv,
      clkdiv            => pclk_x1_in,
      clkdivp           => '0',
      d                 => '0',
      ddly              => '0',
      rst               => io_reset,
      dynclkdivsel      => '0',
      dynclksel         => '0',
      ofb               => '0',
      oclk              => '0',
      oclkb             => '0',
      o                 => open
    );

  -- concatenate the serdes outputs together. keep the timesliced
  --   bits together, and placing the earliest bits on the right
  --   ie, if data comes in 0, 1, 2, 3, 4, 5, 6, 7, ...
  --       the output will be 3210, 7654, ...
  -------------------------------------------------------------
  in_slices: for slice_count in 0 to num_serial_bits-1 generate begin
     -- this places the first data in time on the right
     data_in_to_device(slice_count) <=
       iserdes_q(num_serial_bits-slice_count-1)(0);
  end generate in_slices;
end behavioral;
