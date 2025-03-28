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
-- Package: 	i2c
-- File:	i2c.vhd
-- Author:	Jiri Gaisler - Gaisler Research
-- Description:	I2C interface package
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library grlib;
use grlib.amba.all;

package i2c is

  type i2c_in_type is record
      scl : std_ulogic;
      sda : std_ulogic;
  end record;
  type i2c_in_vector_type is array (natural range <>) of i2c_in_type;

  constant i2c_in_none : i2c_in_type := ('0', '0');
  
  type i2c_out_type is record
      scl    : std_ulogic;
      scloen : std_ulogic;
      sda    : std_ulogic;
      sdaoen : std_ulogic;
      enable : std_ulogic;
  end record;
  type i2c_out_vector_type is array (natural range <>) of i2c_out_type;

  constant i2c_out_none : i2c_out_type := ('0', '0', '0', '0', '0');
  
  -- AMBA wrapper for OC I2C-master
  component i2cmst
    generic (
      pindex  : integer;
      paddr   : integer;
      pmask   : integer;
      pirq    : integer;
      oepol   : integer range 0 to 1 := 0;
      filter  : integer range 2 to 512 := 2;
      dynfilt : integer range 0 to 1 := 0
      );
    port (
      rstn   : in  std_ulogic;
      clk    : in  std_ulogic;
      apbi   : in  apb_slv_in_type;
      apbo   : out apb_slv_out_type;
      i2ci   : in  i2c_in_type;
      i2co   : out i2c_out_type
    );
  end component;

  component i2cmst_gen
    generic (
      oepol  : integer range 0 to 1 := 0;
      filter  : integer range 2 to 512 := 2;
      dynfilt : integer range 0 to 1 := 0
      );
    port (
      rstn        : in  std_ulogic;
      clk         : in  std_ulogic;
      psel        : in  std_ulogic;
      penable     : in  std_ulogic;
      paddr       : in  std_logic_vector(31 downto 0);
      pwrite      : in  std_ulogic;
      pwdata      : in  std_logic_vector(31 downto 0);
      prdata      : out std_logic_vector(31 downto 0);
      irq         : out std_logic;
      i2ci_scl    : in  std_ulogic;
      i2ci_sda    : in  std_ulogic;
      i2co_scl    : out std_ulogic;
      i2co_scloen : out std_ulogic;
      i2co_sda    : out std_ulogic;
      i2co_sdaoen : out std_ulogic;
      i2co_enable : out std_ulogic
      );
  end component;

  -- I2C slave
  component i2cslv
    generic (
      pindex  : integer := 0;
      paddr   : integer := 0;
      pmask   : integer := 16#fff#;
      pirq    : integer := 0;
      hardaddr : integer range 0 to 1 := 0;
      tenbit   : integer range 0 to 1 := 0;
      i2caddr  : integer range 0 to 1023 := 0;
      oepol    : integer range 0 to 1 := 0;
      filter   : integer range 2 to 512 := 2
      );
    port (
      rstn    : in  std_ulogic;
      clk     : in  std_ulogic;
      apbi    : in  apb_slv_in_type;
      apbo    : out apb_slv_out_type;
      i2ci    : in  i2c_in_type;
      i2co    : out i2c_out_type
      );
  end component;

  -- I2C to AHB bridge

  type i2c2ahb_in_type is record
    haddr   : std_logic_vector(31 downto 0);
    hmask   : std_logic_vector(31 downto 0);
    slvaddr : std_logic_vector(6 downto 0);
    cfgaddr : std_logic_vector(6 downto 0);
    en      : std_ulogic;
  end record;

  type i2c2ahb_out_type is record
    dma     : std_ulogic;
    wr      : std_ulogic;
    prot    : std_ulogic;
  end record;

  component i2c2ahb
    generic (
      -- AHB Configuration
      hindex     : integer := 0;
      --
      ahbaddrh   : integer := 0;
      ahbaddrl   : integer := 0;
      ahbmaskh   : integer := 0;
      ahbmaskl   : integer := 0;
      -- I2C configuration
      i2cslvaddr : integer range 0 to 127 := 0;
      i2ccfgaddr : integer range 0 to 127 := 0;
      oepol      : integer range 0 to 1 := 0;
      --
      filter     : integer range 2 to 512 := 2
      );
    port (
      rstn   : in  std_ulogic;
      clk    : in  std_ulogic;
      -- AHB master interface
      ahbi   : in  ahb_mst_in_type;
      ahbo   : out ahb_mst_out_type;
      -- I2C signals
      i2ci   : in  i2c_in_type;
      i2co   : out i2c_out_type
      );
  end component;
  
  component i2c2ahb_apb
    generic (
      -- AHB Configuration
      hindex     : integer := 0;
      --
      ahbaddrh   : integer := 0;
      ahbaddrl   : integer := 0;
      ahbmaskh   : integer := 0;
      ahbmaskl   : integer := 0;
      resen      : integer := 0;
      -- APB configuration
      pindex     : integer := 0;
      paddr      : integer := 0;
      pmask      : integer := 16#fff#;
      pirq       : integer := 0;
      -- I2C configuration
      i2cslvaddr : integer range 0 to 127 := 0;
      i2ccfgaddr : integer range 0 to 127 := 0;
      oepol      : integer range 0 to 1 := 0;
      rstaddr    : integer range 0 to 1 := 0;
      --
      filter     : integer range 2 to 512 := 2
      );
    port (
      rstn   : in  std_ulogic;
      clk    : in  std_ulogic;
      -- AHB master interface
      ahbi   : in  ahb_mst_in_type;
      ahbo   : out ahb_mst_out_type;
      --
      apbi   : in  apb_slv_in_type;
      apbo   : out apb_slv_out_type;
      -- I2C signals
      i2ci   : in  i2c_in_type;
      i2co   : out i2c_out_type;
      i2crstaddr :  in std_logic_vector(2 downto 0)
      );
  end component;

  component i2c2ahbx
    generic (
      -- AHB configuration
      hindex   : integer := 0;
      oepol    : integer range 0 to 1 := 0;
      filter   : integer range 2 to 512 := 2
      );
    port (
      rstn     : in  std_ulogic;
      clk      : in  std_ulogic;
      -- AHB master interface
      ahbi     : in  ahb_mst_in_type;
      ahbo     : out ahb_mst_out_type;
      -- I2C signals
      i2ci     : in  i2c_in_type;
      i2co     : out i2c_out_type;
      --
      i2c2ahbi : in  i2c2ahb_in_type;
      i2c2ahbo : out i2c2ahb_out_type
      );
  end component;

  component i2c2ahb_gen
    generic (
      ahbaddrh   : integer := 0;
      ahbaddrl   : integer := 0;
      ahbmaskh   : integer := 0;
      ahbmaskl   : integer := 0;
      -- I2C configuration
      i2cslvaddr : integer range 0 to 127 := 0;
      i2ccfgaddr : integer range 0 to 127 := 0;
      oepol      : integer range 0 to 1 := 0;
      --
      filter     : integer range 2 to 512 := 2
      );
    port (
      rstn          : in  std_ulogic;
      clk           : in  std_ulogic;
      -- AHB master interface
      ahbi_hgrant   : in  std_ulogic;
      ahbi_hready   : in  std_ulogic;
      ahbi_hresp    : in  std_logic_vector(1 downto 0);
      ahbi_hrdata   : in  std_logic_vector(31 downto 0);
      --ahbo   : out ahb_mst_out_type;
      ahbo_hbusreq  : out  std_ulogic;
      ahbo_hlock    : out  std_ulogic;
      ahbo_htrans   : out  std_logic_vector(1 downto 0);
      ahbo_haddr    : out  std_logic_vector(31 downto 0);
      ahbo_hwrite   : out  std_ulogic;
      ahbo_hsize    : out  std_logic_vector(2 downto 0);
      ahbo_hburst   : out  std_logic_vector(2 downto 0);
      ahbo_hprot    : out  std_logic_vector(3 downto 0);
      ahbo_hwdata   : out  std_logic_vector(31 downto 0);
      -- I2C signals
      --i2ci    : in  i2c_in_type;
      i2ci_scl      : in  std_ulogic;
      i2ci_sda      : in  std_ulogic;
      --i2co    : out i2c_out_type
      i2co_scl      : out std_ulogic;
      i2co_scloen   : out std_ulogic;
      i2co_sda      : out std_ulogic;
      i2co_sdaoen   : out std_ulogic;
      i2co_enable   : out std_ulogic
      );
  end component;

  component i2c2ahb_apb_gen
    generic (
      ahbaddrh   : integer := 0;
      ahbaddrl   : integer := 0;
      ahbmaskh   : integer := 0;
      ahbmaskl   : integer := 0;
      resen      : integer := 0;
      -- APB configuration
      pindex     : integer := 0;         -- slave bus index
      paddr      : integer := 0;
      pmask      : integer := 16#fff#;
      pirq       : integer := 0;
      -- I2C configuration
      i2cslvaddr : integer range 0 to 127 := 0;
      i2ccfgaddr : integer range 0 to 127 := 0;
      oepol      : integer range 0 to 1 := 0;
      rstaddr    : integer range 0 to 1 := 0;
      --
      filter     : integer range 2 to 512 := 2
      );
    port (
      rstn          : in  std_ulogic;
      clk           : in  std_ulogic;
      -- AHB master interface
      --ahbi   : in  ahb_mst_in_type;
      ahbi_hgrant   : in  std_ulogic;
      ahbi_hready   : in  std_ulogic;
      ahbi_hresp    : in  std_logic_vector(1 downto 0);
      ahbi_hrdata   : in  std_logic_vector(31 downto 0);
      --ahbo   : out ahb_mst_out_type;
      ahbo_hbusreq  : out  std_ulogic;
      ahbo_hlock    : out  std_ulogic;
      ahbo_htrans   : out  std_logic_vector(1 downto 0);
      ahbo_haddr    : out  std_logic_vector(31 downto 0);
      ahbo_hwrite   : out  std_ulogic;
      ahbo_hsize    : out  std_logic_vector(2 downto 0);
      ahbo_hburst   : out  std_logic_vector(2 downto 0);
      ahbo_hprot    : out  std_logic_vector(3 downto 0);
      ahbo_hwdata   : out  std_logic_vector(31 downto 0);
      -- APB slave interface
      apbi_psel     : in  std_ulogic;
      apbi_penable  : in  std_ulogic;
      apbi_paddr    : in  std_logic_vector(31 downto 0);
      apbi_pwrite   : in  std_ulogic;
      apbi_pwdata   : in  std_logic_vector(31 downto 0);
      apbo_prdata   : out std_logic_vector(31 downto 0);
      apbo_irq      : out std_logic;
      -- I2C signals
      --i2ci    : in  i2c_in_type;
      i2ci_scl      : in  std_ulogic;
      i2ci_sda      : in  std_ulogic;
      --i2co    : out i2c_out_type
      i2co_scl      : out std_ulogic;
      i2co_scloen   : out std_ulogic;
      i2co_sda      : out std_ulogic;
      i2co_sdaoen   : out std_ulogic;
      i2co_enable   : out std_ulogic;
      i2crstaddr    : in std_logic_vector(2 downto 0)
      );
  end component;

end;

