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
-----------------------------------------------------------------------------
-- Entity:      sgmii
-- File:        sgmii.vhd
-- Author:      Andrea Gianarro - Aeroflex Gaisler AB
-- Description: SGMII to GMII Ethernet bridge
--              Provide a valid MDC clock input for proper functioning
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library gaisler;
use gaisler.net.all;
use gaisler.misc.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
library opencores;
use opencores.ge_1000baseX_comp.all;

entity sgmii is
  generic (
    fabtech   : integer := 0;
    memtech   : integer := 0;
    transtech : integer := 0;
    phy_addr  : integer := 0;
    mode      : integer := 0; -- unused
    impl      : integer := 0
  );
  port (
    clk_125       : in  std_logic;
    rst_125       : in  std_logic;

    ser_rx_p      : in  std_logic;
    ser_rx_n      : in  std_logic;
    ser_tx_p      : out std_logic;
    ser_tx_n      : out std_logic;

    txd           : in  std_logic_vector(7 downto 0);
    tx_en         : in  std_logic;
    tx_er         : in  std_logic;
    tx_clk        : out std_logic;
    tx_rstn       : out std_logic;

    rxd           : out std_logic_vector(7 downto 0);
    rx_dv         : out std_logic;
    rx_er         : out std_logic;
    rx_col        : out std_logic;
    rx_crs        : out std_logic;
    rx_clk        : out std_logic;
    rx_rstn       : out std_logic;
    
    -- optional MDIO interface to PCS
    mdc           : in  std_logic;        -- must be provided
    mdio_o        : in  std_logic         := '0';
    mdio_oe       : in  std_logic         := '1';
    mdio_i        : out std_logic;

    -- added for igloo2_serdes
    apbin         : in apb_in_serdes := apb_in_serdes_none;
    apbout        : out apb_out_serdes;
    m2gl_padin    : in pad_in_serdes := pad_in_serdes_none;
    m2gl_padout   : out pad_out_serdes;
    serdes_clk125 : out std_logic;
    rx_aligned    : out std_logic
  ) ;
end entity ;

architecture rtl of sgmii is

  -- SGMII_CORESGMII_0_CORESGMII   -   Actel:DirectCore:CORESGMII:3.2.101
  component SGMII_CORESGMII_0_CORESGMII
    generic( 
        FAMILY      : integer := 25 ;
        MDIO_PHYID  : integer := 12 ;
        SLIP_ENABLE : integer := 0 
        );
    -- Port list
    port(
        -- Inputs
        MDC          : in  std_logic;
        MDI_EXT      : in  std_logic;
        MDO          : in  std_logic;
        MDOEN        : in  std_logic;
        RCG          : in  std_logic_vector(9 downto 0);
        RESET        : in  std_logic;
        RXCLK        : in  std_logic;
        TBI_RX_CLK   : in  std_logic;
        TBI_RX_READY : in  std_logic;
        TBI_RX_VALID : in  std_logic;
        TBI_TX_CLK   : in  std_logic;
        TXCLK        : in  std_logic;
        TXD          : in  std_logic_vector(7 downto 0);
        TXEN         : in  std_logic;
        TXER         : in  std_logic;
        -- Outputs
        ANX_CDATA    : out std_logic_vector(15 downto 0);
        ANX_CVALID   : out std_logic;
        ANX_STATE    : out std_logic_vector(9 downto 0);
        BCERR        : out std_logic_vector(1 downto 0);
        COL          : out std_logic;
        CRS          : out std_logic;
        INTLB        : out std_logic;
        MDI          : out std_logic;
        PCSRXD       : out std_logic_vector(15 downto 0);
        PCSRXK       : out std_logic_vector(1 downto 0);
        RDERR        : out std_logic_vector(1 downto 0);
        RXD          : out std_logic_vector(7 downto 0);
        RXDV         : out std_logic;
        RXER         : out std_logic;
        RX_SLIP      : out std_logic;
        SPEEDO       : out std_logic_vector(1 downto 0);
        TBI_TX_VALID : out std_logic;
        TCG          : out std_logic_vector(9 downto 0)
        );
  end component;

  signal tx_in_int_reversed, rx_out_int_reversed, tx_in_int, rx_out_int, rx_out_pll_int : std_logic_vector(9 downto 0);
  signal rx_clk_int, rx_pll_clk_int, tx_pll_clk_int, rx_rstn_int, rx_rst_int, rx_pll_rstn_int, rx_pll_rst_int, tx_pll_rst_int, tx_pll_rstn_int, startup_enable_int : std_logic;
  signal mdio_int, bitslip_int : std_logic;
  signal rx_int_clk : std_logic_vector(0 downto 0) ;
  signal debug_int : std_logic_vector(31 downto 0) ;

  signal ready_sig : std_logic;
  signal mdc_rst, mdc_rstn : std_logic;

