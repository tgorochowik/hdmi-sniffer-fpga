----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity system_top is
port (
  ddr_addr    : inout std_logic_vector ( 14 downto 0 );
  ddr_ba      : inout std_logic_vector ( 2 downto 0 );
  ddr_cas_n   : inout std_logic;
  ddr_ck_n    : inout std_logic;
  ddr_ck_p    : inout std_logic;
  ddr_cke     : inout std_logic;
  ddr_cs_n    : inout std_logic;
  ddr_dm      : inout std_logic_vector ( 3 downto 0 );
  ddr_dq      : inout std_logic_vector ( 31 downto 0 );
  ddr_dqs_n   : inout std_logic_vector ( 3 downto 0 );
  ddr_dqs_p   : inout std_logic_vector ( 3 downto 0 );
  ddr_odt     : inout std_logic;
  ddr_ras_n   : inout std_logic;
  ddr_reset_n : inout std_logic;
  ddr_we_n    : inout std_logic;

  fixed_io_ddr_vrn  : inout std_logic;
  fixed_io_ddr_vrp  : inout std_logic;
  fixed_io_mio      : inout std_logic_vector ( 53 downto 0 );
  fixed_io_ps_clk   : inout std_logic;
  fixed_io_ps_porb  : inout std_logic;
  fixed_io_ps_srstb : inout std_logic;


  uart_tx   : out   std_logic;
  uart_rx   : in    std_logic;

  led_n     : inout std_logic_vector(3 downto 0);
  ext_rst   : in    std_logic;

  tmds_in_clk_p  : in    std_logic;
  tmds_in_clk_n  : in    std_logic;
  tmds_in_d2_p   : in    std_logic;
  tmds_in_d2_n   : in    std_logic;
  tmds_in_d1_p   : in    std_logic;
  tmds_in_d1_n   : in    std_logic;
  tmds_in_d0_p   : in    std_logic;
  tmds_in_d0_n   : in    std_logic;
  tmds_in_sda    : inout std_logic;
  tmds_in_scl    : inout std_logic;

  tmds_in_hpd    : out   std_logic
);
end system_top;

architecture structure of system_top is

component vsniff_top is
port (
  ddr_addr              : inout std_logic_vector ( 14 downto 0 );
  ddr_ba                : inout std_logic_vector ( 2 downto 0 );
  ddr_cas_n             : inout std_logic;
  ddr_ck_n              : inout std_logic;
  ddr_ck_p              : inout std_logic;
  ddr_cke               : inout std_logic;
  ddr_cs_n              : inout std_logic;
  ddr_dm                : inout std_logic_vector ( 3 downto 0 );
  ddr_dq                : inout std_logic_vector ( 31 downto 0 );
  ddr_dqs_n             : inout std_logic_vector ( 3 downto 0 );
  ddr_dqs_p             : inout std_logic_vector ( 3 downto 0 );
  ddr_odt               : inout std_logic;
  ddr_ras_n             : inout std_logic;
  ddr_reset_n           : inout std_logic;
  ddr_we_n              : inout std_logic;
  fclk_clk0             : out   std_logic;
  fixed_io_ddr_vrn      : inout std_logic;
  fixed_io_ddr_vrp      : inout std_logic;
  fixed_io_mio          : inout std_logic_vector ( 53 downto 0 );
  fixed_io_ps_clk       : inout std_logic;
  fixed_io_ps_porb      : inout std_logic;
  fixed_io_ps_srstb     : inout std_logic;
  reset_n               : out   std_logic;
  mode_rgb              : out   std_logic;
  mode_tmds             : out   std_logic;
  mode_err              : out   std_logic;
  tmds_in_clk_p         : in    std_logic;
  tmds_in_clk_n         : in    std_logic;
  tmds_in_d2_p          : in    std_logic;
  tmds_in_d2_n          : in    std_logic;
  tmds_in_d1_p          : in    std_logic;
  tmds_in_d1_n          : in    std_logic;
  tmds_in_d0_p          : in    std_logic;
  tmds_in_d0_n          : in    std_logic;
  ext_rst               : in    std_logic;
  data_valid            : out   std_logic;
  tmds_clk              : out   std_logic
);
end component vsniff_top;

