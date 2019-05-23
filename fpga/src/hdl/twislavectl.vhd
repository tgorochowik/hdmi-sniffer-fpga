----------------------------------------------------------------------------------
-- This file comes from HDMI-RX project by Digilent-Maker.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity twislavectl is
  generic (
    slave_address : std_logic_vector(7 downto 0) := x"a0"
  );
  port (
    d_i      : in  std_logic_vector (7 downto 0);
    d_o      : out std_logic_vector (7 downto 0);
    rd_wrn_o : out std_logic;
    end_o    : out std_logic;
    done_o   : out std_logic;
    stb_i    : in  std_logic;
    clk      : in  std_logic;
    srst     : in  std_logic;
    sda_i    : in  std_logic;
    sda_o    : out std_logic;
    sda_t    : out std_logic;
    scl_i    : in  std_logic
  );
end twislavectl;

architecture behavioral of twislavectl is
  attribute fsm_encoding: string;
   type state_type is (stidle, staddress, stread, stwrite, stsack, stmack, stturnaround);
   signal state, nstate : state_type;
  attribute fsm_encoding of state: signal is "gray";

  signal dsda, ddsda, dscl, ddscl : std_logic;
  signal fstart, fstop, fsclfalling, fsclrising : std_logic;
  signal databyte : std_logic_vector(7 downto 0); --shift register and parallel load
  signal iend, idone, latchdata, databitout, shiftbitin, shiftbitout : std_logic;
  signal rd_wrn, drive : std_logic;
  signal bitcount : natural range 0 to 7 := 7;
begin
----------------------------------------------------------------------------------
--bus state detection
----------------------------------------------------------------------------------
sync_ffs: process(clk)
begin
  if rising_edge(clk) then
    dsda  <= sda_i;
    ddsda <= dsda;
    dscl  <= scl_i;
    ddscl <= dscl;
  end if;
end process;

fstart <= dscl and not dsda and ddsda; --if scl high while sda falling, start condition
fstop <= dscl and dsda and not ddsda; --if scl high while sda rising, stop condition

fsclfalling <= ddscl and not dscl; -- scl falling
fsclrising <= not ddscl and dscl; -- scl rising

----------------------------------------------------------------------------------
-- open-drain outputs for bi-directional sda and scl
----------------------------------------------------------------------------------
sda_t <= databitout or not(drive);
sda_o <= '0';

----------------------------------------------------------------------------------
-- title: data byte shift register
-- description: stores the byte to be written or the byte read depending on the
-- transfer direction.
----------------------------------------------------------------------------------
databyte_shreg: process (clk)
begin
  if rising_edge(clk) then
    if ((latchdata = '1' and fsclfalling = '1') or state = stidle or fstart = '1') then
      databyte <= d_i; --latch data
      bitcount <= 7;
    elsif (shiftbitout = '1' and fsclfalling = '1') then
      databyte <= databyte(databyte'high-1 downto 0) & dsda;
      bitcount <= bitcount - 1;
    elsif (shiftbitin = '1' and fsclrising = '1') then
      databyte <= databyte(databyte'high-1 downto 0) & dsda;
      bitcount <= bitcount - 1;
    end if;
  end if;
end process;

databitout <= '0' when state = stsack else databyte(databyte'high);

d_o <= databyte;
rd_wrn_o <= rd_wrn;

rdwrn_bit_reg: process (clk)
begin
  if rising_edge(clk) then
    if (state = staddress and bitcount = 0 and fsclrising = '1') then
      rd_wrn <= dsda;
    end if;
  end if;
end process;

sync_proc: process (clk)
begin
  if rising_edge(clk) then
    state  <= nstate;
    end_o  <= iend;
    done_o <= idone;
  end if;
end process;

output_decode: process (nstate, state, fsclrising, fsclfalling, ddsda, bitcount)
begin
  idone <= '0';
  iend <= '0';
  shiftbitin <= '0';
  shiftbitout <= '0';
  latchdata <= '0';
  drive <= '0';

  if (state = stread or state = stsack) then
    drive <= '1';
  end if;

  if (state = staddress or state = stwrite) then
    shiftbitin <= '1';
  end if;

  if (state = stread) then
    shiftbitout <= '1';
  end if;

  if ((state = stsack and rd_wrn = '1') or
    (state = stmack and ddsda = '0')) then --get the data byte for the next read
    latchdata <= '1';
  end if;

  if ((state = staddress and bitcount = 0 and fsclrising = '1' and databyte(6 downto 0) = slave_address(7 downto 1)) or
    (state = stwrite and bitcount = 0 and fsclrising = '1') or
    (state = stread and bitcount = 0 and fsclfalling = '1')) then
    idone <= '1';
  end if;

  if (fstop = '1' or fstart = '1' or
    (state = stmack and fsclrising = '1' and ddsda = '1')) then
    iend <= '1';
  end if;

end process;

next_state_decode: process (state, fstart, stb_i, fsclrising, fsclfalling, bitcount, ddsda)
begin

  nstate <= state;  --default is to stay in current state

  case (state) is
    when stidle =>
      if (fstart = '1') then -- start condition received
        nstate <= staddress;
      end if;

    when staddress =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (bitcount = 0 and fsclrising = '1') then
        if (databyte(6 downto 0) = slave_address(7 downto 1)) then
          nstate <= stturnaround;
        else
          nstate <= stidle;
        end if;
      end if;

    when stturnaround =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (fstart = '1') then
        nstate <= staddress;
      elsif (fsclfalling = '1') then
        if (stb_i = '1') then
          nstate <= stsack; --we acknowledge and continue
        else
          nstate <= stidle; --don't ack and stop
        end if;
      end if;

    when stsack =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (fstart = '1') then
        nstate <= staddress;
      elsif fsclfalling = '1' then
        if (rd_wrn = '1') then
          nstate <= stread;
        else
          nstate <= stwrite;
        end if;
      end if;

    when stwrite =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (fstart = '1') then
        nstate <= staddress;
      elsif (bitcount = 0 and fsclrising = '1') then
        nstate <= stturnaround;
      end if;

       when stmack =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (fstart = '1') then
        nstate <= staddress;
      elsif (fsclfalling = '1') then
        if (ddsda = '1') then
          nstate <= stidle;
        else
          nstate <= stread;
        end if;
      end if;

    when stread =>
      if (fstop = '1') then
        nstate <= stidle;
      elsif (fstart = '1') then
        nstate <= staddress;
      elsif (bitcount = 0 and fsclfalling = '1') then
        nstate <= stmack;
      end if;

    when others =>
      nstate <= stidle;

  end case;
end process;

end behavioral;

