------------------------------------------------------------------------------
--  LEON3 Demonstration design
--  Copyright (C) 2011 Jiri Gaisler, Gaisler Research
--
--  Modified by Joris van Rantwijk to support Digilent Atlys board.
--
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2023, Cobham Gaisler
--  Copyright (C) 2023 - 2025, Frontgrade Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; version 2.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
------------------------------------------------------------------------------

-- led(6) = dsuact         (LED 6 ON when processor in debug mode)
-- led(7) = not errorn     (LED 7 ON when processor in error mode)
-- switch(6) = dsubre      (SWITCH 6 ON to force DSU break)
-- switch(7) = dsuen       (SWITCH 7 ON to enable debug mode)

library ieee;
use ieee.std_logic_1164.all;
library grlib, techmap;
use grlib.amba.all;
use grlib.amba.all;
use grlib.stdlib.all;
use techmap.gencomp.all;
use techmap.allclkgen.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.ddrpkg.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.spi.all;
use gaisler.net.all;
use gaisler.jtag.all;
-- pragma translate_off
use gaisler.sim.all;
-- pragma translate_on

library esa;
use esa.memoryctrl.all;

library unisim;
use unisim.vcomponents.OBUFDS;

use work.config.all;

entity leon3mp is
  generic (
    fabtech       : integer := CFG_FABTECH;
    memtech       : integer := CFG_MEMTECH;
    padtech       : integer := CFG_PADTECH;
    clktech       : integer := CFG_CLKTECH;
    disas         : integer := CFG_DISAS;   -- Enable disassembly to console
    dbguart       : integer := CFG_DUART;   -- Print UART on console
    pclow         : integer := CFG_PCLOW
  );
  port (
    resetn      : in  std_ulogic;
    clk         : in  std_ulogic;           -- 100 MHz board clock

    -- DDR2 memory
    ddr_clk     : out std_logic;
    ddr_clkb    : out std_logic;
    ddr_cke     : out std_logic;
    ddr_odt     : out std_logic;
    ddr_we      : out std_ulogic;
    ddr_ras     : out std_ulogic;
    ddr_cas     : out std_ulogic;
    ddr_dm      : out std_logic_vector (1 downto 0);
    ddr_dqs     : inout std_logic_vector (1 downto 0);
    ddr_dqsn    : inout std_logic_vector (1 downto 0);
    ddr_ad      : out std_logic_vector (12 downto 0);
    ddr_ba      : out std_logic_vector (2 downto 0);
    ddr_dq      : inout std_logic_vector (15 downto 0);
    ddr_rzq     : inout std_ulogic;
    ddr_zio     : inout std_ulogic;
 
--    dsuen        : in std_ulogic;     -- switch(7)
--    dsubre       : in std_ulogic;     -- switch(6)
--    dsuact       : out std_ulogic;    -- led(6)
--    errorn       : out std_ulogic;    -- led(7)

    txd1        : out std_ulogic;          -- UART1 tx data
    rxd1        : in  std_ulogic;          -- UART1 rx data

    -- GPIO
    pmoda       : inout std_logic_vector(7 downto 0);
    switch      : in std_logic_vector(7 downto 0);
    led         : out std_logic_vector(7 downto 0);
    button      : in std_logic_vector(4 downto 0);

    -- MII Ethernet
    erx_clk     : in std_ulogic; 
    erxd        : in std_logic_vector(7 downto 0);
    erx_dv      : in std_ulogic;
    erx_er      : in std_ulogic;
    erx_col     : in std_ulogic;
    erx_crs     : in std_ulogic;
    etx_clk     : in std_ulogic; 
    etxd        : out std_logic_vector(7 downto 0);
    etx_en      : out std_ulogic;
    etx_er      : out std_ulogic;
    erst        : out std_ulogic;
    egtxclk     : out std_ulogic;
    emdc        : out std_ulogic;
    emdio       : inout std_logic;
    emdint      : in std_ulogic;

    -- PS/2
    kbd_clk     : inout std_logic;
    kbd_data    : inout std_logic;
    mou_clk     : inout std_logic;
    mou_data    : inout std_logic;

    -- SPI flash
    spi_sel_n   : inout std_ulogic;
    spi_clk     : out   std_ulogic;
    spi_dq1     : inout std_logic;     -- MISO
    spi_dq0     : inout std_logic;      -- MOSI
    spi_dq2     : inout std_logic;
    spi_dq3     : inout std_logic;
    
    -- HDMI port
    tmdstx_clk_p : out std_logic;
    tmdstx_clk_n : out std_logic;
    tmdstx_dat_p : out std_logic_vector(2 downto 0);
    tmdstx_dat_n : out std_logic_vector(2 downto 0)
  );

