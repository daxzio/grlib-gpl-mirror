-----------------------------------------------------------------------------
--  LEON Demonstration design test bench
--  Copyright (C) 2013 Gaisler Research
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


library ieee;
use ieee.std_logic_1164.all;
library gaisler;
use gaisler.libdcom.all;
use gaisler.sim.all;
use gaisler.jtagtst.all;
use gaisler.gr1553b_pkg.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
use work.debug.all;

use work.config.all;

entity testbench is
  generic (
    fabtech   : integer := CFG_FABTECH;
    memtech   : integer := CFG_MEMTECH;
    padtech   : integer := CFG_PADTECH;
    clktech   : integer := CFG_CLKTECH;
    disas     : integer := CFG_DISAS;      -- Enable disassembly to console
    dbguart   : integer := CFG_DUART;      -- Print UART on console
    pclow     : integer := CFG_PCLOW;
    USE_MIG_INTERFACE_MODEL : boolean := false

  );
  port (
    pci_rst     : inout std_logic;	-- PCI bus
    pci_clk 	: in std_logic;
    pci_gnt     : in std_logic;
    pci_idsel   : in std_logic;  
    pci_lock    : inout std_logic;
    pci_ad 	: inout std_logic_vector(31 downto 0);
    pci_cbe 	: inout std_logic_vector(3 downto 0);
    pci_frame   : inout std_logic;
    pci_irdy 	: inout std_logic;
    pci_trdy 	: inout std_logic;
    pci_devsel  : inout std_logic;
    pci_stop 	: inout std_logic;
    pci_perr 	: inout std_logic;
    pci_par 	: inout std_logic;    
    pci_req 	: inout std_logic;
    pci_serr    : inout std_logic;
    pci_host   	: in std_logic := '1';
    pci_int 	: inout std_logic_vector(0 downto 0)
    --pci_66	: in std_logic := '0'
  );
end;

architecture behav of testbench is

-- DDR3 Simulation parameters
constant SIM_BYPASS_INIT_CAL : string := "FAST";
          -- # = "OFF" -  Complete memory init &
          --               calibration sequence
          -- # = "SKIP" - Not supported
          -- # = "FAST" - Complete memory init & use
          --              abbreviated calib sequence

constant SIMULATION          : string := "TRUE";
          -- Should be TRUE during design simulations and
          -- FALSE during implementations


constant promfile      : string := "prom.srec";  -- rom contents
constant ramfile       : string := "ram.srec";  -- ram contents

signal clk             : std_logic := '0';
signal Rst             : std_logic := '0';

signal address         : std_logic_vector(24 downto 0);
signal data            : std_logic_vector(7 downto 0);

signal genio           : std_logic_vector(59 downto 0);
signal csn             : std_logic_vector(5 downto 0);
signal romsn           : std_logic;
signal oen             : std_ulogic;
signal writen          : std_ulogic;
signal adv             : std_logic;

signal GND             : std_ulogic := '0';
signal VCC             : std_ulogic := '1';
signal NC              : std_ulogic := 'Z';

signal txd1  , rxd1  , dsurx   : std_logic;
signal txd2  , rxd2  , dsutx   : std_logic;
signal ctsn1 , rtsn1 , dsuctsn : std_ulogic;
signal ctsn2 , rtsn2 , dsurtsn : std_ulogic;

signal phy_gtxclk      : std_logic := '0';
signal phy_txer        : std_ulogic;
signal phy_txd         : std_logic_vector(7 downto 0);
signal phy_txctl_txen  : std_ulogic;
signal phy_txclk       : std_ulogic;
signal phy_rxer        : std_ulogic;
signal phy_rxd         : std_logic_vector(7 downto 0);
signal phy_rxctl_rxdv  : std_ulogic;
signal phy_rxclk       : std_ulogic;
signal phy_reset       : std_ulogic;
signal phy_mdio        : std_logic;
signal phy_mdc         : std_ulogic;
signal phy_crs         : std_ulogic;
signal phy_col         : std_ulogic;
signal phy_int         : std_ulogic;
signal phy_rxdl        : std_logic_vector(7 downto 0);
signal phy_txdl        : std_logic_vector(7 downto 0);

