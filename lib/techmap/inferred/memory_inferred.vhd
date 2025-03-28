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
-- Entity: 	various
-- File:	memory_inferred.vhd
-- Author:	Jiri Gaisler Gaisler Research
-- Description:	Behavioural memory generators
------------------------------------------------------------------------------

-- synchronous 1-port ram

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_syncram is
  generic ( abits : integer := 10; dbits : integer := 8; pipeline : integer := 0; rdhold: integer := 0; gatedwr : integer := 0 );
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    write    : in std_ulogic;
    enable   : in std_ulogic
  ); 
end;     

architecture behavioral of generic_syncram is

  type mem is array(0 to (2**abits -1)) 
	of std_logic_vector((dbits -1) downto 0);
  signal memarr : mem;
  signal ra  : std_logic_vector((abits -1) downto 0);

begin

  main : process(clk)
  begin
    if rising_edge(clk) then
      if write = '1' and (gatedwr=0 or enable='1') then
        memarr(conv_integer(address)) <= datain;
      end if;
      if (rdhold=0 or enable='1') then
        ra <= address;
      end if;
    end if;
  end process;

  nopipe : if pipeline = 0 generate
    dataout <= memarr(conv_integer(ra));
  end generate;
  pipe : if pipeline /= 0 generate
    pp : process(clk)
    begin
      if rising_edge(clk) then
        dataout <= memarr(conv_integer(ra));
      end if;
    end process;
  end generate;

end;

-- synchronous 1-port ram, flip-flops

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_syncram_reg is
  generic ( abits : integer := 10; dbits : integer := 8; pipeline : integer := 0 );
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector((abits -1) downto 0);
    datain   : in std_logic_vector((dbits -1) downto 0);
    dataout  : out std_logic_vector((dbits -1) downto 0);
    write    : in std_ulogic
  ); 
end;     

architecture behavioral of generic_syncram_reg is

  type mem is array(0 to (2**abits -1)) 
	of std_logic_vector((dbits -1) downto 0);
  signal memarr : mem;
  signal ra  : std_logic_vector((abits -1) downto 0);

  attribute syn_ramstyle : string;
  attribute syn_ramstyle of memarr : signal is "registers";                               
begin

  main : process(clk)
  begin
    if rising_edge(clk) then
      if write = '1' then
        memarr(conv_integer(address)) <= datain;
      end if;
      ra <= address;
    end if;
  end process;

  nopipe : if pipeline = 0 generate
    dataout <= memarr(conv_integer(ra));
  end generate;
  pipe : if pipeline /= 0 generate
    pp : process(clk)
    begin
      if rising_edge(clk) then
        dataout <= memarr(conv_integer(ra));
      end if;
    end process;
  end generate;

end;

-- synchronous 2-port ram

LIBRARY ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_syncram_2p is
  generic (
    abits : integer := 8;
    dbits : integer := 32;
    sepclk: integer := 0;
    pipeline: integer := 0;
    rdhold: integer := 0
  );
  port (
    rclk : in std_ulogic;
    wclk : in std_ulogic;
    rdaddress: in std_logic_vector (abits -1 downto 0);
    wraddress: in std_logic_vector (abits -1 downto 0);
    data: in std_logic_vector (dbits -1 downto 0);
    wren : in std_ulogic;
    q: out std_logic_vector (dbits -1 downto 0);
    rden : in std_ulogic := '1'
  );
end;

architecture behav of generic_syncram_2p is
  type dregtype is array (0 to 2**abits - 1) 
	of std_logic_vector(dbits -1 downto 0);
  signal rfd : dregtype;
  signal rdaddressx : std_logic_vector (abits -1 downto 0);
begin

  wp : process(wclk)
  begin
    if rising_edge(wclk) then
      if wren = '1' then rfd(conv_integer(wraddress)) <= data; end if;
    end if;
  end process;

  nopipe : if pipeline = 0 generate
    rdaddressx <= rdaddress;
  end generate;
  
  oneclk : if sepclk = 0 generate
    pipe : if pipeline /= 0 generate
      pp : process(wclk)
      begin
        if rising_edge(wclk) then rdaddressx <= rdaddress; end if;
      end process;
    end generate;
    rp : process(wclk)
    begin
      if rising_edge(wclk) then
        if rdhold=0 or rden='1' then
          q <= rfd(conv_integer(rdaddressx));
        end if;
      end if;
    end process;
  end generate;

  twoclk : if sepclk /= 0 generate
    pipe : if pipeline /= 0 generate
      pp : process(rclk)
      begin
        if rising_edge(rclk) then rdaddressx <= rdaddress; end if;
      end process;
    end generate;  
    rp : process(rclk)
    begin
      if rising_edge(rclk) then
        if rdhold=0 or rden='1' then
          q <= rfd(conv_integer(rdaddressx));
        end if;
      end if;
    end process;
  end generate;

end;


-- synchronous 2-port ram, flip-flops

