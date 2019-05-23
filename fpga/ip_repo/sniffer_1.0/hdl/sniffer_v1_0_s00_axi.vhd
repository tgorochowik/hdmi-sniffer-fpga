----------------------------------------------------------------------------------
-- Company: Antmicro Ltd
-- Engineer: Tomasz Gorochowik <tgorochowik@antmicro.com>
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sniffer_v1_0_S00_AXI is
  generic (
    C_S_AXI_DATA_WIDTH  : integer  := 32;
    C_S_AXI_ADDR_WIDTH  : integer  := 6
  );
  port (
    MODE_REG     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    RES_X        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    RES_Y        : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    TMDS_CLK_CNT : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    -- Generic AXI signals
    S_AXI_ACLK    : in std_logic;
    S_AXI_ARESETN  : in std_logic;
    S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    S_AXI_AWVALID  : in std_logic;
    S_AXI_AWREADY  : out std_logic;
    S_AXI_WDATA    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WVALID  : in std_logic;
    S_AXI_WREADY  : out std_logic;
    S_AXI_BRESP    : out std_logic_vector(1 downto 0);
    S_AXI_BVALID  : out std_logic;
    S_AXI_BREADY  : in std_logic;
    S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
    S_AXI_ARVALID  : in std_logic;
    S_AXI_ARREADY  : out std_logic;
    S_AXI_RDATA    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP    : out std_logic_vector(1 downto 0);
    S_AXI_RVALID  : out std_logic;
    S_AXI_RREADY  : in std_logic
  );
end sniffer_v1_0_S00_AXI;

architecture arch_imp of sniffer_v1_0_S00_AXI is

  -- AXI4LITE signals
  signal axi_awaddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready  : std_logic;
  signal axi_wready  : std_logic;
  signal axi_bresp  : std_logic_vector(1 downto 0);
  signal axi_bvalid  : std_logic;
  signal axi_araddr  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready  : std_logic;
  signal axi_rdata  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp  : std_logic_vector(1 downto 0);
  signal axi_rvalid  : std_logic;

  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := 3;

  signal slv_reg_rden  : std_logic;
  signal slv_reg_wren  : std_logic;
  signal reg_data_out  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal byte_index  : integer;

  -- register signals
  signal mode_reg_i    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
begin

  -- Connect registers to outputs
  MODE_REG <= mode_reg_i;

  -- I/O Connections assignments
  S_AXI_AWREADY  <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP  <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY  <= axi_arready;
  S_AXI_RDATA  <= axi_rdata;
  S_AXI_RRESP  <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;

  -- GENERIC AXI PROCESSES
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          axi_awready <= '1';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          axi_awaddr <= S_AXI_AWADDR;
        end if;
      end if;
    end if;
  end process;

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_wready <= '0';
      else
        if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1') then
            axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process;

  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00";
      else
        if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
          axi_bvalid <= '1';
          axi_bresp  <= "00";
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '1');
      else
        if (axi_arready = '0' and S_AXI_ARVALID = '1') then
          axi_arready <= '1';
          axi_araddr  <= S_AXI_ARADDR;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
      else
        if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
          axi_rvalid <= '1';
          axi_rresp  <= "00";
        elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

  process (S_AXI_ACLK) is
  begin
    if (rising_edge (S_AXI_ACLK)) then
      if ( S_AXI_ARESETN = '0' ) then
        axi_rdata  <= (others => '0');
      else
        if (slv_reg_rden = '1') then
            axi_rdata <= reg_data_out;
        end if;
      end if;
    end if;
  end process;
  -- END OF GENERIC AXI PROCESSES

  -- CUSTOM PROCESSES
  -- Proces for reading registers
  process (mode_reg_i, S_AXI_ARESETN, slv_reg_rden)
  variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
  begin
      -- Address decoding for reading registers
      loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
      case loc_addr is
        when b"0000" =>
          reg_data_out <= mode_reg_i;
        when b"0001" =>
          reg_data_out <= res_x;
        when b"0010" =>
          reg_data_out <= res_y;
        when b"0011" =>
          reg_data_out <= tmds_clk_cnt;
        when others =>
          reg_data_out  <= (others => '0');
      end case;
  end process;

  -- Process for writing registers
  process (S_AXI_ACLK)
  variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
  begin
    if rising_edge(S_AXI_ACLK) then
      if S_AXI_ARESETN = '0' then
        mode_reg_i <= (others => '0');
      else
        loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
        if (slv_reg_wren = '1') then
          case loc_addr is
            when b"0000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  mode_reg_i(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when others =>
              mode_reg_i <= mode_reg_i;
          end case;
        end if;
      end if;
    end if;
  end process;
  -- END OF CUSTOM PROCESSES
end arch_imp;