signal clk27           : std_ulogic := '0';
signal clk_p           : std_ulogic := '0';
signal clk_n           : std_ulogic := '1';
signal clk33           : std_ulogic := '0';
signal clkethp         : std_ulogic := '0';
signal clkethn         : std_ulogic := '1';
signal txp1            : std_logic;
signal txn             : std_logic;
signal rxp             : std_logic := '1';
signal rxn             : std_logic := '0';


signal iic_scl         : std_ulogic;
signal iic_sda         : std_ulogic;
signal ddc_scl         : std_ulogic;
signal ddc_sda         : std_ulogic;
signal dvi_iic_scl     : std_logic;
signal dvi_iic_sda     : std_logic;

signal tft_lcd_data    : std_logic_vector(11 downto 0);
signal tft_lcd_clk_p   : std_ulogic;
signal tft_lcd_clk_n   : std_ulogic;
signal tft_lcd_hsync   : std_ulogic;
signal tft_lcd_vsync   : std_ulogic;
signal tft_lcd_de      : std_ulogic;
signal tft_lcd_reset_b : std_ulogic;

-- DDR3 memory
signal ddr3_dq         : std_logic_vector(15 downto 0);
signal ddr3_dqs_p      : std_logic_vector(1 downto 0);
signal ddr3_dqs_n      : std_logic_vector(1 downto 0);
signal ddr3_addr       : std_logic_vector(14 downto 0);
signal ddr3_ba         : std_logic_vector(2 downto 0);
signal ddr3_ras_n      : std_logic;
signal ddr3_cas_n      : std_logic;
signal ddr3_we_n       : std_logic;
signal ddr3_reset_n    : std_logic;
signal ddr3_ck_p       : std_logic_vector(0 downto 0);
signal ddr3_ck_n       : std_logic_vector(0 downto 0);
signal ddr3_cke        : std_logic_vector(0 downto 0);
signal ddr3_cs_n       : std_logic_vector(0 downto 0);
signal ddr3_dm         : std_logic_vector(1 downto 0);
signal ddr3_odt        : std_logic_vector(0 downto 0);

-- SPI flash
signal spi_sel_n       : std_ulogic;
signal spi_clk         : std_ulogic;
signal spi_mosi        : std_ulogic;

signal dsurst          : std_ulogic;
signal errorn          : std_logic;

signal switch          : std_logic_vector(5 downto 0);    -- I/O port
signal gpio            : std_logic_vector(31 downto 0);    -- I/O port
constant lresp         : boolean := false;

signal tdqs_n : std_logic;

signal gmii_tx_clk     : std_logic;
signal gmii_rx_clk     : std_logic;
signal gmii_txd        : std_logic_vector(7 downto 0);
signal gmii_tx_en      : std_logic;
signal gmii_tx_er      : std_logic;
signal gmii_rxd        : std_logic_vector(7 downto 0);
signal gmii_rx_dv      : std_logic;
signal gmii_rx_er      : std_logic;
    
signal m0_d            : std_logic_vector(3 downto 0);
signal m0_sck          : std_logic;
signal m0_slvsel       : std_logic_vector(1 downto 0);
signal m1_d            : std_logic_vector(3 downto 0);
signal m1_sck          : std_logic;
signal m1_slvsel       : std_logic_vector(1 downto 0);
signal spi_d           : std_logic_vector(3 downto 0);
signal spi_cs          : std_logic;

signal cantxa          : std_logic;
signal cantxb          : std_logic;
signal canrxa          :  std_logic;
signal canrxb          : std_logic;
signal cansela         : std_logic;
signal canselb         :  std_logic;

signal m1553clk        : std_ulogic := '0';
signal m1553rxa        : std_ulogic;
signal m1553rxb        : std_ulogic;
signal m1553rxena      : std_ulogic;
signal m1553rxenb      : std_ulogic;
signal m1553rxna       : std_ulogic;
signal m1553rxnb       : std_ulogic;
signal m1553txa        : std_ulogic;
signal m1553txb        : std_ulogic;
signal m1553txinha     : std_ulogic;
signal m1553txinhb     : std_ulogic;
signal m1553txna       : std_ulogic;
signal m1553txnb       : std_ulogic;
  -- MIL-STD-1553B sim. model signals
  signal milbusA,milbusB : wire1553;
