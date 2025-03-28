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
-- Entity: 	iodpad
-- File:	iodpad.vhd
-- Author:	Jiri Gaisler - Gaisler Research
-- Description:	Open-drain I/O pad with technology wrapper
------------------------------------------------------------------------------

library ieee;
library techmap;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;
use techmap.allpads.all;

entity iodpad is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	   voltage : integer := x33v; strength : integer := 12;
	   oepol : integer := 0);
  port (pad : inout std_ulogic; i : in std_ulogic; o : out std_ulogic);
end;

architecture rtl of iodpad is
signal gnd, oen : std_ulogic;
begin
  oen <= not i when oepol /= padoen_polarity(tech) else i;
  gnd <= '0';
  gen0 : if has_pads(tech) = 0 generate
    pad <= '0' 
-- pragma translate_off
	after 2 ns 
-- pragma translate_on
	when oen = '0'
-- pragma translate_off
           else 'X' after 2 ns when is_x(i)
-- pragma translate_on
           else 'Z' 
-- pragma translate_off
	after 2 ns
-- pragma translate_on
	;
    o <= to_X01(pad) 
-- pragma translate_off
	after 1 ns
-- pragma translate_on
	;
  end generate;
  xcv : if (is_unisim(tech) = 1) generate
    x0 : unisim_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  axc : if (tech = axcel) or (tech = axdsp) generate
    x0 : axcel_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  pa : if (tech = proasic) or (tech = apa3) generate
    x0 : apa3_iopad generic map (level, slew, voltage, strength)
         port map (pad, gnd, oen, o);
  end generate;
  pa3e : if (tech = apa3e) generate
    x0 : apa3e_iopad generic map (level, slew, voltage, strength)
         port map (pad, gnd, oen, o);
  end generate;
  igl2 : if (tech = igloo2) or (tech = rtg4) generate
    x0 : igloo2_iopad port map (pad, gnd, oen, o);
  end generate;
  pa3l : if (tech = apa3l) generate
    x0 : apa3l_iopad generic map (level, slew, voltage, strength)
         port map (pad, gnd, oen, o);
  end generate;
  fus : if (tech = actfus) generate
    x0 : fusion_iopad generic map (level, slew, voltage, strength)
         port map (pad, gnd, oen, o);
  end generate;
  atc : if (tech = atc18s) generate
    x0 : atc18_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  atcrh : if (tech = atc18rha) generate
    x0 : atc18rha_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  um : if (tech = umc) generate
    x0 : umc_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  rhu : if (tech = rhumc) generate
    x0 : rhumc_iopad generic map (level, slew, voltage, strength)
	 port map (pad, gnd, oen, o);
  end generate;
  ihp : if (tech = ihp25) generate
    x0 : ihp25_iopad generic map (level, slew, voltage, strength)
         port map (pad, gnd, oen, o);
    end generate;
  rh18t : if (tech = rhlib18t) generate
    x0 : rh_lib18t_iopad generic map (strength)
         port map (pad, gnd, oen, o);
    end generate;
  ut025 : if (tech = ut25) generate
    x0 : ut025crh_iopad generic map (strength)
         port map (pad, gnd, oen, o);
    end generate;
  ut13 : if (tech = ut130) generate
    x0 : ut130hbd_iopad generic map (strength) port map (pad, gnd, oen, o);
  end generate;
  pere  : if (tech = peregrine) generate
    x0 : peregrine_iopad generic map (level, slew, voltage, strength)
         port map(pad, gnd, oen, o);
  end generate;
  nxus   : if (tech = nexus) generate
    x0 : nexus_iopad port map(pad, gnd, oen, o);
  end generate;
end;

library ieee;
library techmap;
use ieee.std_logic_1164.all;
use techmap.gencomp.all;

entity iodpadv is
  generic (tech : integer := 0; level : integer := 0; slew : integer := 0;
	voltage : integer := 0; strength : integer := 0; width : integer := 1;
	oepol : integer := 0);
  port (
    pad : inout std_logic_vector(width-1 downto 0);
    i   : in  std_logic_vector(width-1 downto 0);
    o   : out std_logic_vector(width-1 downto 0));
end;
architecture rtl of iodpadv is
begin
  v : for j in width-1 downto 0 generate
    x0 : iodpad generic map (tech, level, slew, voltage, strength, oepol)
	 port map (pad(j), i(j), o(j));
  end generate;
end;