component hdmi_ddc_w is
port(
  clk_i : in  std_logic;
  scl_i : in  std_logic;
  sda_i : in  std_logic;
  sda_o : out std_logic;
  sda_t : out std_logic
);
end component hdmi_ddc_w;

signal clk     : std_logic;
signal rst     : std_logic := '0';
signal rst_n   : std_logic := '1';

signal rstcnt  : unsigned (15 downto 0) := (others => '0');

signal ledcount    : unsigned (25 downto 0);
signal ledcount_e  : unsigned (25 downto 0);

signal mode_rgb_i  : std_logic;
signal mode_tmds_i : std_logic;
signal mode_err_i  : std_logic;

signal tmds_in_valid : std_logic;
signal edid_t, edid_i, edid_o : std_logic;

signal tmds_clk_int : std_logic;

begin

-- processing system
i_system : vsniff_top
port map (
  ddr_addr          => ddr_addr,
  ddr_ba            => ddr_ba,
  ddr_cas_n         => ddr_cas_n,
  ddr_ck_n          => ddr_ck_n,
  ddr_ck_p          => ddr_ck_p,
  ddr_cke           => ddr_cke,
  ddr_cs_n          => ddr_cs_n,
  ddr_dm            => ddr_dm,
  ddr_dq            => ddr_dq,
  ddr_dqs_n         => ddr_dqs_n,
  ddr_dqs_p         => ddr_dqs_p,
  ddr_odt           => ddr_odt,
  ddr_ras_n         => ddr_ras_n,
  ddr_reset_n       => ddr_reset_n,
  ddr_we_n          => ddr_we_n,
  fclk_clk0         => clk,
  fixed_io_ddr_vrn  => fixed_io_ddr_vrn,
  fixed_io_ddr_vrp  => fixed_io_ddr_vrp,
  fixed_io_mio      => fixed_io_mio,
  fixed_io_ps_clk   => fixed_io_ps_clk,
  fixed_io_ps_porb  => fixed_io_ps_porb,
  fixed_io_ps_srstb => fixed_io_ps_srstb,
  reset_n           => rst_n,
  mode_rgb          => mode_rgb_i,
  mode_tmds         => mode_tmds_i,
  mode_err          => mode_err_i,
  tmds_in_clk_p     => tmds_in_clk_p,
  tmds_in_clk_n     => tmds_in_clk_n,
  tmds_in_d2_p      => tmds_in_d2_p,
  tmds_in_d2_n      => tmds_in_d2_n,
  tmds_in_d1_p      => tmds_in_d1_p,
  tmds_in_d1_n      => tmds_in_d1_n,
  tmds_in_d0_p      => tmds_in_d0_p,
  tmds_in_d0_n      => tmds_in_d0_n,
  data_valid        => tmds_in_valid,
  ext_rst           => ext_rst,
  tmds_clk          => tmds_clk_int
);

edid_inst : hdmi_ddc_w port map (
  clk_i => clk,
  scl_i => tmds_in_scl,
  sda_i => edid_i,
  sda_o => edid_o,
  sda_t => edid_t
);

-- clk and rst
process (clk)
  begin
  if rising_edge (clk) then
    if (not rstcnt) = 0 then
      rst <= '0';
    else
      rst <= '1';
      rstcnt <= rstcnt + 1;
    end if;
  end if;
end process;

-- led blink (internal clk running)
process (clk)
begin
  if rising_edge (clk) then
    if rst = '1' then
      ledcount  <= (others => '0');
    else
      ledcount <= ledcount + 1;
    end if;
  end if;
end process;

-- led blink (indicates valid HDMI clk input)
process (tmds_clk_int)
begin
  if rising_edge (tmds_clk_int) then
    if rst = '1' then
      ledcount_e <= (others => '0');
    else
      ledcount_e <= ledcount_e + 1;
    end if;
  end if;
end process;

led_n(0) <= mode_rgb_i;
led_n(1) <= tmds_in_valid;
led_n(2) <= ledcount_e(25);
led_n(3) <= ledcount(25);

iobuf_edid_inst : iobuf
port map (
  o  => edid_i,
  io => tmds_in_sda,
  i  => edid_o,
  t  => edid_t
);

tmds_in_hpd <= '1';

end architecture structure;