LIBRARY ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_syncram_2p_reg is
  generic (
    abits : integer := 8;
    dbits : integer := 32;
    sepclk: integer := 0;
    pipeline: integer := 0
  );
  port (
    rclk : in std_ulogic;
    wclk : in std_ulogic;
    rdaddress: in std_logic_vector (abits -1 downto 0);
    wraddress: in std_logic_vector (abits -1 downto 0);
    data: in std_logic_vector (dbits -1 downto 0);
    wren : in std_ulogic;
    q: out std_logic_vector (dbits -1 downto 0)
  );
end;

architecture behav of generic_syncram_2p_reg is
  type dregtype is array (0 to 2**abits - 1) 
	of std_logic_vector(dbits -1 downto 0);
  signal rfd : dregtype;
  signal wa, ra : std_logic_vector (abits -1 downto 0);
  attribute syn_ramstyle : string;
  attribute syn_ramstyle of rfd : signal is "registers";                               
begin

  wp : process(wclk)
  begin
    if rising_edge(wclk) then
      if wren = '1' then rfd(conv_integer(wraddress)) <= data; end if;
    end if;
  end process;

  oneclk : if sepclk = 0 generate
    rp : process(wclk) begin
    if rising_edge(wclk) then ra <= rdaddress; end if;
    end process;
    pipe : if pipeline /= 0 generate
      pp : process(wclk)
      begin
        if rising_edge(wclk) then q <= rfd(conv_integer(ra)); end if;
      end process;
    end generate;
  end generate;

  twoclk : if sepclk /= 0 generate
    rp : process(rclk) begin
    if rising_edge(rclk) then ra <= rdaddress; end if;
    end process;
    pipe : if pipeline /= 0 generate
      pp : process(rclk)
      begin
        if rising_edge(rclk) then q <= rfd(conv_integer(ra)); end if;
      end process;
    end generate;
  end generate;

  nopipe : if pipeline = 0 generate
    q <= rfd(conv_integer(ra));
  end generate;

end;

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_regfile_3p is
  generic (tech : integer := 0; abits : integer := 6; dbits : integer := 32;
           wrfst : integer := 0; numregs : integer := 40; delout: integer := 0);
  port (
    wclk   : in  std_ulogic;
    waddr  : in  std_logic_vector((abits -1) downto 0);
    wdata  : in  std_logic_vector((dbits -1) downto 0);
    we     : in  std_ulogic;
    rclk   : in  std_ulogic;
    raddr1 : in  std_logic_vector((abits -1) downto 0);
    re1    : in  std_ulogic;
    rdata1 : out std_logic_vector((dbits -1) downto 0);
    raddr2 : in  std_logic_vector((abits -1) downto 0);
    re2    : in  std_ulogic;
    rdata2 : out std_logic_vector((dbits -1) downto 0);
    pre1   : out std_ulogic;
    pre2   : out std_ulogic;
    prdata1 : out std_logic_vector((dbits -1) downto 0);
    prdata2 : out std_logic_vector((dbits -1) downto 0)
  );
end;

architecture rtl of generic_regfile_3p is
  type mem is array(0 to numregs-1) 
	of std_logic_vector((dbits -1) downto 0);
  signal memarr : mem;
  signal ra1, ra2, wa  : std_logic_vector((abits -1) downto 0);
  signal din  : std_logic_vector((dbits -1) downto 0);
  signal wr  : std_ulogic;

  signal re1d,re1dd,re2d,re2dd: std_ulogic;
  signal rdata1i,rdata2i,rdata1d,rdata2d: std_logic_vector(dbits-1 downto 0);
begin

  main : process(wclk)
  begin
    if rising_edge(wclk) then
      din <= wdata; wr <= we; 
      if (we = '1')
-- pragma translate_off
	and (conv_integer(waddr) < numregs)
-- pragma translate_on
      then wa <= waddr; end if;
      if (re1 = '1') 
-- pragma translate_off
	and (conv_integer(raddr1) < numregs)
-- pragma translate_on
      then ra1 <= raddr1; end if;
      if (re2 = '1') 
-- pragma translate_off
	and (conv_integer(raddr2) < numregs)
-- pragma translate_on
      then ra2 <= raddr2; end if;
      if wr = '1' then
        memarr(conv_integer(wa)) <= din;
      end if;
    end if;
  end process;

  rdata1i <= din when (wr = '1') and (wa = ra1) and (wrfst = 1)
	else memarr(conv_integer(ra1));
  rdata2i <= din when (wr = '1') and (wa = ra2) and (wrfst = 1)
	else memarr(conv_integer(ra2));

  rdata1 <= rdata1i;
  rdata2 <= rdata2i;

  delgen: if delout /= 0 generate
    p: process(wclk)
    begin
      if rising_edge(wclk) then
        re1d <= re1;
        re2d <= re2;
        re1dd <= re1d;
        re2dd <= re2d;
        rdata1d <= rdata1i;
        rdata2d <= rdata2i;
      end if;
    end process;
  end generate;

  ndelgen: if delout=0 generate
    re1d <= '0'; re2d <= '0';
    re1dd <= '0'; re2dd <= '0';
    rdata1d <= (others => '0');
    rdata2d <= (others => '0');
  end generate;

  pre1 <= re1dd;
  pre2 <= re2dd;
  prdata1 <= rdata1d;
  prdata2 <= rdata2d;