-- SPW  
signal spwclk          : std_ulogic := '0';
signal spw_rxd         : std_logic_vector(0 to 5);
signal spw_rxs         : std_logic_vector(0 to 5);
signal spw_txd         : std_logic_vector(0 to 5);
signal spw_txs         : std_logic_vector(0 to 5);

signal pci_arb_req, pci_arb_gnt : std_logic_vector(0 to 3);


signal uart_txd        : std_logic_vector(4 downto 0);
signal uart_rxd        : std_logic_vector(4 downto 0);
signal uart_ctsn       : std_logic_vector(1 downto 0);
signal uart_rtsn       : std_logic_vector(1 downto 0);


signal led             : std_logic_vector(6 downto 0);

signal jtag_tck, jtag_tms, jtag_tdi, jtag_tdo : std_logic;
constant TEST_JTAGDCL : boolean := true;

component leon3mp is
  generic (
    fabtech             : integer := CFG_FABTECH;
    memtech             : integer := CFG_MEMTECH;
    padtech             : integer := CFG_PADTECH;
    clktech             : integer := CFG_CLKTECH;
    disas               : integer := CFG_DISAS;   -- Enable disassembly to console
    dbguart             : integer := CFG_DUART;   -- Print UART on console
    pclow               : integer := CFG_PCLOW;
    SIM_BYPASS_INIT_CAL : string := "OFF";
    SIMULATION          : string := "FALSE";
    USE_MIG_INTERFACE_MODEL : boolean := false
  );
  port (
    resetn          : in    std_ulogic;
    clk             : in    std_ulogic;
    --
    a               : out   std_logic_vector(24 downto 0);
    d               : inout std_logic_vector(7 downto 0);
    oen             : out   std_ulogic;
    writen          : out   std_ulogic;
    csn             : out   std_logic_vector(5 downto 0);
    --
    jtag_tck        : in    std_logic;
    jtag_tms        : in    std_logic;
    jtag_tdi        : in    std_logic;
    jtag_tdo        : out   std_logic;

    ddr3_dq         : inout std_logic_vector(15 downto 0);
    ddr3_dqs_p      : inout std_logic_vector( 1 downto 0);
    ddr3_dqs_n      : inout std_logic_vector( 1 downto 0);
    ddr3_addr       : out   std_logic_vector(14 downto 0);
    ddr3_ba         : out   std_logic_vector( 2 downto 0);
    ddr3_ras_n      : out   std_logic;
    ddr3_cas_n      : out   std_logic;
    ddr3_we_n       : out   std_logic;
    ddr3_reset_n    : out   std_logic;
    ddr3_ck_p       : out   std_logic_vector(0 downto 0);
    ddr3_ck_n       : out   std_logic_vector(0 downto 0);
    ddr3_cke        : out   std_logic_vector(0 downto 0);
    ddr3_cs_n       : out   std_logic_vector(0 downto 0);
    ddr3_dm         : out   std_logic_vector(1 downto 0);
    ddr3_odt        : out   std_logic_vector(0 downto 0);
    --
    dsurx           : in    std_ulogic;
    dsutx           : out   std_ulogic;

    switch          : inout std_logic_vector( 5 downto 0);
    gpio            : inout std_logic_vector(31 downto 0);
    led             : out   std_logic_vector( 6 downto 0);
    
    cantxa          : out std_logic;
    cantxb          : out std_logic;
    canrxa          : in  std_logic;
    canrxb          : in  std_logic;
    cansela         : out std_logic;
    canselb         : out std_logic;

    -- PCI
    pci_rst         : inout std_logic;             
    pci_clk         : in std_logic;
    pci_gnt         : in std_logic;
    pci_idsel       : in std_logic; 
    pci_lock        : inout std_logic;
    pci_ad          : inout std_logic_vector(31 downto 0);
    pci_cbe         : inout std_logic_vector(3 downto 0);
    pci_frame       : inout std_logic;
    pci_irdy        : inout std_logic;
    pci_trdy        : inout std_logic;
    pci_devsel      : inout std_logic;
    pci_stop        : inout std_logic;
    pci_perr        : inout std_logic;
    pci_par         : inout std_logic;    
    pci_req         : inout std_logic;
    pci_serr        : inout std_logic;
    pci_host        : in std_logic;
    pci_int         : inout std_logic_vector(0 downto 0);
    --pci_66          : in std_logic;
    pci_arb_req     : in  std_logic_vector(0 to 3);
    pci_arb_gnt     : out std_logic_vector(0 to 3);
    


    -- 
    iic_scl         : inout std_ulogic;
    iic_sda         : inout std_ulogic;
    --
    m0_d            : inout std_logic_vector(3 downto 0);
    m0_sck          : out   std_logic;
    m0_slvsel       : out   std_logic_vector(1 downto 0);
    m1_d            : inout std_logic_vector(3 downto 0);
    m1_sck          : out   std_logic;
    m1_slvsel       : out   std_logic_vector(1 downto 0);
    spi_d           : inout std_logic_vector(3 downto 0);
    spi_cs          : out   std_logic;

    uart_txd        : out   std_logic_vector(4 downto 0);
    uart_rxd        : in    std_logic_vector(4 downto 0);
    uart_ctsn       : in    std_logic_vector(1 downto 0);
    uart_rtsn       : out   std_logic_vector(1 downto 0);

    -- ETH ???
    eth_gtxclk      : out   std_logic;
    eth_mdio        : inout std_logic;
    eth_txclk       : in    std_ulogic;
    eth_rxclk       : in    std_ulogic;
    eth_rxd         : in    std_logic_vector(7 downto 0);   
    eth_rxdv        : in    std_ulogic; 
    eth_rxer        : in    std_ulogic; 
    eth_col         : in    std_ulogic;
    eth_crs         : in    std_ulogic;
    eth_mdint       : in    std_ulogic;
    eth_txd         : out   std_logic_vector(7 downto 0);   
    eth_txen        : out   std_ulogic; 
    eth_txer        : out   std_ulogic; 
    eth_mdc         : out   std_ulogic;
    --phy_reset       : out   std_ulogic;
    -- SPW
    spwclk          : in  std_ulogic;
    spw_rxd         : in  std_logic_vector(0 to 5);
    spw_rxs         : in  std_logic_vector(0 to 5);
    spw_txd         : out std_logic_vector(0 to 5);
    spw_txs         : out std_logic_vector(0 to 5);
    -- Mil1553
    m1553clk        : in    std_ulogic;
    m1553rxa        : in    std_ulogic;
    m1553rxb        : in    std_ulogic;
    m1553rxena      : out   std_ulogic;
    m1553rxenb      : out   std_ulogic;
    m1553rxna       : in    std_ulogic;
    m1553rxnb       : in    std_ulogic;
    m1553txa        : out   std_ulogic;
    m1553txb        : out   std_ulogic;
    m1553txinha     : out   std_ulogic;
    m1553txinhb     : out   std_ulogic;
    m1553txna       : out   std_ulogic;
    m1553txnb       : out   std_ulogic
   );
