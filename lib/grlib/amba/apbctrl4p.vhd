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
-- Entity:      apbctrl3p
-- File:        apbctrl3p.vhd
-- Author:      Nils Wessman - Gaisler
-- Description: 4-port wrapper for AMBA AHB/APB bridge
------------------------------------------------------------------------------ 

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.config_types.all;
use grlib.config.all;
use grlib.amba.all;
use grlib.stdlib.all;

entity apbctrl4p is
  generic (
    hindex0     : integer := 0;
    haddr0      : integer := 0;
    hmask0      : integer := 16#fff#;
    hindex1     : integer := 0;
    haddr1      : integer := 0;
    hmask1      : integer := 16#fff#;
    hindex2     : integer := 0;
    haddr2      : integer := 0;
    hmask2      : integer := 16#fff#;
    hindex3     : integer := 0;
    haddr3      : integer := 0;
    hmask3      : integer := 16#fff#;
    nslaves     : integer range 1 to NAPBSLV := NAPBSLV;
    wprot       : integer range 0 to 2 := 0;
    debug       : integer range 0 to 2 := 2;
    icheck      : integer range 0 to 1 := 1;
    enbusmon    : integer range 0 to 1 := 0;
    asserterr   : integer range 0 to 1 := 0;
    assertwarn  : integer range 0 to 1 := 0;
    pslvdisable : integer := 0;
    mcheck      : integer range 0 to 1 := 1;
    ccheck      : integer range 0 to 1 := 1
    );
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahb0i   : in  ahb_slv_in_type;
    ahb0o   : out ahb_slv_out_type;
    ahb1i   : in  ahb_slv_in_type;
    ahb1o   : out ahb_slv_out_type;
    ahb2i   : in  ahb_slv_in_type;
    ahb2o   : out ahb_slv_out_type;
    ahb3i   : in  ahb_slv_in_type;
    ahb3o   : out ahb_slv_out_type;
    apbi    : out apb_slv_in_vector;
    apbo    : in  apb_slv_out_vector;
    wp      : in  std_logic_vector(0 to 3) := (others => '0');
    wpv     : in  std_logic_vector((256*4)-1 downto 0) := (others => '0')
  );
end;

architecture struct of apbctrl4p is
signal lahbi    : ahb_slv_in_vector_type(0 to 3);
signal lahbo    : ahb_slv_out_vector_type(0 to 3);
begin

  lahbi(0) <= ahb0i;
  lahbi(1) <= ahb1i;
  lahbi(2) <= ahb2i;
  lahbi(3) <= ahb3i;
  ahb0o <= lahbo(0);
  ahb1o <= lahbo(1);
  ahb2o <= lahbo(2);
  ahb3o <= lahbo(3);

  apbx : apbctrlx
    generic map(
      hindex0     => hindex0,
      haddr0      => haddr0,
      hmask0      => hmask0,
      hindex1     => hindex1,
      haddr1      => haddr1,
      hmask1      => hmask1,
      hindex2     => hindex2,
      haddr2      => haddr2,
      hmask2      => hmask2,
      hindex3     => hindex3,
      haddr3      => haddr3,
      hmask3      => hmask3,
      nslaves     => nslaves,
      nports      => 4,
      wprot       => wprot,
      debug       => debug,
      icheck      => icheck,
      enbusmon    => enbusmon,
      asserterr   => asserterr,
      assertwarn  => assertwarn,
      pslvdisable => pslvdisable,
      mcheck      => mcheck,
      ccheck      => ccheck)
    port map(
      rst         => rst,
      clk         => clk,
      ahbi        => lahbi,
      ahbo        => lahbo,
      apbi        => apbi,
      apbo        => apbo,
      wp          => wp,
      wpv         => wpv);
end;

