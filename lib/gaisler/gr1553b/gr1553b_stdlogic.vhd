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
-- Entity:      gr1553b_stdlogic
-- File:        gr1553b_stdlogic.vhd
-- Author:      Magnus Hjorth - Aeroflex Gaisler
-- Description: Wrapper for GR1553B with std_logic ports
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
library gaisler;
use gaisler.gr1553b_pkg.all;

entity gr1553b_stdlogic is

  generic (
    bc_enable: integer range 0 to 1 := 1;
    rt_enable: integer range 0 to 1 := 1;
    bm_enable: integer range 0 to 1 := 1;
    bc_timer: integer range 0 to 2 := 1;
    bc_rtbusmask: integer range 0 to 1 := 1;
    extra_regkeys: integer range 0 to 1 := 0;
    syncrst: integer range 0 to 2 := 1;
    ahbendian: integer range 0 to 1 := 0;
    bm_filters: integer range 0 to 1 := 1;
    codecfreq: integer := 20;
    sameclk: integer range 0 to 1 := 0;
    codecver: integer range 0 to 2 := 1;
    extctrlen: integer range 0 to 1 := 0
    );

  port (
    clk: in std_logic;
    rst: in std_logic;
    codec_clk: in std_logic;
    codec_rst: in std_logic;

    -- AHB interface

    mi_hgrant   : in std_logic;                         -- bus grant
    mi_hready   : in std_ulogic;                        -- transfer done
    mi_hresp    : in std_logic_vector(1 downto 0);      -- response type
    mi_hrdata   : in std_logic_vector(31 downto 0);     -- read data bus
    mo_hbusreq  : out std_ulogic;                       -- bus request
    mo_htrans   : out std_logic_vector(1 downto 0);     -- transfer type
    mo_haddr    : out std_logic_vector(31 downto 0);    -- address bus (byte)
    mo_hwrite   : out std_ulogic;                       -- read/write
    mo_hsize    : out std_logic_vector(2 downto 0);     -- transfer size
    mo_hburst   : out std_logic_vector(2 downto 0);     -- burst type
    mo_hwdata   : out std_logic_vector(31 downto 0);    -- write data bus

    -- APB interface

    si_psel     : in std_logic;                         -- slave select
    si_penable  : in std_ulogic;                        -- strobe
    si_paddr    : in std_logic_vector(7 downto 0);      -- address bus (byte addr)
    si_pwrite   : in std_ulogic;                        -- write
    si_pwdata   : in std_logic_vector(31 downto 0);     -- write data bus
    so_prdata   : out std_logic_vector(31 downto 0);    -- read data bus
    so_pirq     : out std_logic;                        -- interrupt bus

    -- Aux signals
    bcsync     : in std_logic;                          -- external sync input for BC
    rtaddr     : in std_logic_vector(4 downto 0);       -- reset value for RT address
    rtaddrp    : in std_logic;                          -- RT address odd parity

    rtsync     : out std_logic;
    busreset   : out std_logic;
    validcmda  : out std_logic;
    validcmdb  : out std_logic;
    timedouta  : out std_logic;
    timedoutb  : out std_logic;
    badreg     : out std_logic;
    irqvec     : out std_logic_vector(7 downto 0);

    -- 1553 transceiver interface
    busainen   : out std_logic;                     -- bus A receiver enable
    busainp    : in  std_logic;                     -- bus A receiver, positive input
    busainn    : in  std_logic;                     -- bus A receiver, negative input
    busaouten  : out std_logic;                     -- bus A transmitter enable
    busaoutp   : out std_logic;                     -- bus A transmitter, positive output
    busaoutn   : out std_logic;                     -- bus A transmitter, negative output
    busa_txin  : out std_logic;                     -- bus A transmitter enable (inverted)

    busbinen   : out std_logic;                     -- bus B receiver enable
    busbinp    : in  std_logic;                     -- bus B receiver, positive input
    busbinn    : in  std_logic;                     -- bus B receiver, negative input
    busbouten  : out std_logic;                     -- bus B transmitter enable
    busboutp   : out std_logic;                     -- bus B transmitter, positive output
    busboutn   : out std_logic;                     -- bus B transmitter, negative output
    busb_txin  : out std_logic;                     -- bus B transmitter enable (inverted)

    -- Extra signals for extctrlen option
    extctrl_rten   : in std_logic;
    extctrl_rtaddr : in std_logic_vector(4 downto 0);
    extctrl_brs    : in std_logic;
    extctrl_sys    : in std_logic;
    extctrl_syds   : in std_logic;
    extctrl_busy   : in std_logic;
    extctrl_satb   : in std_logic_vector(31 downto 9);
    extctrl_mccr   : in std_logic_vector(29 downto 0)
    );

