----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity sniffer_v1_0 is
  generic (
    C_S00_AXI_DATA_WIDTH  : integer := 32;
    C_S00_AXI_ADDR_WIDTH  : integer := 6;
    C_M00_AXIS_TDATA_WIDTH  : integer := 32;
    C_M00_AXIS_START_COUNT  : integer := 32
  );
  port (
    tmds_clk      : in std_logic;

    tmds_blue     : in std_logic_vector(9 downto 0);
    tmds_green    : in std_logic_vector(9 downto 0);
    tmds_red      : in std_logic_vector(9 downto 0);

    data_ready    : in std_logic;

    sysclk        : in std_logic;

    pixel_clk     : out std_logic;

    mode_rgb      : out std_logic;
    mode_tmds     : out std_logic;
    mode_err      : out std_logic;

    s00_axi_aclk    : in std_logic;
    s00_axi_aresetn : in std_logic;
    s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot  : in std_logic_vector(2 downto 0);
    s00_axi_awvalid : in std_logic;
    s00_axi_awready : out std_logic;
    s00_axi_wdata   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid  : in std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp   : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in std_logic;
    s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid : in std_logic;
    s00_axi_arready : out std_logic;
    s00_axi_rdata   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp   : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in std_logic;

    m00_axis_aclk    : in std_logic;
    m00_axis_aresetn : in std_logic;
    m00_axis_tvalid  : out std_logic;
    m00_axis_tdata   : out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
    m00_axis_tuser   : out std_logic_vector(0 downto 0);
    m00_axis_tlast   : out std_logic;
    m00_axis_tready  : in std_logic;

    m00_axis_fsync   : out std_logic
  );
end sniffer_v1_0;