begin

  rx_rst_int <= not rx_rstn_int;
  rx_pll_rst_int <= not rx_pll_rstn_int;
  tx_pll_rst_int <= not tx_pll_rstn_int;

  pma0: serdes
    generic map (
      fabtech   => fabtech,
      transtech => transtech
    )
    port map (
      clk_125     => clk_125,
      rst_125     => rst_125,
      rx_in_p     => ser_rx_p,
      rx_in_n     => ser_rx_n,
      rx_out      => rx_out_int,
      rx_clk      => rx_clk_int,
      rx_rstn     => rx_rstn_int,
      rx_pll_clk  => rx_pll_clk_int,
      rx_pll_rstn => rx_pll_rstn_int,
      tx_pll_clk  => tx_pll_clk_int,
      tx_pll_rstn => tx_pll_rstn_int,
      tx_in       => tx_in_int,
      tx_out_p    => ser_tx_p, 
      tx_out_n    => ser_tx_n, 
      bitslip     => bitslip_int,
      apbin       => apbin,
      apbout      => apbout,
      m2gl_padin  => m2gl_padin,
      m2gl_padout  => m2gl_padout,
      serdes_clk125 => serdes_clk125,
      serdes_ready => ready_sig
    );

  str0: if (fabtech = stratix3) or (fabtech = stratix4) or (fabtech = stratix5) or (is_unisim(fabtech) = 1) generate
    -- COMMA DETECTOR WITH BITSLIP LOGIC
    cd0: comma_detect
      generic map (
        bsbreak => 16,
        bswait  => 63
        )
      port map (
        clk     => rx_clk_int,
        rstn    => rx_rstn_int,
        indata  => rx_out_int,
        bitslip => bitslip_int
    );

    -- ELASTIC BUFFER WITH INTERNAL FIFO
    eb0: elastic_buffer
      generic map (
        tech    => memtech,
        abits   => 7
      )
      port map (
        wr_clk  => rx_clk_int,
        wr_rst  => rx_rst_int,
        wr_data => rx_out_int,
        rd_clk  => rx_pll_clk_int,
        rd_rst  => rx_pll_rst_int,
        rd_data => rx_out_pll_int
      );

    pcs0 : ge_1000baseX
      generic map (
        PHY_ADDR => phy_addr,
        BASEX_AN_MODE => mode
      )
      port map(
        rx_ck           => rx_pll_clk_int,
        tx_ck           => tx_pll_clk_int,
        rx_reset        => rx_pll_rst_int,
        tx_reset        => tx_pll_rst_int,
        startup_enable  => startup_enable_int,
        tbi_rxd         => rx_out_pll_int,  -- abcdefghij
        tbi_txd         => tx_in_int,       -- abcdefghij
        gmii_rxd        => rxd,
        gmii_rx_dv      => rx_dv,
        gmii_rx_er      => rx_er,
        gmii_col        => rx_col,
        gmii_cs         => rx_crs,
        gmii_txd        => txd,
        gmii_tx_en      => tx_en,
        gmii_tx_er      => tx_er,
        repeater_mode   => '0',
        mdc_reset       => rst_125,
        mdio_i          => mdio_int,
        mdio_o          => mdio_i,
        mdc             => mdc,
        debug           => debug_int
        );
    
  end generate;

  igl2 : if (fabtech = igloo2 or fabtech = rtg4) and (impl = 0) generate
    -- comma detector and word aligner
    wa0: word_aligner
    port map (
      clk => rx_clk_int,
      rstn => rx_rstn_int,
      rx_in => rx_out_int,
      rx_out => rx_out_pll_int);

  rst0 : rstgen     -- reset synchronizer for MDC clock domain in ge_1000baseX
    generic map (syncrst => 1, acthigh => 1)
    port map (rx_pll_rst_int, mdc, '1', mdc_rstn, open);

  mdc_rst <= not(mdc_rstn);

  pcs0 : ge_1000baseX
    generic map (
      PHY_ADDR => phy_addr,
      BASEX_AN_MODE => mode
    )
    port map(
      rx_ck           => rx_pll_clk_int,
      tx_ck           => tx_pll_clk_int,
      rx_reset        => rx_pll_rst_int,
      tx_reset        => tx_pll_rst_int,
      startup_enable  => startup_enable_int,
      tbi_rxd         => rx_out_pll_int,  -- abcdefghij
      tbi_txd         => tx_in_int,       -- abcdefghij
      gmii_rxd        => rxd,
      gmii_rx_dv      => rx_dv,
      gmii_rx_er      => rx_er,
      gmii_col        => rx_col,
      gmii_cs         => rx_crs,
      gmii_txd        => txd,
      gmii_tx_en      => tx_en,
      gmii_tx_er      => tx_er,
      repeater_mode   => '0',
      mdc_reset       => mdc_rst,
      mdio_i          => mdio_int,
      mdio_o          => mdio_i,
      mdc             => mdc,
      debug           => debug_int
      );

  end generate;

  -- rtg4impl1 makes use of the Microsemi CoreSGMII. This needs to be built
  -- to the gaisler library. One way to accomplish this is to add:
  -- bash-4.1$ cat lib/gaisler/greth/vlogsyn.txt
  -- <path to>/component/Actel/DirectCore/CORESGMII/3.2.101/rtl/vlog/core_encrypted/CoreSGMII_ENC.v
  -- <path to>/component/work/SGMII/CORESGMII_0/rtl/vlog/core_encrypted/CoreSGMII.v
  rt4impl1 : if (fabtech = igloo2 or fabtech = rtg4) and (impl = 1) generate
    -- comma detector and word aligner
    wa0: word_aligner
    port map (
      clk => rx_clk_int,
      rstn => rx_rstn_int,
      rx_in => rx_out_int,
      rx_out => rx_out_pll_int);

  rst0 : rstgen     -- reset synchronizer for MDC clock domain in ge_1000baseX
    generic map (syncrst => 1, acthigh => 1)
    port map (rx_pll_rst_int, mdc, '1', mdc_rstn, open);

  mdc_rst <= not(mdc_rstn);

  CORESGMII_0 : SGMII_CORESGMII_0_CORESGMII
    generic map( 
        FAMILY      => ( 25 ),
        MDIO_PHYID  => ( phy_addr ),
        SLIP_ENABLE => ( 0 )
        )
    port map( 
        -- Inputs
        RESET        => startup_enable_int,  -- rx_pll_rst_int,
        TBI_TX_CLK   => tx_pll_clk_int,
        TXCLK        => tx_pll_clk_int,
        RXCLK        => rx_pll_clk_int,
        TXD          => txd,
        TXEN         => tx_en,
        TXER         => tx_er,
        MDC          => mdc,            -- MDIO data clock
        MDO          => mdio_o,         -- MDIO output
        MDOEN        => mdio_oe,        -- MDIO oen
        MDI_EXT      => '0',            -- Management data input from external
                                        -- PCS/PHY
        RCG          => tx_in_int,
        TBI_RX_CLK   => rx_pll_clk_int,
        TBI_RX_READY => ready_sig,
        TBI_RX_VALID => '0', -- tied to '0' from definition
        -- Outputs
        SPEEDO       => open,
        TCG          => rx_out_pll_int,
        RXD          => rxd,
        RXDV         => rx_dv,
        RXER         => rx_er,
        COL          => rx_col,
        CRS          => rx_crs,
        MDI          => mdio_i,          -- Management data input
        INTLB        => open,
        TBI_TX_VALID => open,
        ANX_STATE    => open,
        PCSRXD       => open,
        PCSRXK       => open,
        BCERR        => open,
        RDERR        => open,
        ANX_CVALID   => open,
        ANX_CDATA    => open,
        RX_SLIP      => OPEN 
        );

    
  end generate;
  
  mdio_int <= mdio_o when mdio_oe = '0' else
          '0'; 

  startup_enable_int <= (not rst_125) and ready_sig;

  rx_clk      <= rx_pll_clk_int; --rx_clk_int;
  rx_rstn     <= rx_pll_rstn_int;
  tx_clk      <= tx_pll_clk_int; --clk_125;
  tx_rstn     <= tx_pll_rstn_int;
  rx_aligned  <= ready_sig;

end architecture ; -- rtl