end;


library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.stdlib.all;

entity generic_regfile_4p is
  generic (tech : integer := 0; abits : integer := 6; dbits : integer := 32;
           wrfst : integer := 0; numregs : integer := 40; g0addr: integer := 0;
           delout : integer := 0);
  port (
    wclk   : in  std_ulogic;
    waddr  : in  std_logic_vector((abits -1) downto 0);
    wdata  : in  std_logic_vector((dbits -1) downto 0);
    we     : in  std_ulogic;
    rclk   : in  std_ulogic;
    raddr1 : in  std_logic_vector((abits -1) downto 0);
    re1    : in  std_ulogic;
    rdata1 : out std_logic_vector((dbits -1) downto 0);
    raddr2 : in  std_logic_vector((abits -1) downto 0);
    re2    : in  std_ulogic;
    rdata2 : out std_logic_vector((dbits -1) downto 0);
    raddr3 : in  std_logic_vector((abits -1) downto 0);
    re3    : in  std_ulogic;
    rdata3 : out std_logic_vector((dbits -1) downto 0);
    pre1   : out std_ulogic;
    pre2   : out std_ulogic;
    pre3   : out std_ulogic;
    prdata1 : out std_logic_vector((dbits -1) downto 0);
    prdata2 : out std_logic_vector((dbits -1) downto 0);
    prdata3 : out std_logic_vector((dbits -1) downto 0)
  );
end;

architecture rtl of generic_regfile_4p is
  type mem is array(0 to numregs-1) 
	of std_logic_vector((dbits -1) downto 0);
  signal memarr : mem;
  signal ra1, ra2, ra3, wa  : std_logic_vector((abits -1) downto 0);
  signal din  : std_logic_vector((dbits -1) downto 0);
  signal wr  : std_ulogic;

  signal re1d,re1dd,re2d,re2dd,re3d,re3dd: std_ulogic;
  signal rdata1i,rdata2i,rdata3i,rdata1d,rdata2d,rdata3d: std_logic_vector(dbits-1 downto 0);
begin

  main : process(wclk)
  begin
    if rising_edge(wclk) then
      din <= wdata; wr <= we; 
      if (we = '1')
-- pragma translate_off
	and (conv_integer(waddr) < numregs)
-- pragma translate_on
      then wa <= waddr; end if;
      if (re1 = '1') 
-- pragma translate_off
	and (conv_integer(raddr1) < numregs)
-- pragma translate_on
      then ra1 <= raddr1; end if;
      if (re2 = '1') 
-- pragma translate_off
	and (conv_integer(raddr2) < numregs)
-- pragma translate_on
      then ra2 <= raddr2; end if;
      if (re3 = '1') 
-- pragma translate_off
	and (conv_integer(raddr3) < numregs)
-- pragma translate_on
      then ra3 <= raddr3; end if;
      if wr = '1' then
        memarr(conv_integer(wa)) <= din;
      end if;
      if g0addr > 0 and g0addr < numregs then
        memarr(g0addr) <= (others => '0');
      end if;
    end if;
  end process;

  rdata1i <= din when (wr = '1') and (wa = ra1) and (wrfst = 1)
	else memarr(conv_integer(ra1));
  rdata2i <= din when (wr = '1') and (wa = ra2) and (wrfst = 1)
	else memarr(conv_integer(ra2));
  rdata3i <= din when (wr = '1') and (wa = ra3) and (wrfst = 1)
	else memarr(conv_integer(ra3));

  rdata1 <= rdata1i;
  rdata2 <= rdata2i;
  rdata3 <= rdata3i;

  delgen: if delout /= 0 generate
    p: process(wclk)
    begin
      if rising_edge(wclk) then
        re1d <= re1;
        re2d <= re2;
        re3d <= re3;
        re1dd <= re1d;
        re2dd <= re2d;
        re3dd <= re3d;
        rdata1d <= rdata1i;
        rdata2d <= rdata2i;
        rdata3d <= rdata3i;
      end if;
    end process;
  end generate;

  ndelgen: if delout=0 generate
    re1d <= '0'; re2d <= '0'; re3d <= '0';
    re1dd <= '0'; re2dd <= '0'; re3dd <= '0';
    rdata1d <= (others => '0');
    rdata2d <= (others => '0');
    rdata3d <= (others => '0');
  end generate;

  pre1 <= re1dd;
  pre2 <= re2dd;
  pre3 <= re3dd;
  prdata1 <= rdata1d;
  prdata2 <= rdata2d;
  prdata3 <= rdata3d;

end;

