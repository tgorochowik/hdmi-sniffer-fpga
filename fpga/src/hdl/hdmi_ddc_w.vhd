------------------------------------------------------------------------
-- This file comes from HDMI-RX project by Digilent-Maker.
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

------------------------------------------------------------------------
-- module declaration
------------------------------------------------------------------------
entity hdmi_ddc_w is
  port(
    -- system clock
    clk_i : in  std_logic;

    -- i2c signals
    scl_i : in std_logic;
    sda_i : in std_logic;
    sda_o : out std_logic;
    sda_t : out std_logic
  );
end hdmi_ddc_w;

architecture behavioral of hdmi_ddc_w is

type edid_t is array (0 to 255) of std_logic_vector(7 downto 0);
type state_type is (stidle, stread, stwrite, stregaddress);

------------------------------------------------------------------------
-- signal declarations
------------------------------------------------------------------------

signal edid : edid_t := (
 x"00" ,x"ff" ,x"ff" ,x"ff" ,x"ff" ,x"ff" ,x"ff" ,x"00" ,x"4c" ,x"2d" ,x"20" ,x"0a" ,x"31" ,x"38" ,x"32" ,x"30",
 x"30" ,x"17" ,x"01" ,x"03" ,x"80" ,x"30" ,x"1b" ,x"78" ,x"2a" ,x"90" ,x"c1" ,x"a2" ,x"59" ,x"55" ,x"9c" ,x"27",
 x"0e" ,x"50" ,x"54" ,x"bf" ,x"ef" ,x"80" ,x"71" ,x"4f" ,x"81" ,x"c0" ,x"81" ,x"00" ,x"81" ,x"80" ,x"95" ,x"00",
 x"a9" ,x"c0" ,x"b3" ,x"00" ,x"01" ,x"01" ,x"02" ,x"3a" ,x"80" ,x"18" ,x"71" ,x"38" ,x"2d" ,x"40" ,x"58" ,x"2c",
 x"45" ,x"00" ,x"dd" ,x"0c" ,x"11" ,x"00" ,x"00" ,x"1e" ,x"01" ,x"1d" ,x"00" ,x"72" ,x"51" ,x"d0" ,x"1e" ,x"20",
 x"6e" ,x"28" ,x"55" ,x"00" ,x"dd" ,x"0c" ,x"11" ,x"00" ,x"00" ,x"1e" ,x"00" ,x"00" ,x"00" ,x"fd" ,x"00" ,x"32",
 x"4b" ,x"1e" ,x"51" ,x"11" ,x"00" ,x"0a" ,x"20" ,x"20" ,x"20" ,x"20" ,x"20" ,x"20" ,x"00" ,x"00" ,x"00" ,x"fc",
 x"00" ,x"53" ,x"32" ,x"32" ,x"43" ,x"33" ,x"30" ,x"30" ,x"0a" ,x"20" ,x"20" ,x"20" ,x"20" ,x"20" ,x"01" ,x"b1",
 x"02" ,x"03" ,x"11" ,x"b1" ,x"46" ,x"90" ,x"04" ,x"1f" ,x"13" ,x"12" ,x"03" ,x"65" ,x"03" ,x"0c" ,x"00" ,x"10",
 x"00" ,x"01" ,x"1d" ,x"00" ,x"bc" ,x"52" ,x"d0" ,x"1e" ,x"20" ,x"b8" ,x"28" ,x"55" ,x"40" ,x"dd" ,x"0c" ,x"11",
 x"00" ,x"00" ,x"1e" ,x"8c" ,x"0a" ,x"d0" ,x"90" ,x"20" ,x"40" ,x"31" ,x"20" ,x"0c" ,x"40" ,x"55" ,x"00" ,x"dd",
 x"0c" ,x"11" ,x"00" ,x"00" ,x"18" ,x"8c" ,x"0a" ,x"d0" ,x"8a" ,x"20" ,x"e0" ,x"2d" ,x"10" ,x"10" ,x"3e" ,x"96",
 x"00" ,x"dd" ,x"0c" ,x"11" ,x"00" ,x"00" ,x"18" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00",
 x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00",
 x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00",
 x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"00" ,x"50");

signal state, nstate : state_type;
signal regaddr, databytein, databyteout : std_logic_vector(7 downto 0) := x"00";
signal xfer_end, xfer_done, xfer_stb, rd_wrn : std_logic;

------------------------------------------------------------------------
-- component declarations
------------------------------------------------------------------------

component twislavectl
  generic(
    slave_address : std_logic_vector(7 downto 0) := x"a0"); -- twi slave address
  port(
    d_i       : in  std_logic_vector (7 downto 0);
    d_o       : out std_logic_vector (7 downto 0);
    rd_wrn_o  : out std_logic;
    end_o     : out std_logic;
    done_o    : out std_logic;
    stb_i     : in  std_logic;
    clk       : in  std_logic;
    srst      : in  std_logic;
    sda_i     : in  std_logic;
    sda_o     : out std_logic;
    sda_t     : out std_logic;
    scl_i     : in  std_logic
  );
end component;

------------------------------------------------------------------------
-- module implementation
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
-- instantiate the i2c slave transmitter
------------------------------------------------------------------------
inst_twislave: twislavectl
  generic map(
    slave_address => x"a0")
  port map(
    d_i      => databyteout,
    d_o      => databytein,
    rd_wrn_o => rd_wrn,
    end_o    => xfer_end,
    done_o   => xfer_done,
    stb_i    => xfer_stb,
    clk      => clk_i,
    srst     => '0',
    sda_i    => sda_i,
    sda_o    => sda_o,
    sda_t    => sda_t,
    scl_i    => scl_i
  );

-- eeprom
process (clk_i)
begin
  if rising_edge(clk_i) then
    if (xfer_done = '1') then
      if (state = stregaddress) then
        regaddr <= databytein;
      elsif (state = stread) then
        regaddr <= regaddr + '1';
      end if;

      if (state = stwrite) then
        edid(conv_integer(regaddr)) <= databytein;
      end if;
    end if;
    databyteout <= edid(conv_integer(regaddr));
  end if;
end process;

--insert the following in the architecture after the begin keyword
sync_proc: process (clk_i)
begin
  if rising_edge(clk_i) then
    state <= nstate;
  end if;
end process;

--moore state-machine - outputs based on state only
output_decode: process (state)
begin
  xfer_stb <= '0';

  if (state = stregaddress or state = stread or state = stwrite) then
    xfer_stb <= '1';
  end if;
end process;

next_state_decode: process (state, xfer_done, xfer_end, rd_wrn)
begin
  --declare default state for next_state to avoid latches
  nstate <= state;
  case (state) is
    when stidle =>
      if (xfer_done = '1') then
        if (rd_wrn = '1') then
          nstate <= stread;
        else
          nstate <= stregaddress;
        end if;
      end if;

    when stregaddress =>
      if (xfer_end = '1') then
        nstate <= stidle;
      elsif (xfer_done = '1') then
        nstate <= stwrite;
      end if;

    when stwrite =>
      if (xfer_end = '1') then
        nstate <= stidle;
      elsif (xfer_done = '1') then
        nstate <= stwrite;
      end if;

    when stread =>
      if (xfer_end = '1') then
        nstate <= stidle;
      elsif (xfer_done = '1') then
        nstate <= stread;
      end if;

    when others =>
      nstate <= stidle;
  end case;
end process;

end behavioral;
