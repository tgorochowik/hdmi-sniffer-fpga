----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rgb_streamer is
  port (
    red           : in std_logic_vector(7 downto 0);
    green         : in std_logic_vector(7 downto 0);
    blue          : in std_logic_vector(7 downto 0);
    ctrl          : in std_logic_vector(7 downto 0);
    enable        : in std_logic;

    hsync         : in std_logic;
    vsync         : in std_logic;

    m_axis_aclk   : in std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis_tdata  : out std_logic_vector(31 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tuser  : out std_logic_vector(0 downto 0);
    m_axis_fsync  : out std_logic;

    img_res_x     : out std_logic_vector(31 downto 0);
    img_res_y     : out std_logic_vector(31 downto 0)
  );
end entity;

architecture bechavioral of rgb_streamer is

  -- delayed data signals
  signal red_d    : std_logic_vector(7 downto 0);
  signal green_d  : std_logic_vector(7 downto 0);
  signal blue_d   : std_logic_vector(7 downto 0);
  signal ctrl_d   : std_logic_vector(7 downto 0);
  signal enable_d : std_logic;
  signal hsync_d  : std_logic;
  signal vsync_d  : std_logic;

  signal synced   : std_logic := '0';

  signal x_i, y_i : unsigned(31 downto 0);

begin

  -- size calculator
  process (m_axis_aclk)
  begin
    if rising_edge(m_axis_aclk) then
      if enable_d = '1' then
        x_i <= x_i + 1;
      elsif hsync_d = '1' and hsync = '0' then
        img_res_x <= std_logic_vector(x_i);
        x_i <= (others => '0');
      end if;

      if enable_d = '1' and enable = '0' then
        y_i <= y_i + 1;
      elsif vsync_d = '1' and vsync = '0' then
        img_res_y <= std_logic_vector(y_i);
        y_i <= (others => '0');
      end if;
    end if;
  end process;

  process (m_axis_aclk)
  begin
    if rising_edge(m_axis_aclk) then
      red_d    <= red;
      green_d  <= green;
      blue_d   <= blue;
      ctrl_d   <= ctrl;

      hsync_d  <= hsync;
      vsync_d  <= vsync;

      enable_d <= enable;
    end if;
  end process;

  process (m_axis_aclk)
  begin
    if rising_edge(m_axis_aclk) then
      if vsync = '1' then
        synced <= m_axis_tready;
      end if;
    end if;
  end process;

  m_axis_tlast <= enable_d and not enable and synced and m_axis_tready and not hsync and not vsync;

  m_axis_tdata <= red_d & green_d & blue_d & ctrl_d;

  m_axis_tvalid <= enable_d and synced and m_axis_tready;

  m_axis_tuser(0) <= not vsync and vsync_d and synced;

  m_axis_fsync <= not vsync and vsync_d and synced;

end architecture;