end entity;

architecture rtl of leon3mp is

  attribute syn_netlist_hierarchy : boolean;
  attribute syn_netlist_hierarchy of rtl : architecture is false;

  constant maxahbm : integer := CFG_NCPU+CFG_AHB_UART+CFG_GRETH+CFG_AHB_JTAG;

  signal vcc, gnd   : std_logic;
  signal memi  : memory_in_type;
  signal memo  : memory_out_type;
  signal wpo   : wprot_out_type;
  signal sdo   : sdram_out_type;

  signal apbi  : apb_slv_in_type;
  signal apbo  : apb_slv_out_vector := (others => apb_none);
  signal ahbsi : ahb_slv_in_type;
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
  signal ahbmi : ahb_mst_in_type;
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

  signal clkm, rstn, rstraw : std_ulogic;
  signal clk200 : std_ulogic;

  signal cgi  : clkgen_in_type;
  signal cgo  : clkgen_out_type;
  signal u1i, dui : uart_in_type;
  signal u1o, duo : uart_out_type;

  signal irqi : irq_in_vector(0 to CFG_NCPU-1);
  signal irqo : irq_out_vector(0 to CFG_NCPU-1);

  signal dbgi : l3_debug_in_vector(0 to CFG_NCPU-1);
  signal dbgo : l3_debug_out_vector(0 to CFG_NCPU-1);

  signal dsui : dsu_in_type;
  signal dsuo : dsu_out_type; 

  signal ethi : eth_in_type;
  signal etho : eth_out_type;

  signal gpti : gptimer_in_type;
  signal gpto : gptimer_out_type;

  signal gpioi : gpio_in_type;
  signal gpioo : gpio_out_type;

  signal lock, calib_done, lclk : std_ulogic;
  signal rstext   : std_ulogic;
  signal rstint   : std_ulogic;
  signal errorp   : std_ulogic;
  signal tck, tckn, tms, tdi, tdo : std_ulogic;

  signal ddr2clk : std_ulogic;
  signal ddr0_clk_fb : std_ulogic;
  signal ddr0_clk : std_logic_vector(2 downto 0);
  signal ddr0_clkb : std_logic_vector(2 downto 0);
  signal ddr0_cke : std_logic_vector(1 downto 0);
  signal ddr0_odt : std_logic_vector(1 downto 0);
  signal ddr0_ad : std_logic_vector(13 downto 0);
  signal ddr0_lock: std_ulogic;

  signal spmi : spimctrl_in_type;
  signal spmo : spimctrl_out_type;
  
  signal spii : spi_in_type;
  signal spio : spi_out_type;
  signal slvsel : std_logic_vector(CFG_SPICTRL_SLVS-1 downto 0);
  
  signal kbdi : ps2_in_type;
  signal kbdo : ps2_out_type;
  signal moui : ps2_in_type;
  signal mouo : ps2_out_type;
  signal vgao : apbvga_out_type;

  signal video_clk     : std_logic;
  signal video_fastclk : std_logic;
  signal video_clksel  : std_logic_vector(1 downto 0);
  signal tmds_clk      : std_logic;
  signal tmds_dat      : std_logic_vector(2 downto 0);

  constant BOARD_FREQ : integer := 100000;   -- input frequency in KHz
  constant CPU_FREQ   : integer := BOARD_FREQ * CFG_CLKMUL / CFG_CLKDIV;  -- cpu frequency in KHz
  constant IOAEN : integer := 1;
--  constant DDR2_FREQ  : integer := 150000;                                -- DDR2 input frequency in KHz

  signal stati : ahbstat_in_type;

  signal leon_rstn : std_ulogic;
  
  signal fpi : grfpu_in_vector_type;
  signal fpo : grfpu_out_vector_type;

  attribute keep : boolean;
  attribute syn_keep : boolean;
  attribute syn_preserve : boolean;
  attribute syn_preserve of ddr2clk : signal is true;
  attribute keep of ddr2clk : signal is true;
  attribute syn_preserve of clkm : signal is true;
  attribute keep of clkm : signal is true;
  attribute syn_preserve of video_clk : signal is true;
  attribute keep of video_clk : signal is true;
  attribute syn_preserve of video_fastclk : signal is true;
  attribute keep of video_fastclk : signal is true;

begin