architecture arch_imp of sniffer_v1_0 is
    component decoder
      port (
        clk        : in  std_logic;
        data_raw   : in  std_logic_vector(9 downto 0);
        data_ready : in  std_logic;
        c0         : out std_logic;
        c1         : out std_logic;
        vde        : out std_logic;
        vdout      : out std_logic_vector(7 downto 0)
      );
    end component;

    component rgb_streamer is
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
    end component;

    component tmds_streamer is
    generic (
      IMG_WIDTH  : integer;
      IMG_HEIGHT : integer;
      IMG_FRAMES : integer;
      IMG_VSYNC  : integer;
      IMG_HSYNC  : integer;
      STRM_BLANK : integer
    );
    port (
      red           : in  std_logic_vector(9 downto 0);
      green         : in  std_logic_vector(9 downto 0);
      blue          : in  std_logic_vector(9 downto 0);

      clk_cnt       : out std_logic_vector(31 downto 0);

      m_axis_aclk   : in  std_logic;
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis_tdata  : out std_logic_vector(31 downto 0);
      m_axis_tlast  : out std_logic;
      m_axis_tuser  : out std_logic_vector(0 downto 0);
      m_axis_fsync  : out std_logic
    );
    end component;

    -- component declaration
    component sniffer_v1_0_S00_AXI is
    generic (
        C_S_AXI_DATA_WIDTH : integer := C_S00_AXI_ADDR_WIDTH;
        C_S_AXI_ADDR_WIDTH : integer := C_S00_AXI_ADDR_WIDTH
    );
    port (
        MODE_REG      : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
        RES_X         : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
        RES_Y         : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
        TMDS_CLK_CNT  : in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

        S_AXI_ACLK    : in std_logic;
        S_AXI_ARESETN : in std_logic;
        S_AXI_AWADDR  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
        S_AXI_AWVALID : in std_logic;
        S_AXI_AWREADY : out std_logic;
        S_AXI_WDATA   : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB   : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
        S_AXI_WVALID  : in std_logic;
        S_AXI_WREADY  : out std_logic;
        S_AXI_BRESP   : out std_logic_vector(1 downto 0);
        S_AXI_BVALID  : out std_logic;
        S_AXI_BREADY  : in std_logic;
        S_AXI_ARADDR  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
        S_AXI_ARVALID : in std_logic;
        S_AXI_ARREADY : out std_logic;
        S_AXI_RDATA   : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP   : out std_logic_vector(1 downto 0);
        S_AXI_RVALID  : out std_logic;
        S_AXI_RREADY  : in std_logic
    );
    end component sniffer_v1_0_S00_AXI;

    signal MODE_REG : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal res_x_reg : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal res_y_reg : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal rgb_res_x : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal rgb_res_y : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal tmds_clk_cnt : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    signal refclk, lckd : std_logic;
    signal blue_rdy, green_rdy, red_rdy : std_logic;
    signal blue_vld, green_vld, red_vld : std_logic;
    signal red_int, green_int, blue_int : std_logic_vector(7 downto 0);
    signal ctrl_int : std_logic_vector(7 downto 0) := (others => '0');
    signal vsync_int, hsync_int : std_logic;
    signal blue_vde, green_vde, red_vde : std_logic;
    signal sysrst : std_logic;

    signal found_vld_openeye : std_logic;
    signal psalgnerr : std_logic;
    signal idelay_cnt_out : std_logic_vector(4 downto 0);
    signal bitslip_cntr : std_logic_vector(3 downto 0);

    signal m00_axis_tvalid_rgb  : std_logic;
    signal m00_axis_tdata_rgb   : std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
    signal m00_axis_tuser_rgb   : std_logic_vector(0 downto 0);
    signal m00_axis_tlast_rgb   : std_logic;
    signal m00_axis_fsync_rgb   : std_logic;

    signal m00_axis_tvalid_tmds : std_logic;
    signal m00_axis_tdata_tmds  : std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
    signal m00_axis_tuser_tmds  : std_logic_vector(0 downto 0);
    signal m00_axis_tlast_tmds  : std_logic;
    signal m00_axis_fsync_tmds  : std_logic;

    constant C_MODE_RGB  : std_logic_vector (C_M00_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    constant C_MODE_TMDS : std_logic_vector (C_M00_AXIS_TDATA_WIDTH-1 downto 0) := (0 => '1', others => '0');

    constant C_TMDS_STREAM_IMG_WIDTH  : integer := 1920;
    constant C_TMDS_STREAM_IMG_HEIGHT : integer := 1080;
    constant C_TMDS_STREAM_IMG_FRAMES : integer := 3;
    constant C_TMDS_STREAM_IMG_VSYNC  : integer := 20;
    constant C_TMDS_STREAM_IMG_HSYNC  : integer := 50;
    constant C_TMDS_STREAM_STRM_BLANK : integer := 500;

    constant C_TMDS_STREAM_RES_X      : integer := C_TMDS_STREAM_IMG_WIDTH + C_TMDS_STREAM_IMG_HSYNC;
    constant C_TMDS_STREAM_RES_Y      : integer := (C_TMDS_STREAM_IMG_HEIGHT + C_TMDS_STREAM_IMG_VSYNC) * C_TMDS_STREAM_IMG_FRAMES;

begin

pixel_clk <= tmds_clk;

lckd <= '1';
sysrst <= not lckd;

-- instantiate the decoders
bluedecoder: decoder
  port map(
    clk         => tmds_clk,
    data_raw    => tmds_blue,
    data_ready  => data_ready,
    c0          => hsync_int,
    c1          => vsync_int,
    vde         => blue_vde,
    vdout       => blue_int
  );

greendecoder: decoder
  port map(
    clk         => tmds_clk,
    data_raw    => tmds_green,
    data_ready  => data_ready,
    c0          => open,
    c1          => open,
    vde         => green_vde,
    vdout       => green_int
  );

reddecoder: decoder
  port map(
    clk         => tmds_clk,
    data_raw    => tmds_red,
    data_ready  => data_ready,
    c0          => open,
    c1          => open,
    vde         => red_vde,
    vdout       => red_int
  );

rgb_streamer_inst : rgb_streamer
  port map (
    red           => red_int,
    green         => green_int,
    blue          => blue_int,
    ctrl          => ctrl_int,
    enable        => blue_vde,

    hsync         => hsync_int,
    vsync         => vsync_int,

    m_axis_aclk   => m00_axis_aclk,
    m_axis_tvalid => m00_axis_tvalid_rgb,
    m_axis_tready => m00_axis_tready,
    m_axis_tdata  => m00_axis_tdata_rgb,
    m_axis_tlast  => m00_axis_tlast_rgb,
    m_axis_tuser  => m00_axis_tuser_rgb,
    m_axis_fsync  => m00_axis_fsync_rgb,
    img_res_x     => rgb_res_x,
    img_res_y     => rgb_res_y
  );

tmds_streamer_inst : tmds_streamer
  generic map (
    IMG_WIDTH  => C_TMDS_STREAM_IMG_WIDTH,
    IMG_HEIGHT => C_TMDS_STREAM_IMG_HEIGHT,
    IMG_FRAMES => C_TMDS_STREAM_IMG_FRAMES,
    IMG_VSYNC  => C_TMDS_STREAM_IMG_VSYNC,
    IMG_HSYNC  => C_TMDS_STREAM_IMG_HSYNC,
    STRM_BLANK => C_TMDS_STREAM_STRM_BLANK
  )
  port map (
    red           => tmds_red,
    green         => tmds_green,
    blue          => tmds_blue,

    clk_cnt       => tmds_clk_cnt,

    m_axis_aclk   => m00_axis_aclk,
    m_axis_tvalid => m00_axis_tvalid_tmds,
    m_axis_tready => m00_axis_tready,
    m_axis_tdata  => m00_axis_tdata_tmds,
    m_axis_tlast  => m00_axis_tlast_tmds,
    m_axis_tuser  => m00_axis_tuser_tmds,
    m_axis_fsync  => m00_axis_fsync_tmds
  );

  process (sysclk)
  begin
    if rising_edge(sysclk) then
      case MODE_REG is
        when C_MODE_RGB =>
          m00_axis_tvalid <= m00_axis_tvalid_rgb;
          m00_axis_tdata  <= m00_axis_tdata_rgb;
          m00_axis_tlast  <= m00_axis_tlast_rgb;
          m00_axis_tuser  <= m00_axis_tuser_rgb;
          m00_axis_fsync  <= m00_axis_fsync_rgb;
          res_x_reg       <= rgb_res_x;
          res_y_reg       <= rgb_res_y;
          mode_err        <= '0';
        when C_MODE_TMDS =>
          m00_axis_tvalid <= m00_axis_tvalid_tmds;
          m00_axis_tdata  <= m00_axis_tdata_tmds;
          m00_axis_tlast  <= m00_axis_tlast_tmds;
          m00_axis_tuser  <= m00_axis_tuser_tmds;
          m00_axis_fsync  <= m00_axis_fsync_tmds;
          res_x_reg       <= std_logic_vector(to_unsigned(C_TMDS_STREAM_RES_X, res_x_reg'length));
          res_y_reg       <= std_logic_vector(to_unsigned(C_TMDS_STREAM_RES_Y, res_y_reg'length));
          mode_err        <= '0';
        when others =>
          m00_axis_tvalid <= '0';
          m00_axis_tdata  <= (others => '0');
          m00_axis_tlast  <= '0';
          m00_axis_tuser  <= "0";
          m00_axis_fsync  <= '0';
          mode_err        <= '1';
      end case;
    end if;
  end process;

  mode_tmds <= '1' when MODE_REG = C_MODE_TMDS else '0';
  mode_rgb  <= '1' when MODE_REG = C_MODE_RGB else '0';

-- Instantiation of Axi Bus Interface S00_AXI
sniffer_v1_0_S00_AXI_inst : sniffer_v1_0_S00_AXI
  generic map (
    C_S_AXI_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH  => C_S00_AXI_ADDR_WIDTH
  )
  port map (
    MODE_REG      => MODE_REG,
    RES_X         => res_x_reg,
    RES_Y         => res_y_reg,
    TMDS_CLK_CNT  => tmds_clk_cnt,
    S_AXI_ACLK    => s00_axi_aclk,
    S_AXI_ARESETN => s00_axi_aresetn,
    S_AXI_AWADDR  => s00_axi_awaddr,
    S_AXI_AWPROT  => s00_axi_awprot,
    S_AXI_AWVALID => s00_axi_awvalid,
    S_AXI_AWREADY => s00_axi_awready,
    S_AXI_WDATA   => s00_axi_wdata,
    S_AXI_WSTRB   => s00_axi_wstrb,
    S_AXI_WVALID  => s00_axi_wvalid,
    S_AXI_WREADY  => s00_axi_wready,
    S_AXI_BRESP   => s00_axi_bresp,
    S_AXI_BVALID  => s00_axi_bvalid,
    S_AXI_BREADY  => s00_axi_bready,
    S_AXI_ARADDR  => s00_axi_araddr,
    S_AXI_ARPROT  => s00_axi_arprot,
    S_AXI_ARVALID => s00_axi_arvalid,
    S_AXI_ARREADY => s00_axi_arready,
    S_AXI_RDATA   => s00_axi_rdata,
    S_AXI_RRESP   => s00_axi_rresp,
    S_AXI_RVALID  => s00_axi_rvalid,
    S_AXI_RREADY  => s00_axi_rready
  );
end arch_imp;
