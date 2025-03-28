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
-- Entity:      cachememnv
-- File:        cachememnv.vhd
-- Author:      Magnus Hjorth - Cobham Gaisler
-- Description: Memory instantiations for both instruction and data caches
------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library techmap;
use techmap.gencomp.all;
library grlib;
use grlib.stdlib.log2;
use grlib.stdlib.notx;
use grlib.stdlib.setx;
use grlib.stdlib.tost_bits;
use grlib.stdlib.tost;
use grlib.stdlib.print;
library gaisler;
use gaisler.utilnv.u2i;
use gaisler.noelvint.nv_cram_in_type;
use gaisler.noelvint.nv_cram_out_type;
use gaisler.utilnv.b2i;

entity cachememnv is
  generic (
    tech      : integer range 0 to NTECH;
    iways     : integer range 1 to 8;
    ilinesize : integer range 4 to 8;
    iidxwidth : integer range 1 to 10;
    itagwidth : integer range 1 to 32;
    itcmen    : integer range 0 to 1;
    itcmabits : integer range 1 to 20;
    dways     : integer range 1 to 8;
    dlinesize : integer range 4 to 8;
    didxwidth : integer range 1 to 10;
    dtagwidth : integer range 1 to 32;
    dtagconf  : integer range 0 to 2;
    dusebw    : integer range 0 to 1;
    dtcmen    : integer range 0 to 1;
    dtcmabits : integer range 1 to 20;
    testen    : integer range 0 to 1
  );
  port (
        rstn   : in  std_ulogic;
        clk    : in  std_ulogic;
        sclk   : in  std_ulogic;
        crami  : in  nv_cram_in_type;
        cramo  : out nv_cram_out_type;
        testin : in  std_logic_vector(TESTIN_WIDTH-1 downto 0)
  );


end;