end component;

begin

  -- clock and reset
  m1553clk     <= not m1553clk after 20.83 ns;
  clk     <= not clk after 10 ns;
  spwclk  <= not spwclk after 5 ns;

  clkethp <= not clkethp after 4 ns;
  clkethn <= not clkethp after 4 ns;

  rst <= dsurst;
  --rst <= '0', '1' after 200 ns;
  
  rxd1 <= 'H'; ctsn1 <= '0';
  rxd2 <= 'H'; ctsn2 <= '0';

  switch(5 downto 4) <= "00";
  switch(2 downto 0) <= "000";

  spw_rxd <= spw_txd;
  spw_rxs <= spw_txs;  

    cpu : leon3mp
      generic map (
       fabtech              => fabtech,
       memtech              => memtech,
       padtech              => padtech,
       clktech              => clktech,
       disas                => disas,
       dbguart              => dbguart,
       pclow                => pclow,
       SIM_BYPASS_INIT_CAL  => SIM_BYPASS_INIT_CAL,
       SIMULATION           => SIMULATION,
       USE_MIG_INTERFACE_MODEL => USE_MIG_INTERFACE_MODEL
   )
      port map (
       resetn          => rst,
       clk             => clk, 
       a               => address,
       d               => data,
       oen             => oen,
       writen          => writen,
       csn             => csn,
       --
       jtag_tck        => jtag_tck,
       jtag_tms        => jtag_tms,
       jtag_tdi        => jtag_tdi,
       jtag_tdo        => jtag_tdo,
       --adv             => adv,
       ddr3_dq         => ddr3_dq,
       ddr3_dqs_p      => ddr3_dqs_p,
       ddr3_dqs_n      => ddr3_dqs_n,
       ddr3_addr       => ddr3_addr,
       ddr3_ba         => ddr3_ba,
       ddr3_ras_n      => ddr3_ras_n,
       ddr3_cas_n      => ddr3_cas_n,
       ddr3_we_n       => ddr3_we_n,
       ddr3_reset_n    => ddr3_reset_n,
       ddr3_ck_p       => ddr3_ck_p,
       ddr3_ck_n       => ddr3_ck_n,
       ddr3_cke        => ddr3_cke,
       ddr3_cs_n       => ddr3_cs_n,
       ddr3_dm         => ddr3_dm,
       ddr3_odt        => ddr3_odt,
       dsurx           => dsurx,
       dsutx           => dsutx,
       --dsuctsn         => dsuctsn,
       --dsurtsn         => dsurtsn,
       --button          => button,
       switch          => switch,
       gpio            => gpio,
       led             => led,
       iic_scl         => iic_scl,
       iic_sda         => iic_sda,
       m0_d            => m0_d, 
       m0_sck          => m0_sck,
       m0_slvsel       => m0_slvsel,
       m1_d            => m1_d,
       m1_sck          => m1_sck,
       m1_slvsel       => m1_slvsel,
       spi_d           => spi_d,
       spi_cs          => spi_cs,
       eth_gtxclk      => phy_gtxclk,
       eth_txer        => phy_txer,
       eth_txd         => phy_txd(7 downto 0),
       eth_txen        => phy_txctl_txen,
       eth_txclk       => phy_txclk,
       eth_rxer        => phy_rxer,
       eth_rxd         => phy_rxd(7 downto 0),
       eth_rxdv        => phy_rxctl_rxdv,
       eth_rxclk       => phy_rxclk,
       eth_col         => phy_col,
       eth_crs         => phy_crs,
       --phy_reset       => phy_reset,
       eth_mdio        => phy_mdio,
       eth_mdc         => phy_mdc,
       eth_mdint       => phy_int,


       cantxa         => cantxa,
       cantxb         => cantxb,
       canrxa         => canrxa,
       canrxb         => canrxb,
       cansela        => cansela,
       canselb        => canselb,

       uart_txd        => uart_txd,   
       uart_rxd        => uart_rxd,
       uart_ctsn       => uart_ctsn,
       uart_rtsn       => uart_rtsn,

           -- PCI
       pci_rst         => pci_rst,    
       pci_clk         => pci_clk,
       pci_gnt         => pci_gnt,
       pci_idsel       => pci_idsel,
       pci_lock        => pci_lock,
       pci_ad          => pci_ad,
       pci_cbe         => pci_cbe, 
       pci_frame       => pci_frame, 
       pci_irdy        => pci_irdy,
       pci_trdy        => pci_trdy,
       pci_devsel      => pci_devsel, 
       pci_stop        => pci_stop, 
       pci_perr        => pci_perr,   
       pci_par         => pci_par,
       pci_req         => pci_req,    
       pci_serr        => pci_serr, 
       pci_host        => pci_host,   
       pci_int         => pci_int,     
       --pci_66          => pci_66, 
       pci_arb_req     => pci_arb_req,
       pci_arb_gnt     => pci_arb_gnt,
    
       --
       spwclk          => spwclk,
       spw_rxd         => spw_rxd,
       spw_rxs         => spw_rxs,
       spw_txd         => spw_txd,
       spw_txs         => spw_txs,
       --
       m1553clk        => m1553clk,   
       m1553rxa        => m1553rxa,   
       m1553rxb        => m1553rxb,   
       m1553rxena      => m1553rxena, 
       m1553rxenb      => m1553rxenb, 
       m1553rxna       => m1553rxna,  
       m1553rxnb       => m1553rxnb,  
       m1553txa        => m1553txa,   
       m1553txb        => m1553txb,   
       m1553txinha     => m1553txinha,
       m1553txinhb     => m1553txinhb,
       m1553txna       => m1553txna,  
       m1553txnb       => m1553txnb  
      );

  --prom0 : for i in 0 to 1 generate
      sr0 : sram generic map (index => 6, abits => 25, fname => ramfile, clear => 1)
        port map (address(24 downto 0), data(7 downto 0), csn(0),
                  writen, oen);
      
        sr1 : sram generic map (index => 6, abits => 25, fname => promfile)
        port map (address(24 downto 0), data(7 downto 0), csn(1),
                  writen, oen);
  --end generate;

  -- Memory Models instantiations
  gen_mem_model : if (USE_MIG_INTERFACE_MODEL /= true) generate
   ddr3mem : if (CFG_MIG_7SERIES = 1) generate
     u1 : ddr3ram
       generic map (
         width     => 16,
         abits     => 15,
         colbits   => 10,
         rowbits   => 14,
         implbanks => 1,
         fname     => ramfile,
         lddelay   => (0 ns),
         ldguard   => 1,
         speedbin  => 9, --DDR3-1600K
         density   => 3,
         pagesize  => 1,
         changeendian => 8)
       port map (
          ck     => ddr3_ck_p(0),
          ckn    => ddr3_ck_n(0),
          cke    => ddr3_cke(0),
          csn    => ddr3_cs_n(0),
          odt    => ddr3_odt(0),
          rasn   => ddr3_ras_n,
          casn   => ddr3_cas_n,
          wen    => ddr3_we_n,
          dm     => ddr3_dm,
          ba     => ddr3_ba,
          a      => ddr3_addr,
          resetn => ddr3_reset_n,
          dq     => ddr3_dq,
          dqs    => ddr3_dqs_p,
          dqsn   => ddr3_dqs_n,
          doload => led(3)
          );
   end generate ddr3mem;
  end generate gen_mem_model;

  mig_mem_model : if (USE_MIG_INTERFACE_MODEL = true) generate
    ddr3_dq    <= (others => 'Z');
    ddr3_dqs_p <= (others => 'Z');
    ddr3_dqs_n <= (others => 'Z');
  end generate mig_mem_model;

  errorn <= led(1);
  errorn <= 'H'; -- ERROR pull-up

  phy0 : if (CFG_GRETH = 1) generate

   phy_mdio <= 'H';
   --phy_int <= '0';
   phy_reset <= rst;
   p0: phy
    generic map (
             address       => 1,
             base1000_t_fd => 0,
             base1000_t_hd => 0
    )
    port map(phy_reset, phy_mdio, phy_txclk, phy_rxclk, phy_rxd,
             phy_rxctl_rxdv, phy_rxer, phy_col, phy_crs, phy_txd,
             phy_txctl_txen, phy_txer, phy_mdc, phy_gtxclk);

  end generate;
    
  GR1553_test : if (1 = 1) generate
    x1553: simtrans1553
      port map (
        busA  => milbusA,
        busB  => milbusB,
        rxenA => m1553rxena,
        txinA => m1553txinha,
        txAP  => m1553txa,
        txAN  => m1553txna,
        rxAP  => m1553rxa,
        rxAN  => m1553rxna,
        rxenB => m1553rxenb,
        txinB => m1553txinhb,
        txBP  => m1553txb,
        txBN  => m1553txnb,
        rxBP  => m1553rxb,
        rxBN  => m1553rxnb);
  end generate;

   iuerr : process
   begin
     wait for 210 us; -- This is for proper DDR3 behaviour durign init phase not needed durin simulation
     wait on led(3);  -- DDR3 Memory Init ready
     wait for 5000 ns;
     if to_x01(errorn) = '1' then wait on errorn; end if;
     assert (to_x01(errorn) = '1')
       report "*** IU in error mode, simulation halted ***"
          severity failure ; -- this should be a failure
   end process;

  data <= buskeep(data) after 5 ns;

  dsucom : process
   procedure dsucfg(signal dsurx : in std_ulogic; signal dsutx : out std_ulogic) is
   variable w32 : std_logic_vector(31 downto 0);
    variable c8  : std_logic_vector(7 downto 0);
    constant txp : time := 320 * 1 ns;
    begin
    dsutx <= '1';
    dsurst <= '0';
    switch(3) <= '0';
    wait for 2500 ns;
    wait for 210 us; -- This is for proper DDR3 behaviour durign init phase not needed durin simulation
    dsurst <= '1';
    switch(3) <= '1';
    if (USE_MIG_INTERFACE_MODEL /= true) then
       wait on led(3);  -- Wait for DDR3 Memory Init ready
    end if;
    report "Start DSU transfer";
    wait for 5000 ns;
    txc(dsutx, 16#55#, txp);      -- sync uart

    -- Reads from memory and DSU register to mimic GRMON during simulation
    l1 : loop
     txc(dsutx, 16#80#, txp);
     txa(dsutx, 16#40#, 16#00#, 16#00#, 16#04#, txp);
     rxi(dsurx, w32, txp, lresp);
     --report "DSU read memory " & tost(w32);
     txc(dsutx, 16#80#, txp);
     txa(dsutx, 16#90#, 16#00#, 16#00#, 16#20#, txp);
     rxi(dsurx, w32, txp, lresp);
     --report "DSU Break and Single Step register" & tost(w32);
    end loop l1;

    wait;

    -- ** This is only kept for reference --

    -- do test read and writes to DDR3 to check status
    -- Write
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#00#, txp);
    txa(dsutx, 16#01#, 16#23#, 16#45#, 16#67#, txp);
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#04#, txp);
    txa(dsutx, 16#89#, 16#AB#, 16#CD#, 16#EF#, txp);
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#08#, txp);
    txa(dsutx, 16#08#, 16#19#, 16#2A#, 16#3B#, txp);
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#0C#, txp);
    txa(dsutx, 16#4C#, 16#5D#, 16#6E#, 16#7F#, txp);
    txc(dsutx, 16#80#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#00#, txp);
    rxi(dsurx, w32, txp, lresp);
    txc(dsutx, 16#80#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#04#, txp);
    rxi(dsurx, w32, txp, lresp);
    report "* Read " & tost(w32);
    txc(dsutx, 16#a0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#08#, txp);
    rxi(dsurx, w32, txp, lresp);
    txc(dsutx, 16#a0#, txp);
    txa(dsutx, 16#40#, 16#00#, 16#00#, 16#0C#, txp);
    rxi(dsurx, w32, txp, lresp);
    wait;

    -- Register 0x90000000 (DSU Control Register)
    -- Data 0x0000202e (b0010 0000 0010 1110)
    -- [0] - Trace Enable
    -- [1] - Break On Error
    -- [2] - Break on IU watchpoint
    -- [3] - Break on s/w break points
    --
    -- [4] - (Break on trap)
    -- [5] - Break on error traps
    -- [6] - Debug mode (Read mode only)
    -- [7] - DSUEN (read mode)
    --
    -- [8] - DSUBRE (read mode)
    -- [9] - Processor mode error (clears error)
    -- [10] - processor halt (returns 1 if processor halted)
    -- [11] - power down mode (return 1 if processor in power down mode)
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#90#, 16#00#, 16#00#, 16#00#, txp);
    txa(dsutx, 16#00#, 16#00#, 16#80#, 16#02#, txp);
    wait;
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#90#, 16#00#, 16#00#, 16#00#, txp);
    txa(dsutx, 16#00#, 16#00#, 16#20#, 16#2e#, txp);

    wait for 25000 ns;
    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#90#, 16#00#, 16#00#, 16#20#, txp);
    txa(dsutx, 16#00#, 16#00#, 16#00#, 16#01#, txp);

    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#90#, 16#40#, 16#00#, 16#24#, txp);
    txa(dsutx, 16#00#, 16#00#, 16#00#, 16#0D#, txp);

    txc(dsutx, 16#c0#, txp);
    txa(dsutx, 16#90#, 16#70#, 16#11#, 16#78#, txp);
    txa(dsutx, 16#91#, 16#00#, 16#00#, 16#0D#, txp);

    txa(dsutx, 16#90#, 16#40#, 16#00#, 16#44#, txp);
    txa(dsutx, 16#00#, 16#00#, 16#20#, 16#00#, txp);

    txc(dsutx, 16#80#, txp);
    txa(dsutx, 16#90#, 16#40#, 16#00#, 16#44#, txp);

    wait;

   end;

   begin
    dsuctsn <= '0';
    dsucfg(dsutx, dsurx);
    wait;
  end process;

  -----------------------------------------------------------------------------
  -- JTAG Debug Communication Link
  -----------------------------------------------------------------------------
 -- jtag_tck         <= 'L';
 -- jtag_tms         <= 'L';
--  jtag_tdi         <= 'L';

  --jtagdcl_test : if TEST_JTAGDCL generate
  --  -- Tests JTAG Debug Communication Link
  --  jtagproc : process
  --    variable datav      : jdata_vector_type(0 to 7);
  --    variable wantedv    : jdata_vector_type(0 to 7);
  --    constant CP         : integer := 30;
  --    variable tp         : boolean := true;
  --    variable reread     : boolean := true;
  --    variable assertions : boolean := false;
    

  --  begin
  --    --dsu_break <= '1';
  --    jtag_tck         <= 'L';
  --    jtag_tms         <= 'L';
  --    jtag_tdi         <= 'L';
      
  --    if rst /= '1' then wait until rst = '1'; end if;

  --    -- JTAG initialization
  --    print(tost(NOW/1 ns) & "ns JTAG init.");
  --    jtagcom(jtag_tdo, jtag_tck, jtag_tms, jtag_tdi, 10, CP, 0, false, true,
  --            reread, assertions);


  --    ---- Perform same access pattern as GRMON 1.0.40 when connecting without
  --    ---- scanning the debug bus IO area
  --    --datav := (others => (others => '0'));
  --    --wantedv := (X"0104B01c", X"00000114", X"FFE00000", X"00000000",
  --    --            X"00038002", X"F000FFC2", X"FFE0FFF2", X"00000000");
    
    
  --    --jreadm(X"FFFFF800", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP,
  --    --       reread, assertions);
  --    --for j in datav'range loop
  --    --  if datav(j) /= wantedv(j) then
  --    --    Print("Data mismatch on address " & tost(X"FFFFF800" + j*4) &
  --    --          ", expected " & tost(wantedv(j)) & ", read " & tost(datav(j)));
  --    --    tp := false;
  --    --  end if;
  --    --end loop;
      
  --    --jreadm(X"40000010", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP, reread, assertions);
      
  --    --jwrite(X"eff00000", X"00000009", jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP);
      
  --    --jtag_load_srec;

  --    --jreadm(X"90000020", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP, reread, assertions);
  --    --print("R(0x90000020): " & tost(datav(0)));
  --    --jwrite(X"90000020", X"00000000", jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP);
      
  --    --dsu_break <= '0';
  --    jreadm(X"80000300", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP, reread, assertions);
  --    print("R[0x80000300]: " & tost(datav(0)));
      
  --    jreadm(X"80000b00", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP, reread, assertions);
  --    print("R[0x80000b00]: " & tost(datav(0)));
      
      
  --    jwrite(X"80000b04", X"F0FF0F0F", jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP);
  --    jwrite(X"80000b08", X"F0FF0F0F", jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP);
      
  --    jreadm(X"80000b00", datav, jtag_tck, jtag_tms, jtag_tdi, jtag_tdo, CP, reread, assertions);
  --    print("R[0x80000b00]: " & tost(datav(0)));
      
      
  --    if tp then print("JTAG test passed");
  --    else print("JTAG test FAILED"); end if;
  --    wait;
  --  end process;
  --end generate;
end ;

