----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_streamer is
  generic (
    IMG_WIDTH  : integer := 1920;
    IMG_HEIGHT : integer := 1080;
    IMG_FRAMES : integer := 3;
    IMG_VSYNC  : integer := 20;
    IMG_HSYNC  : integer := 50;
    STRM_BLANK : integer := 5000
  );
  port (
    red           : in std_logic_vector(9 downto 0);
    green         : in std_logic_vector(9 downto 0);
    blue          : in std_logic_vector(9 downto 0);

    clk_cnt       : out std_logic_vector(31 downto 0);

    m_axis_aclk   : in std_logic;
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis_tdata  : out std_logic_vector(31 downto 0);
    m_axis_tlast  : out std_logic;
    m_axis_tuser  : out std_logic_vector(0 downto 0);
    m_axis_fsync  : out std_logic
  );
end entity;

architecture behavioral of tmds_streamer is
  constant PX_CNT_MAX : integer := (IMG_WIDTH + IMG_HSYNC) *
                                   (IMG_HEIGHT + IMG_VSYNC) *
                                   IMG_FRAMES + (2 * STRM_BLANK); -- 2xHD

  constant PX_TLAST_INTERVAL : integer := IMG_WIDTH + IMG_HSYNC;

  signal clk_cnt_i : unsigned(31 downto 0);
begin

  process(m_axis_aclk)
  begin
    if rising_edge(m_axis_aclk) then
      clk_cnt <= std_logic_vector(clk_cnt_i);
      clk_cnt_i <= clk_cnt_i + 1;
    end if;
  end process;

  process(m_axis_aclk)
    variable px_cnt : integer range 0 to PX_CNT_MAX;
    variable next_tlast : integer range 0 to PX_CNT_MAX + PX_TLAST_INTERVAL;
  begin
    if rising_edge(m_axis_aclk) then
      if m_axis_tready = '0' then
        px_cnt := 0;
        m_axis_tvalid <= '0';
        m_axis_fsync <= '0';
        m_axis_tuser(0) <= '0';
        m_axis_tlast <= '0';
        next_tlast := STRM_BLANK + PX_TLAST_INTERVAL;
      else
        case px_cnt is
          when 0 =>
            next_tlast := STRM_BLANK + PX_TLAST_INTERVAL;
            m_axis_tvalid <= '0';
            m_axis_fsync <= '1';
            m_axis_tuser(0) <= '1';
          when 1 to STRM_BLANK =>
            m_axis_fsync <= '0';
            m_axis_tuser(0) <= '0';
          when STRM_BLANK + 1 to PX_CNT_MAX - STRM_BLANK - 1 =>
            m_axis_tvalid <= '1';
            if px_cnt = next_tlast then
              next_tlast := next_tlast + PX_TLAST_INTERVAL;
              m_axis_tlast <= '1';
            else
              m_axis_tlast <= '0';
            end if;
          when PX_CNT_MAX - STRM_BLANK =>
            m_axis_tlast <= '1';
          when PX_CNT_MAX - STRM_BLANK + 1 =>
            m_axis_tvalid <= '0';
            m_axis_tlast <= '0';
          when others =>
            null;
        end case;

        if px_cnt < PX_CNT_MAX then
          px_cnt := px_cnt + 1;
        else
          px_cnt := 0;
        end if;
      end if;
    end if;
  end process;

  m_axis_tdata <= "00" & blue & green & red;

end architecture;