----------------------------------------------------------------------
---  Reset and Clock generation  -------------------------------------
----------------------------------------------------------------------
  
  vcc <= '1'; gnd <= '0';
  cgi.pllctrl <= "00"; cgi.pllrst <= rstraw;

  clk_pad : clkpad generic map (tech => padtech) port map (clk, lclk); 

  clkgen0 : clkgen        -- clock generator
    generic map (clktech, CFG_CLKMUL, CFG_CLKDIV, CFG_MCTRL_SDEN,
                 CFG_CLK_NOFB, 0, 0, 0, BOARD_FREQ)
    port map (clkin => lclk, pciclkin => lclk,
              clk => clkm, clkn => open, clk2x => open,
              sdclk => open, pciclk => open,
              cgi => cgi, cgo => cgo,
              clk4x => open, clk1xu => open, clk2xu => clk200);

  resetn_pad : inpad generic map (tech => padtech) port map (resetn, rstext);
  rst0 : rstgen         -- reset generator
    port map (rstint, clkm, lock, rstn, rstraw);
  lock <= cgo.clklock and ddr0_lock;

  -- Generate clean internal reset from external reset and watchdog.
  rst1 : process (lclk, rstext) is
    variable v_shift: std_logic_vector(3 downto 0);
    variable v_wdog:  std_logic_vector(2 downto 0);
  begin
    if rstext = '0' then
      rstint <= '0';
      v_shift := (others => '0');
      v_wdog  := (others => '0');
    elsif rising_edge(lclk) then
      rstint <= v_shift(0);
      if CFG_GPT_WDOGEN /= 0 and v_wdog(0) = '1' then
        v_shift := (others => '0');
      else
        v_shift := '1' & v_shift(3 downto 1);
      end if;
      if CFG_GPT_WDOGEN /= 0 then
        v_wdog(0) := v_wdog(2) and not v_wdog(1);
        v_wdog(1) := v_wdog(2);
        v_wdog(2) := gpto.wdog;
      end if;
    end if;
  end process;

  leon_rstn <= rstn and spmo.initialized;

----------------------------------------------------------------------
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl       -- AHB arbiter/multiplexer
  generic map (defmast => CFG_DEFMST, split => CFG_SPLIT, 
   rrobin => CFG_RROBIN, ioaddr => CFG_AHBIO,
   ioen => IOAEN, nahbm => maxahbm, nahbs => 16)
  port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  nosh : if CFG_GRFPUSH = 0 generate
    cpu : for i in 0 to CFG_NCPU-1 generate
      l3ft : if CFG_LEON3FT_EN /= 0 generate
        leon3ft0 : leon3ft		-- LEON3 processor      
        generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8, 
  	  0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE, 
	  CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
	  CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
          CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP, 
          CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
	  CFG_IUFT_EN, CFG_FPUFT_EN, CFG_CACHE_FT_EN, CFG_RF_ERRINJ, 
	  CFG_CACHE_ERRINJ, CFG_DFIXED, CFG_LEON3_NETLIST, CFG_SCAN, CFG_MMU_PAGE,
          CFG_BP, CFG_NP_ASI, CFG_WRPSR)
        port map (clkm, leon_rstn, ahbmi, ahbmo(i), ahbsi, ahbso, 
    		irqi(i), irqo(i), dbgi(i), dbgo(i), clkm);
      end generate;

      l3s : if CFG_LEON3FT_EN = 0 generate
        u0 : leon3s 		-- LEON3 processor
        generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8,
	  0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE,
	  CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
	  CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
          CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP,
          CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
	  CFG_DFIXED, CFG_SCAN, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
        port map (clkm, leon_rstn, ahbmi, ahbmo(i), ahbsi, ahbso,
    		irqi(i), irqo(i), dbgi(i), dbgo(i));
      end generate;
    end generate;
  end generate;

  sh : if CFG_GRFPUSH = 1 generate
    cpu : for i in 0 to CFG_NCPU-1 generate
      l3ft : if CFG_LEON3FT_EN /= 0 generate
        leon3ft0 : leon3ftsh		-- LEON3 processor      
        generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8, 
  	  0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE, 
	  CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
	  CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
          CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP, 
          CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
	  CFG_IUFT_EN, CFG_FPUFT_EN, CFG_CACHE_FT_EN, CFG_RF_ERRINJ, 
	  CFG_CACHE_ERRINJ, CFG_DFIXED, CFG_LEON3_NETLIST, CFG_SCAN, CFG_MMU_PAGE,
          CFG_BP, CFG_NP_ASI, CFG_WRPSR)
        port map (clkm, leon_rstn, ahbmi, ahbmo(i), ahbsi, ahbso, 
    		irqi(i), irqo(i), dbgi(i), dbgo(i), clkm,  fpi(i), fpo(i));

      end generate;
      l3s : if CFG_LEON3FT_EN = 0 generate
        u0 : leon3sh 		-- LEON3 processor
        generic map (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8,
	  0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE,
	  CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
	  CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
          CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP,
          CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR, CFG_NCPU-1,
	  CFG_DFIXED, CFG_SCAN, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR)
        port map (clkm, leon_rstn, ahbmi, ahbmo(i), ahbsi, ahbso,
    		irqi(i), irqo(i), dbgi(i), dbgo(i), fpi(i), fpo(i));
      end generate;
    end generate;

    grfpush0 : grfpushwx generic map ((CFG_FPU-1), CFG_NCPU, fabtech)
    port map (clkm, rstn, fpi, fpo);

  end generate;

  -- LED(7) = error
  errorp <= not dbgo(0).error;
  led1_pad : outpad generic map (tech => padtech) port map (led(7), errorp);

  dsugen : if CFG_DSU = 1 generate
      dsu0 : dsu3         -- LEON3 Debug Support Unit
      generic map (hindex => 2, haddr => 16#900#, hmask => 16#F00#, 
         ncpu => CFG_NCPU, tbits => 30, tech => memtech, irq => 0, kbytes => CFG_ATBSZ)
      port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);
  end generate;

  nodsu : if CFG_DSU = 0 generate 
    dsuo.tstop <= '0'; dsuo.active <= '0'; ahbso(2) <= ahbs_none;
  end generate;

  -- SWITCH(7) = dsuen
  dsuen_pad : inpad generic map (tech => padtech) port map (switch(7), dsui.enable);

  -- SWITCH(6) = dsubre
  dsubre_pad : inpad generic map (tech => padtech) port map (switch(6), dsui.break);

  -- LED(6) = dsuact
  dsuact_pad : outpad generic map (tech => padtech) port map (led(6), dsuo.active);

  dcomgen : if CFG_AHB_UART = 1 generate
    dcom0: ahbuart      -- Debug UART
    generic map (hindex => CFG_NCPU, pindex => 7, paddr => 7)
    port map (rstn, clkm, dui, duo, apbi, apbo(7), ahbmi, ahbmo(CFG_NCPU));
    dsurx_pad : inpad generic map (tech => padtech) port map (rxd1, dui.rxd); 
    dsutx_pad : outpad generic map (tech => padtech) port map (txd1, duo.txd);
  end generate;
  nouah : if CFG_AHB_UART = 0 generate apbo(7) <= apb_none; end generate;

  ahbjtaggen0 :if CFG_AHB_JTAG = 1 generate
    ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => CFG_NCPU+CFG_AHB_UART)
      port map(rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(CFG_NCPU+CFG_AHB_UART),
               open, open, open, open, open, open, open, gnd);
  end generate;
  