end;

architecture rtl of gr1553b_stdlogic is

  signal gr1553b_txout: gr1553b_txout_type;
  signal gr1553b_rxin: gr1553b_rxin_type;

  signal mi: ahb_mst_in_type;
  signal mo: ahb_mst_out_type;
  signal si: apb_slv_in_type;
  signal so: apb_slv_out_type;

  signal auxin: gr1553b_auxin_type;
  signal auxout: gr1553b_auxout_type;

begin

  x: gr1553b
    generic map (
      hindex => 0,
      pindex => 0,
      paddr => 0,
      pmask => 0,
      pirq => 0,
      bc_enable => bc_enable,
      rt_enable => rt_enable,
      bm_enable => bm_enable,
      bc_timer => bc_timer,
      bc_rtbusmask => bc_rtbusmask,
      syncrst => syncrst,
      extra_regkeys => extra_regkeys,
      ahbendian => ahbendian,
      bm_filters => bm_filters,
      codecfreq => codecfreq,
      sameclk => sameclk,
      codecver => codecver,
      extctrlen => extctrlen
      )
    port map (
      clk => clk,
      rst => rst,
      ahbmi => mi,
      ahbmo => mo,
      apbsi => si,
      apbso => so,
      codec_clk => codec_clk,
      codec_rst => codec_rst,
      txout => gr1553b_txout,
      txout_fb => gr1553b_txout,
      rxin => gr1553b_rxin,
      auxin => auxin,
      auxout => auxout
      );

  mi.hgrant(0) <= mi_hgrant;
  mi.hgrant(1 to NAHBMST-1) <= (others => '0');
  mi.hready <= mi_hready;
  mi.hresp <= mi_hresp;
  mi.hrdata <= ahbdrivedata(mi_hrdata);
  mi.hirq <= (others => '0');
  mi.testen <= '0';
  mi.testrst <= '0';
  mi.scanen <= '0';
  mi.testoen <= '0';
  mi.testin <= (others => '0');

  mo_hbusreq <= mo.hbusreq;
  mo_htrans <= mo.htrans;
  mo_haddr <= mo.haddr;
  mo_hwrite <= mo.hwrite;
  mo_hsize <= mo.hsize;
  mo_hburst <= mo.hburst;
  mo_hwdata <= ahbreadword(mo.hwdata);

  si.psel(0) <= si_psel;
  si.psel(1 to NAPBSLV-1) <= (others => '0');
  si.penable <= si_penable;
  si.paddr <= x"000000" & si_paddr;
  si.pwrite <= si_pwrite;
  si.pwdata <= si_pwdata;
  si.pirq <= (others => '0');
  si.testen <= '0';
  si.testrst <= '0';
  si.scanen <= '0';
  si.testoen <= '0';
  si.testin <= (others => '0');

  so_prdata <= so.prdata;
  so_pirq <= so.pirq(0);

  auxin.extsync <= bcsync;
  auxin.rtaddr <= rtaddr;
  auxin.rtpar <= rtaddrp;
  auxin.extctrl.rten <= extctrl_rten;
  auxin.extctrl.rtaddr <= extctrl_rtaddr;
  auxin.extctrl.brs <= extctrl_brs;
  auxin.extctrl.sys <= extctrl_sys;
  auxin.extctrl.syds <= extctrl_syds;
  auxin.extctrl.busy <= extctrl_busy;
  auxin.extctrl.satb <= extctrl_satb;
  auxin.extctrl.mccr <= extctrl_mccr;
  rtsync <= auxout.rtsync;
  busreset <= auxout.busreset;
  validcmda <= auxout.validcmda;
  validcmdb <= auxout.validcmdb;
  timedouta <= auxout.timedouta;
  timedoutb <= auxout.timedoutb;
  badreg <= auxout.badreg;
  irqvec <= auxout.irqvec;

  busainen <= gr1553b_txout.busA_rxen;
  gr1553b_rxin.busA_rxP <= busainp;
  gr1553b_rxin.busA_rxN <= busainn;
  busaouten <= gr1553b_txout.busA_txen;
  busaoutp <= gr1553b_txout.busA_txP;
  busaoutn <= gr1553b_txout.busA_txN;
  busa_txin <= gr1553b_txout.busA_txin;

  busBinen <= gr1553b_txout.busB_rxen;
  gr1553b_rxin.busB_rxP <= busBinp;
  gr1553b_rxin.busB_rxN <= busBinn;
  busBouten <= gr1553b_txout.busB_txen;
  busBoutp <= gr1553b_txout.busB_txP;
  busBoutn <= gr1553b_txout.busB_txN;
  busb_txin <= gr1553b_txout.busB_txin;

end;