architecture rtl of cachememnv is

  -- Only used for ranges
  constant iidx     : std_logic_vector(iidxwidth - 1 downto 0)                   := (others => '0');
  constant itag_hi  : std_logic_vector(cramo.itagdout(0)'high downto itagwidth)  := (others => '0');
  constant itag_lo  : std_logic_vector(itagwidth - 1 downto 0)                   := (others => '0');
  constant itag_lo1 : std_logic_vector(itagwidth - 1 downto 1)                   := (others => '0');
  constant didx     : std_logic_vector(didxwidth - 1 downto 0)                   := (others => '0');
  constant dtag_hi  : std_logic_vector(cramo.dtagcdout(0)'high downto dtagwidth) := (others => '0');
  constant dtag_lo  : std_logic_vector(dtagwidth - 1 downto 0)                   := (others => '0');
  constant dtag_lo1 : std_logic_vector(dtagwidth - 1 downto 1)                   := (others => '0');

  signal idataaddr  : std_logic_vector(iidxwidth + log2(ilinesize) - 2 downto 0);
  signal ddataaddr  : std_logic_vector(didxwidth + log2(dlinesize) - 2 downto 0);

  signal gndv: std_logic_vector(dtag_lo'range);

  type denv_type is array(0 to 3) of std_logic_vector(7 downto 0);
  signal denv     : denv_type;
  signal denvtcm  : std_logic_vector(7 downto 0);


begin

  gndv <= (others => '0');

  -- Instruction cache tag RAMs

  itagloop: for s in 0 to iways-1 generate
    itagmem: syncram
      generic map (
        tech       => tech,
        abits      => iidxwidth,
        dbits      => itagwidth,
        testen     => testen,
        custombits => memtest_vlen,
        pipeline   => 0,
        rdhold     => 1,
        gatedwr    => 1
        )
      port map (
        clk     => clk,
        address => crami.iindex(iidx'range),
        datain  => crami.itagdin(s)(itag_lo'range),
        dataout => cramo.itagdout(s)(itag_lo'range),
        enable  => crami.itagen(s),
        write   => crami.itagwrite,
        testin  => testin
        );
    cramo.itagdout(s)(itag_hi'range) <= (others => '0');
  end generate;

  -- Instruction cache data RAMs
  idataaddr <= crami.iindex(iidx'range) & crami.idataoffs(log2(ilinesize)-2 downto 0);
  idataloop: for s in 0 to iways-1 generate
    idatamemh: syncram
      generic map (
        tech       => tech,
        abits      => iidxwidth + log2(ilinesize) - 1,
        dbits      => 32,
        testen     => testen,
        custombits => memtest_vlen,
        pipeline   => 0,
        rdhold     => 1,
        gatedwr    => 1
        )
      port map (
        clk     => clk,
        address => idataaddr,
        datain  => crami.idatadin(63 downto 32),
        dataout => cramo.idatadout(s)(63 downto 32),
        enable  => crami.idataen(s),
        write   => crami.idatawrite(1),
        testin  => testin
        );
    idatameml: syncram
      generic map (
        tech       => tech,
        abits      => iidxwidth + log2(ilinesize) - 1,
        dbits      => 32,
        testen     => testen,
        custombits => memtest_vlen,
        pipeline   => 0,
        rdhold     => 1,
        gatedwr    => 1
        )
      port map (
        clk     => clk,
        address => idataaddr,
        datain  => crami.idatadin(31 downto 0),
        dataout => cramo.idatadout(s)(31 downto 0),
        enable  => crami.idataen(s),
        write   => crami.idatawrite(0),
        testin  => testin
        );
  end generate;

  -- Instruction cache tightly coupled memory
  itcm0: if itcmen /= 0 generate
    itcmmemh: syncram
      generic map (
        tech       => tech,
        abits      => itcmabits,
        dbits      => 32,
        testen     => testen,
        custombits => memtest_vlen,
        pipeline   => 0,
        rdhold     => 1,
        gatedwr    => 1
        )
      port map (
        clk     => clk,
        address => crami.ifulladdr(2+itcmabits downto 3),
        datain  => crami.itcmdin(63 downto 32),
        dataout => cramo.itcmdout(63 downto 32),
        enable  => crami.itcmen,
        write   => crami.itcmwrite(1),
        testin  => testin
        );
    itcmmeml: syncram
      generic map (
        tech       => tech,
        abits      => itcmabits,
        dbits      => 32,
        testen     => testen,
        custombits => memtest_vlen,
        pipeline   => 0,
        rdhold     => 1,
        gatedwr    => 1
        )
      port map (
        clk     => clk,
        address => crami.ifulladdr(2+itcmabits downto 3),
        datain  => crami.itcmdin(31 downto 0),
        dataout => cramo.itcmdout(31 downto 0),
        enable  => crami.itcmen,
        write   => crami.itcmwrite(0),
        testin  => testin
        );
  end generate;

  -- Data cache tag RAMs

  dtagconf0: if dtagconf = 0 generate
    -- two memories (1x two-port, 1x one-port), valid bits in two-port memory
    dtagloop: for s in 0 to dways-1 generate
      -- Tag read for regular cache operation
      dtagcmem: syncram_2p
        generic map (
          tech     => tech,
          abits    => didxwidth,
          dbits    => dtagwidth,
          sepclk   => 2,
          wrfst    => 1,
          testen   => testen,
          words    => 0,
          pipeline => 0,
          rdhold   => 1,
          custombits => memtest_vlen
          )
        port map (
          rclk     => clk,
          renable  => crami.dtagcen(s),
          raddress => crami.dtagcindex(didx'range),
          dataout  => cramo.dtagcdout(s)(dtag_lo'range),
          wclk     => sclk,
          write    => crami.dtaguwrite(s),
          waddress => crami.dtaguindex(didx'range),
          datain   => crami.dtagudin(s)(dtag_lo'range),
          testin   => testin
          );
    -- Tag read for snooping
      dtagsmem: syncram
        generic map (
          tech     => tech,
          abits    => didxwidth,
          dbits    => dtagwidth - 1,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk      => sclk,
          address => crami.dtagsindex(didx'range),
          datain   => crami.dtagsdin(s)(dtag_lo1'range),
          dataout  => cramo.dtagsdout(s)(dtag_lo1'range),
          enable   => crami.dtagsen(s),
          write    => crami.dtagswrite,
          testin   => testin
          );
      cramo.dtagcdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagsdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagsdout(s)(0)             <= '1';
    end generate;
  end generate;
  dtagconf1: if dtagconf = 1 generate
    -- 1 x dual-port memory, valid bits in flip flops
    dtagloop: for s in 0 to dways-1 generate
      dtagmem: syncram_dp
        generic map (
          tech     => tech,
          abits    => didxwidth,
          dbits    => dtagwidth - 1,
          testen   => testen,
          sepclk   => 2,
          wrfst    => 1,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          -- Port 1, read for cache operation
          clk1     => clk,
          address1 => crami.dtagcindex(didx'range),
          datain1  => gndv(dtag_lo1'range),
          dataout1 => cramo.dtagcdout(s)(dtag_lo1'range),
          enable1  => crami.dtagcen(s),
          write1   => gndv(0),
          -- Port 2, write for cache update, read for snooping
          clk2     => sclk,
          address2 => crami.dtagsindex(didx'range),
          datain2  => crami.dtagsdin(s)(dtag_lo1'range),
          dataout2 => cramo.dtagsdout(s)(dtag_lo1'range),
          enable2  => crami.dtagsen(s),
          write2   => crami.dtagswrite,
          --
          testin   => testin
          );
      cramo.dtagcdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagsdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagcdout(s)(0)             <= '1';
      cramo.dtagsdout(s)(0)             <= '1';
    end generate;
  end generate;
  dtagconf2: if dtagconf = 2 generate
    -- 2 x single-port memory, valid bits in flip flops
    dtagloop: for s in 0 to dways-1 generate
      -- Tag read for regular cache operation
      dtagcmem: syncram
        generic map (
          tech     => tech,
          abits    => didxwidth,
          dbits    => dtagwidth - 1,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk      => clk,
          address  => crami.dtagcuindex(didx'range),
          datain   => crami.dtagudin(s)(dtag_lo1'range),
          dataout  => cramo.dtagcdout(s)(dtag_lo1'range),
          enable   => crami.dtagcuen(s),
          write    => crami.dtagcuwrite,
          testin   => testin
          );
    -- Tag read for snooping
      dtagsmem: syncram
        generic map (
          tech     => tech,
          abits    => didxwidth,
          dbits    => dtagwidth - 1,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk      => sclk,
          address  => crami.dtagsindex(didx'range),
          datain   => crami.dtagsdin(s)(dtag_lo1'range),
          dataout  => cramo.dtagsdout(s)(dtag_lo1'range),
          enable   => crami.dtagsen(s),
          write    => crami.dtagswrite,
          testin   => testin
          );
      cramo.dtagcdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagsdout(s)(dtag_hi'range) <= (others => '0');
      cramo.dtagcdout(s)(0)             <= '1';
      cramo.dtagsdout(s)(0)             <= '1';
    end generate;
  end generate;

  -- Data cache data RAMs
  ddataaddr <= crami.ddataindex(didx'range) & crami.ddataoffs(log2(dlinesize) - 2 downto 0);
  denv <= (0 => (others => crami.ddataen(0)),
           1 => (others => crami.ddataen(1)),
           2 => (others => crami.ddataen(2)),
           3 => (others => crami.ddataen(3)));
  denvtcm <= (others => crami.dtcmen);
  ddusebw: if dusebw = 1 generate
    -- Memories with byte writes
    ddataloop: for s in 0 to dways-1 generate
      ddatamemh: syncrambw
        generic map (
          tech     => tech,
          abits    => didxwidth + log2(dlinesize) - 1,
          dbits    => 32,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk     => clk,
          address => ddataaddr,
          datain  => crami.ddatadin(s)(63 downto 32),
          dataout => cramo.ddatadout(s)(63 downto 32),
          enable  => denv(s)(7 downto 4),
          write   => crami.ddatawrite(7 downto 4),
          testin  => testin
          );
      ddatameml: syncrambw
        generic map (
          tech     => tech,
          abits    => didxwidth + log2(dlinesize) - 1,
          dbits    => 32,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk     => clk,
          address => ddataaddr,
          datain  => crami.ddatadin(s)(31 downto 0),
          dataout => cramo.ddatadout(s)(31 downto 0),
          enable  => denv(s)(3 downto 0),
          write   => crami.ddatawrite(3 downto 0),
          testin  => testin
          );
    end generate;
  end generate;
  ddnobw: if dusebw = 0 generate
    -- Memories without byte writes, data loopback in cache controller
    ddataloop: for s in 0 to dways-1 generate
      ddatamemh: syncram
        generic map (
          tech     => tech,
          abits    => didxwidth + log2(dlinesize) - 1,
          dbits    => 32,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk     => clk,
          address => ddataaddr,
          datain  => crami.ddatadin(s)(63 downto 32),
          dataout => cramo.ddatadout(s)(63 downto 32),
          enable  => crami.ddataen(s),
          write   => crami.ddatawrite(7),
          testin  => testin
          );
      ddatameml: syncram
        generic map (
          tech     => tech,
          abits    => didxwidth + log2(dlinesize) - 1,
          dbits    => 32,
          testen   => testen,
          pipeline => 0,
          rdhold   => 1,
          gatedwr  => 1,
          custombits => memtest_vlen
          )
        port map (
          clk     => clk,
          address => ddataaddr,
          datain  => crami.ddatadin(s)(31 downto 0),
          dataout => cramo.ddatadout(s)(31 downto 0),
          enable  => crami.ddataen(s),
          write   => crami.ddatawrite(3),
          testin  => testin
          );
    end generate;
  end generate;

  -- Data cache tightly coupled memory
  ddtcmbw : if dtcmen /= 0 and dusebw /= 0 generate
    -- Memories with byte writes
    dtcmmemh: syncrambw
      generic map (
        tech     => tech,
        abits    => dtcmabits,
        dbits    => 32,
        testen   => testen,
        pipeline => 0,
        rdhold   => 1,
        gatedwr  => 1,
        custombits => memtest_vlen
        )
      port map (
        clk     => clk,
        address => crami.ddatafulladdr(2 + dtcmabits downto 3),
        datain  => crami.dtcmdin(63 downto 32),
        dataout => cramo.dtcmdout(63 downto 32),
        enable  => denvtcm(7 downto 4),
        write   => crami.dtcmwrite(7 downto 4),
        testin  => testin
        );
    dtcmmeml: syncrambw
      generic map (
        tech     => tech,
        abits    => dtcmabits,
        dbits    => 32,
        testen   => testen,
        pipeline => 0,
        rdhold   => 1,
        gatedwr  => 1,
        custombits => memtest_vlen
        )
      port map (
        clk     => clk,
        address => crami.ddatafulladdr(2 + dtcmabits downto 3),
        datain  => crami.dtcmdin(31 downto 0),
        dataout => cramo.dtcmdout(31 downto 0),
        enable  => denvtcm(3 downto 0),
        write   => crami.dtcmwrite(3 downto 0),
        testin  => testin
        );
  end generate;

  ddtcmnobw : if dtcmen /= 0 and dusebw = 0 generate
    -- Memories without byte writes, data loopback in cache controller
    dtcmmemh: syncram
      generic map (
        tech     => tech,
        abits    => dtcmabits,
        dbits    => 32,
        testen   => testen,
        pipeline => 0,
        rdhold   => 1,
        gatedwr  => 1,
        custombits => memtest_vlen
        )
      port map (
        clk     => clk,
        address => crami.ddatafulladdr(2 + dtcmabits downto 3),
        datain  => crami.dtcmdin(63 downto 32),
        dataout => cramo.dtcmdout(63 downto 32),
        enable  => crami.dtcmen,
        write   => crami.dtcmwrite(7),
        testin  => testin
        );
    dtcmmeml: syncram
      generic map (
        tech     => tech,
        abits    => dtcmabits,
        dbits    => 32,
        testen   => testen,
        pipeline => 0,
        rdhold   => 1,
        gatedwr  => 1,
        custombits => memtest_vlen
        )
      port map (
        clk     => clk,
        address => crami.ddatafulladdr(2 + dtcmabits downto 3),
        datain  => crami.dtcmdin(31 downto 0),
        dataout => cramo.dtcmdout(31 downto 0),
        enable  => crami.dtcmen,
        write   => crami.dtcmwrite(3),
        testin  => testin
        );
  end generate;


  unusediloop: for s in iways to 7 generate
    cramo.itagdout(s)  <= (others => '0');
    cramo.idatadout(s) <= (others => '0');
  end generate;
  unuseddloop: for s in dways to 7 generate
    cramo.dtagcdout(s) <= (others => '0');
    cramo.dtagsdout(s) <= (others => '0');
    cramo.ddatadout(s) <= (others => '0');
  end generate;

  noitcm: if itcmen = 0 generate
    cramo.itcmdout <= (others => '0');
  end generate;

  nodtcm: if dtcmen = 0 generate
    cramo.dtcmdout <= (others => '0');
  end generate;

-- pragma translate_off
  tagmon: process(sclk)
    subtype itag_type  is std_logic_vector(itag_lo'range);
    type itagset_type  is array(0 to iways - 1) of itag_type;
    type itags_type    is array(0 to 2 ** iidxwidth - 1) of itagset_type;
    variable itags      : itags_type;
    subtype dctag_type is std_logic_vector(dtag_lo'range);
    subtype dstag_type is std_logic_vector(dtag_lo1'range);
    type dctagset_type is array(0 to iways - 1) of dctag_type;
    type dstagset_type is array(0 to iways - 1) of dstag_type;
    type dctags_type   is array(0 to 2 ** iidxwidth - 1) of dctagset_type;
    type dstags_type   is array(0 to 2 ** iidxwidth - 1) of dstagset_type;
    variable dctags     : dctags_type;
    variable dstags     : dstags_type;
    variable idx, cidx  : integer;
    variable itagupd    : boolean;
    variable dtagupd    : boolean;
    type boolarr       is array(natural range <>) of boolean;
    variable ctagupd    : boolarr(0 to DWAYS - 1);
  begin
    if rising_edge(sclk) then
      itagupd := false;
      dtagupd := false;
	    idx := u2i(crami.iindex(iidx'range));
      for w in 0 to IWAYS-1 loop
        assert notx(crami.itagen(w)) report "crami.itagen(" & tost(w) & ") is " & tost(crami.itagen) severity warning;
        assert notx(crami.itagwrite) report "crami.itawrite" & " is " & tost(crami.itagwrite) severity warning;
        if crami.itagen(w) = '1' and crami.itagwrite = '1' then
          itagupd := true;
          itags(idx)(w) := crami.itagdin(w)(itag_lo'range);
          assert notx(crami.itagdin(w)) report "Writing X into Itag!" severity failure;
        end if;
      end loop;
      if itagupd then
        for w1 in 0 to IWAYS-2 loop
          for w2 in w1+1 to IWAYS-1 loop
            if notx(itags(idx)(w1)) then
              assert itags(idx)(w1)(itag_lo1'range) /= itags(idx)(w2)(itag_lo1'range)
                report "Duplicated Itag written" severity failure;
            end if;
          end loop;
        end loop;
      end if;
      ctagupd := (others => false);
      for w in 0 to DWAYS-1 loop
        if dtagconf = 0 and crami.dtaguwrite(w) = '1' then
          cidx         := u2i(crami.dtaguindex(didx'range));
          if notx(dctags(cidx)(w)) then
            dtagupd     := true;
            ctagupd(w) := true;
          end if;
          dctags(cidx)(w) := crami.dtagudin(w)(dtag_lo'range);
          assert notx(crami.dtagudin(w)) report "Writing X into Dtag!" severity failure;
        end if;
        if dtagconf /= 0 and crami.dtagcuen(w) = '1' and crami.dtagcuwrite = '1' then
          cidx := u2i(crami.dtagcuindex(didx'range));
          if notx(dctags(cidx)(w)) then
            dtagupd     := true;
            ctagupd(w) := true;
          end if;
          dctags(cidx)(w) := crami.dtagudin(w)(dtag_lo'range);
          assert notx(crami.dtagudin(w)) report "Writing X into Dtag!" severity failure;
        end if;
        if crami.dtagsen(w) = '1' and crami.dtagswrite = '1' then
          idx      := u2i(crami.dtagsindex(didx'range));
          if notx(dstags(idx)(w)) then
            dtagupd := true;
          end if;
          dstags(idx)(w) := crami.dtagsdin(w)(dtag_lo1'range);
          assert notx(crami.dtagsdin(w)) report "Writing X into Dstag!" severity failure;
        end if;
      end loop;
      if dtagupd then
        for w1 in 0 to DWAYS-2 loop
          if dctags(idx)(w1) = "UUUUUUUUUUUUUUUUUUUUU" then
            next;
          end if;
          for w2 in w1+1 to DWAYS-1 loop
            if dctags(idx)(w2) = "UUUUUUUUUUUUUUUUUUUUU" then
              next;
            end if;
            assert dctags(cidx)(w1)(dtag_lo1'range) /= dctags(cidx)(w2)(dtag_lo1'range)
--              report "Duplicated dtag written" severity failure;
              report "Duplicated dtag written " & tost_bits(dctags(cidx)(w1)) & " " & tost_bits(dctags(cidx)(w2)) &
              " cidx = " & tost(cidx) & " w1 = " & tost(w1) & " w2 = " & tost(w2) severity failure;
            assert dstags(idx)(w1)(dtag_lo1'range) /= dstags(idx)(w2)(dtag_lo1'range)
              or (dtagconf=0 and (dctags(idx)(w1)(0)='0' or dctags(idx)(w2)(0)='0'))
              report "Duplicated snoop-dtag written" severity failure;
          end loop;
        end loop;
        for w in 0 to DWAYS-1 loop
          if ctagupd(w) then
            assert dctags(cidx)(w)(dtag_lo1'range) = dstags(cidx)(w) or dctags(cidx)(w)(0) = '0'
              report "Snoop and regular tag mismatch" severity failure;
          end if;
        end loop;
      end if;
    end if;
  end process;
-- pragma translate_on
end;