----------------------------------------------------------------------
---  Memory controllers ----------------------------------------------
----------------------------------------------------------------------

  mctrl_gen : if (CFG_MCTRL_LEON2 /= 0) generate

    memi.writen <= '1'; memi.wrn <= "1111"; memi.bwidth <= "00";
    memi.brdyn <= '0'; memi.bexcn <= '1';

    mctrl0 : mctrl generic map (hindex => 0, pindex => 0,
     paddr => 0, srbanks => 2, ram8 => CFG_MCTRL_RAM8BIT, 
     ram16 => CFG_MCTRL_RAM16BIT, sden => CFG_MCTRL_SDEN, 
     invclk => CFG_CLK_NOFB, sepbus => CFG_MCTRL_SEPBUS,
     pageburst => CFG_MCTRL_PAGE, rammask => 0, iomask => 0)
    port map (rstn, clkm, memi, memo, ahbsi, ahbso(0), apbi, apbo(0), wpo, sdo);

    memi.data <= (others => '0'); -- Atlys board has no asynchronous memory bus
    memi.sd   <= (others => '0'); -- Atlys board has no classic SDRAM

  end generate;

-----------------------------------------------------------------------
---  Test report module  ----------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off

  test0 : ahbrep generic map (hindex => 5, haddr => 16#200#)
	port map (rstn, clkm, ahbsi, ahbso(5));

-- pragma translate_on

----------------------------------------------------------------------
---  DDR2 memory controller ------------------------------------------
----------------------------------------------------------------------

  ddr_gen : if (CFG_DDR2SP = 1) generate
    ddr0: ddr2spa
      generic map (
        fabtech => fabtech,
        memtech => memtech,
        rskew => 0,
        hindex => 4,
        haddr => 16#400#,
        hmask => 16#f80#,
        ioaddr => 16#001#,
        iomask => 16#fff#,
        MHz => CPU_FREQ/1000,
        TRFC => CFG_DDR2SP_TRFC,
        clkmul => 6,
        clkdiv => 2,
        col => CFG_DDR2SP_COL,
        Mbyte => CFG_DDR2SP_SIZE,
        rstdel => 200,
        pwron => CFG_DDR2SP_INIT,
        ddrbits => CFG_DDR2SP_DATAWIDTH,
        ahbfreq => CPU_FREQ/1000,
        readdly => 1,
        norefclk => 0,
        odten => 3,
        dqsgating => 0,
        nosync => CFG_DDR2SP_NOSYNC,
        eightbanks => 1,
        dqsse => 0,
        burstlen => 8,
        ft => CFG_DDR2SP_FTEN,
        ftbits => CFG_DDR2SP_FTWIDTH,
        bigmem => 0,
        raspipe => 0 )
      port map (
        rst_ddr => rstraw,
        rst_ahb => rstn,
        clk_ddr => clkm,
        clk_ahb => clkm,
        clkref200 => clk200,
        lock    => ddr0_lock,
        clkddro => ddr2clk,
        clkddri => ddr2clk,
        ahbsi   => ahbsi,
        ahbso   => ahbso(4),
        ddr_clk => ddr0_clk,
        ddr_clkb => ddr0_clkb,
        ddr_clk_fb_out => ddr0_clk_fb,
        ddr_clk_fb => ddr0_clk_fb,
        ddr_cke => ddr0_cke,
        ddr_csb => open,
        ddr_web => ddr_we,
        ddr_rasb => ddr_ras,
        ddr_casb => ddr_cas,
        ddr_dm  => ddr_dm,
        ddr_dqs => ddr_dqs,
        ddr_dqsn => ddr_dqsn,
        ddr_ad  => ddr0_ad,
        ddr_ba  => ddr_ba,
        ddr_dq  => ddr_dq,
        ddr_odt => ddr0_odt,
        ce      => open );

    ddr_clk  <= ddr0_clk(0);
    ddr_clkb <= ddr0_clkb(0);
    ddr_cke  <= ddr0_cke(0);
    ddr_odt  <= ddr0_odt(0);
    ddr_ad   <= ddr0_ad(12 downto 0);
    ddr_rzq  <= 'Z';
    ddr_zio  <= 'Z';
  end generate;

  ddr_nogen : if (CFG_DDR2SP /= 1) generate
    ddr0_lock <= '1';
    ddrcke_nopad : outpad generic map (tech => padtech) port map (ddr_cke, gnd);
  end generate;

----------------------------------------------------------------------
---  SPI Memory Controller--------------------------------------------
----------------------------------------------------------------------

  -- Numonyx N25Q12 16 MByte SPI flash memory
  -- SPI memory controller is mapped at address 0 if AHBROM is disabled.
  -- If AHBROM is enabled then the SPI Flash area is mapped at 0xe0000000
  spimc: if CFG_SPIMCTRL = 1 generate
    spimctrl0 : spimctrl        -- SPI Memory Controller
      generic map (hindex => 3, hirq => 11, faddr => 16#e00#*CFG_AHBROMEN,
                   fmask => 16#ff0#,
                   ioaddr => 16#002#, iomask => 16#fff#,
                   spliten => CFG_SPLIT, oepol  => 0,
                   sdcard => CFG_SPIMCTRL_SDCARD,
                   readcmd => CFG_SPIMCTRL_READCMD,
                   dummybyte => CFG_SPIMCTRL_DUMMYBYTE,
                   dualoutput => CFG_SPIMCTRL_DUALOUTPUT,
                   scaler => CFG_SPIMCTRL_SCALER,
                   altscaler => CFG_SPIMCTRL_ASCALER,
                   pwrupcnt => CFG_SPIMCTRL_PWRUPCNT,
                   offset => CFG_SPIMCTRL_OFFSET)
      port map (rstn, clkm, ahbsi, ahbso(3), spmi, spmo); 

    miso_pad : inpad generic map (tech => padtech)
      port map (spi_dq1, spmi.miso);
    mosi_pad : iopad generic map (tech => padtech)
      port map (spi_dq0, spmo.mosi, spmo.mosioen , spmi.mosi);
    sck_pad  : outpad generic map (tech => padtech)
      port map (spi_clk, spmo.sck);
    spisel_pad : odpad generic map (tech => padtech)
      port map (spi_sel_n, spmo.csn);
  end generate;
  nospimc : if CFG_SPIMCTRL = 0 generate
    spmo.initialized <= '1';
  end generate;

----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  apb0 : apbctrl            -- AHB/APB bridge
  generic map (hindex => 1, haddr => CFG_APBADDR, nslaves => 16)
  port map (rstn, clkm, ahbsi, ahbso(1), apbi, apbo );

  ua1 : if CFG_UART1_ENABLE /= 0 generate
    uart1 : apbuart         -- UART 1
    generic map (pindex => 1, paddr => 1,  pirq => 2, console => dbguart,
   fifosize => CFG_UART1_FIFO)
    port map (rstn, clkm, apbi, apbo(1), u1i, u1o);
    u1i.extclk <= '0';
    u1i.ctsn <= '0';
    rxd1_pad : inpad generic map (tech => padtech) port map (rxd1, u1i.rxd); 
    txd1_pad : outpad generic map (tech => padtech) port map (txd1, u1o.txd);
  end generate;
  noua0 : if CFG_UART1_ENABLE = 0 generate apbo(1) <= apb_none; end generate;

  notxd : if CFG_UART1_ENABLE = 0 and CFG_AHB_UART = 0 generate
    notxd_pad : outpad generic map (tech => padtech) port map (txd1, vcc);
  end generate;

  irqctrl : if CFG_IRQ3_ENABLE /= 0 generate
    irqctrl0 : irqmp         -- interrupt controller
    generic map (pindex => 2, paddr => 2, ncpu => CFG_NCPU)
    port map (rstn, clkm, apbi, apbo(2), irqo, irqi);
  end generate;
  irq3 : if CFG_IRQ3_ENABLE = 0 generate
    x : for i in 0 to CFG_NCPU-1 generate
      irqi(i).irl <= "0000";
    end generate;
    apbo(2) <= apb_none;
  end generate;

  gpt : if CFG_GPT_ENABLE /= 0 generate
    timer0 : gptimer          -- timer unit
    generic map (pindex => 3, paddr => 3, pirq => CFG_GPT_IRQ, 
   sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW, ntimers => CFG_GPT_NTIM, 
   nbits => CFG_GPT_TW, wdog => CFG_GPT_WDOGEN*CFG_GPT_WDOG)
    port map (rstn, clkm, apbi, apbo(3), gpti, gpto);
    gpti <= gpti_dhalt_drive(dsuo.tstop);
  end generate;

  nogpt : if CFG_GPT_ENABLE = 0 generate apbo(3) <= apb_none; end generate;

  kbd : if CFG_KBD_ENABLE /= 0 generate
    ps21 : apbps2 generic map(pindex => 4, paddr => 4, pirq => 4)
      port map(rstn, clkm, apbi, apbo(4), moui, mouo);
    ps20 : apbps2 generic map(pindex => 5, paddr => 5, pirq => 5)
      port map(rstn, clkm, apbi, apbo(5), kbdi, kbdo);
  end generate;
  nokbd : if CFG_KBD_ENABLE = 0 generate 
   apbo(4) <= apb_none; mouo <= ps2o_none;
   apbo(5) <= apb_none; kbdo <= ps2o_none;
  end generate;
  kbdclk_pad : iopad generic map (tech => padtech)
      port map (kbd_clk, kbdo.ps2_clk_o, kbdo.ps2_clk_oe, kbdi.ps2_clk_i);
  kbdata_pad : iopad generic map (tech => padtech)
        port map (kbd_data, kbdo.ps2_data_o, kbdo.ps2_data_oe, kbdi.ps2_data_i);
  mouclk_pad : iopad generic map (tech => padtech)
      port map (mou_clk, mouo.ps2_clk_o, mouo.ps2_clk_oe, moui.ps2_clk_i);
  mouata_pad : iopad generic map (tech => padtech)
        port map (mou_data, mouo.ps2_data_o, mouo.ps2_data_oe, moui.ps2_data_i);

  gpio0 : if CFG_GRGPIO_ENABLE /= 0 generate     -- GPIO unit
    grgpio0: grgpio
      generic map (pindex => 10, paddr => 10, imask => CFG_GRGPIO_IMASK, nbits => 32)
      port map (rst => rstn, clk => clkm, apbi => apbi, apbo => apbo(10),
                gpioi => gpioi, gpioo => gpioo);

    -- Map GPIO bits 0 to 5 to LEDS 0 to 5.
    gpio_led_pads : outpadv
      generic map (tech => padtech, width => 6)
      port map (led(5 downto 0), gpioo.dout(5 downto 0));

    -- Map GPIO bits 8 to 13 to SWITCHES 0 to 5.
    gpio_sw_pads : inpadv
      generic map (tech => padtech, width => 6)
      port map (switch(5 downto 0), gpioi.din(13 downto 8));

    -- Map GPIO bits 16 to 20 to BUTTONS 0 to 4.
    gpio_button_pads : inpadv
      generic map (tech => padtech, width => 5)
      port map (button(4 downto 0), gpioi.din(20 downto 16));

    -- Map GPIO bits 24 to 31 to PMODA port.
    gpio_pmod_pads : for i in 0 to 7 generate
      gpio_pmod_padi : iopad
        generic map (tech => padtech)
        port map (pmoda(i), gpioo.dout(24+i), gpioo.oen(24+i), gpioi.din(24+i));
    end generate;

    gpioi.din(7 downto 0)   <= (others => '0');
    gpioi.din(15 downto 14) <= (others => '0');
    gpioi.din(23 downto 21) <= (others => '0');
  end generate;	

  spic: if CFG_SPICTRL_ENABLE = 1 and CFG_SPIMCTRL = 0 generate  -- SPI controller
    spi1 : spictrl
      generic map (pindex => 11, paddr  => 11, pmask  => 16#fff#, pirq => 12,
                   fdepth => CFG_SPICTRL_FIFO, slvselen => CFG_SPICTRL_SLVREG,
                   slvselsz => CFG_SPICTRL_SLVS, odmode => 0, netlist => 0,
                   syncram => CFG_SPICTRL_SYNCRAM, ft => CFG_SPICTRL_FT,
                   prot => CFG_SPICTRL_PROT)
      port map (rstn, clkm, apbi, apbo(11), spii, spio, slvsel);
    spii.spisel <= '1';                 -- Master only
    miso_pad : iopad generic map (tech => padtech)
      port map (spi_dq1, spio.miso, spio.misooen, spii.miso);
    mosi_pad : iopad generic map (tech => padtech)
      port map (spi_dq0, spio.mosi, spio.mosioen, spii.mosi);
    io2_pad : iopad generic map (tech => padtech)
      port map (spi_dq2, spio.io2, spio.io2oen, spii.io2);
    io3_pad : iopad generic map (tech => padtech)
      port map (spi_dq3, spio.io3, spio.io3oen, spii.io3);
    sck_pad  : outpad generic map (tech => padtech)
      port map (spi_clk, spio.sck);
    slvsel_pad : outpad generic map (tech => padtech)
      port map (spi_sel_n, slvsel(0));
  end generate spic;

  nospic: if CFG_SPICTRL_ENABLE = 0 or CFG_SPIMCTRL = 1 generate
    apbo(11) <= apb_none;
  end generate;
  
  ahbs : if CFG_AHBSTAT = 1 generate   -- AHB status register
    stati <= ahbstat_in_none;
    ahbstat0 : ahbstat generic map (pindex => 15, paddr => 15, pirq => 7,
   nftslv => CFG_AHBSTATN)
      port map (rstn, clkm, ahbmi, ahbsi, stati, apbi, apbo(15));
  end generate;

-----------------------------------------------------------------------
---  ETHERNET ---------------------------------------------------------
-----------------------------------------------------------------------

  eth0 : if CFG_GRETH = 1 generate -- Gaisler ethernet MAC
    e1 : grethm
      generic map (
        hindex => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG, 
        pindex => 14, paddr => 14, pirq => 12, memtech => memtech,
        mdcscaler => CPU_FREQ/1000, rmii => 0, enable_mdio => 1, fifosize => CFG_ETH_FIFO,
        nsync => 1, edcl => CFG_DSU_ETH, edclbufsz => CFG_ETH_BUF, phyrstadr => 7,
        macaddrh => CFG_ETH_ENM, macaddrl => CFG_ETH_ENL, enable_mdint => 1,
	ipaddrh => CFG_ETH_IPM, ipaddrl => CFG_ETH_IPL,
	giga => 0)
      port map (
        rst => rstn, clk => clkm, ahbmi => ahbmi,
        ahbmo => ahbmo(CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG), 
        apbi => apbi, apbo => apbo(14), ethi => ethi, etho => etho);

    etxc_pad : clkpad generic map (tech => padtech) 
      port map (etx_clk, ethi.tx_clk);
    erxc_pad : clkpad generic map (tech => padtech) 
      port map (erx_clk, ethi.rx_clk);
    erxd_pad : inpadv generic map (tech => padtech, width => 8) 
      port map (erxd, ethi.rxd(7 downto 0));
    erxdv_pad : inpad generic map (tech => padtech) 
      port map (erx_dv, ethi.rx_dv);
    erxer_pad : inpad generic map (tech => padtech) 
      port map (erx_er, ethi.rx_er);
    erxco_pad : inpad generic map (tech => padtech) 
      port map (erx_col, ethi.rx_col);
    erxcr_pad : inpad generic map (tech => padtech) 
      port map (erx_crs, ethi.rx_crs);
    etxd_pad : outpadv generic map (tech => padtech, width => 8) 
      port map (etxd, etho.txd(7 downto 0));
    etxen_pad : outpad generic map (tech => padtech) 
      port map (etx_en, etho.tx_en);
    etxer_pad : outpad generic map (tech => padtech) 
      port map (etx_er, etho.tx_er);

    emdc_pad : outpad generic map (tech => padtech) 
      port map (emdc, etho.mdc);
    emdio_pad : iopad generic map (tech => padtech) 
      port map (emdio, etho.mdio_o, etho.mdio_oe, ethi.mdio_i);
    emdint_pad : inpad generic map (tech => padtech) 
      port map (emdint, ethi.mdint);
  end generate;

  eth_nopads : if (CFG_GRETH /= 1) generate -- eth pads
    etxd_nopad : outpadv generic map (tech => padtech, width => 8) 
      port map (etxd, "00000000");
    etxen_nopad : outpad generic map (tech => padtech) 
      port map (etx_en, '0');
    etxer_nopad : outpad generic map (tech => padtech) 
      port map (etx_er, '0');
    emdc_nopad : outpad generic map (tech => padtech) 
      port map (emdc, '0');
    emdio_nopad : iopad generic map (tech => padtech) 
      port map (emdio, '0', '1', open);
  end generate;

  erst_pad : outpad generic map (tech => padtech)
    port map (erst, rstraw);

  egtxclk_pad : outpad generic map (tech => padtech)
    port map (egtxclk, '0');

  ethi.gtx_clk <= '0';

-----------------------------------------------------------------------
---  AHB ROM ----------------------------------------------------------
-----------------------------------------------------------------------

  bromgen : if CFG_AHBROMEN /= 0 generate 
    brom : entity work.ahbrom
      generic map (hindex => 6, haddr => CFG_AHBRODDR, pipe => CFG_AHBROPIP )
      port map (rstn, clkm, ahbsi, ahbso(6));
  end generate;

-----------------------------------------------------------------------
---  AHB RAM ----------------------------------------------------------
-----------------------------------------------------------------------

  ocram : if CFG_AHBRAMEN = 1 generate 
    ahbram0 : ahbram generic map (hindex => 7, haddr => CFG_AHBRADDR, 
   tech => CFG_MEMTECH, kbytes => CFG_AHBRSZ)
    port map ( rstn, clkm, ahbsi, ahbso(7));
  end generate;

-----------------------------------------------------------------------
---  VGA / HDMI  ------------------------------------------------------
-----------------------------------------------------------------------

  vga : if CFG_VGA_ENABLE /= 0 generate
    vga0 : apbvga
      generic map(memtech => memtech, pindex => 6, paddr => 6)
      port map(rstn, clkm, video_clk, apbi, apbo(6), vgao);
    video_clksel <= "00"; -- fixed 25 MHz
   end generate;
  
  svga : if CFG_SVGA_ENABLE /= 0 generate
    svga0 : svgactrl
      generic map(memtech => memtech, pindex => 6, paddr => 6,
        hindex => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH, 
        clk0 => 40000, clk1 => 25000, clk2 => 40000, clk3 => 25000,
        burstlen => 6)
      port map(rstn, clkm, video_clk, apbi, apbo(6), vgao,
               ahbmi, ahbmo(CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+CFG_GRETH),
               video_clksel);
  end generate;

  tmds : if CFG_VGA_ENABLE /= 0 or CFG_SVGA_ENABLE /= 0 generate
    vgaclk0 : entity work.vga_clkgen
      port map (resetn => rstraw, clk100 => lclk, sel => video_clksel,
                vgaclk => video_clk, fastclk => video_fastclk);
    tmds0 : entity work.vga2tmds
      generic map (tech => fabtech)
      port map (vgaclk => video_clk, fastclk => video_fastclk, vgao => vgao,
                tmdsclk => tmds_clk, tmdsdat => tmds_dat );
    tmdsc_pad : OBUFDS
      port map (O => tmdstx_clk_p, OB => tmdstx_clk_n, I => tmds_clk);
    tmdsd_pad : for i in 0 to 2 generate
      tmdsdi_pad : OBUFDS
        port map (O => tmdstx_dat_p(i), OB => tmdstx_dat_n(i), I => tmds_dat(i));
    end generate;
  end generate;

  novga : if (CFG_VGA_ENABLE = 0 and CFG_SVGA_ENABLE = 0) generate
    apbo(6) <= apb_none; vgao <= vgao_none;
    tmdsc_pad : OBUFDS
      port map (O => tmdstx_clk_p, OB => tmdstx_clk_n, I => gnd);
    tmdsd_pad : for i in 0 to 2 generate
      tmdsdi_pad : OBUFDS
        port map (O => tmdstx_dat_p(i), OB => tmdstx_dat_n(i), I => gnd);
    end generate;
  end generate;

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_design
  generic map (
    msg1 => "LEON3 Digilent-Atlys-XC6SLX45 Demonstration design",
    fabtech => tech_table(fabtech), memtech => tech_table(memtech),
    mdel => 1
    );
-- pragma translate_on

end architecture;

