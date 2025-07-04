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
-- Entity:      nvsupport
-- File:        nvsupport.vhd
-- Author:      Johan Klockars, Cobham Gaisler AB
-- Description: NOEL-V type/constants/functions that could be broken out of the pipeline.
--              Not everything here can be synthesized!
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library grlib;
use grlib.riscv.all;
use grlib.stdlib.log2;
use grlib.stdlib.log2x;
use grlib.stdlib.tost;
use grlib.stdlib.tost_bits;
use grlib.stdlib.orv;
library gaisler;
use gaisler.l5nv_shared.all;
use gaisler.noelvtypes.all;
use gaisler.noelv.XLEN;
use gaisler.noelv.GEILEN;
use gaisler.noelv.CAUSELEN;
use gaisler.utilnv.to_bit;
use gaisler.utilnv.cond;
use gaisler.utilnv.get;
use gaisler.utilnv.get_hi;
use gaisler.utilnv.get_lo;
use gaisler.utilnv.b2i;
use gaisler.utilnv.u2i;
use gaisler.utilnv.s2vec;
use gaisler.utilnv.u2slv;
use gaisler.utilnv.u2vec;
use gaisler.utilnv.uext;
use gaisler.utilnv.sext;
use gaisler.utilnv.uadd;
use gaisler.utilnv.single_1;
use gaisler.utilnv.all_0;
use gaisler.utilnv.all_1;
use gaisler.utilnv.single_1;
use gaisler.utilnv.minimum;
use gaisler.utilnv.fit0ext;
use gaisler.utilnv.hi_h;
use gaisler.noelvint.nv_csr_in_type;
use gaisler.noelvint.trace_type;
use gaisler.noelvint.trace_rst;
use gaisler.noelvint.pmpcfg_vec_type;
use gaisler.noelvint.pmpaddr_vec_type;
use gaisler.noelvint.pmp_precalc_type;
use gaisler.noelvint.pmp_precalc_none;
use gaisler.noelvint.pmp_precalc_vec;
use gaisler.noelvint.atp_type;
use gaisler.noelvint.atp_none;
use gaisler.noelvint.csr_out_cctrl_type;
use gaisler.noelvint.csr_out_cctrl_rst;
use gaisler.noelvint.nv_bht_in_type;
use gaisler.noelvint.nv_btb_in_type;
use gaisler.noelvint.nv_ras_in_type;
use gaisler.noelvint.nv_ras_in_none;
use gaisler.noelvint.nv_ras_out_type;
use gaisler.noelvint.nv_ras_out_none;
--use gaisler.noelvint.reg_t;

package nvsupport is

  constant FUSELBITS   : integer := 14;
  subtype  fuseltype  is std_logic_vector(FUSELBITS - 1 downto 0);

  subtype  hold_category_t is std_logic_vector(8 downto 0);
  subtype  raw_category_t is std_logic_vector(5 downto 0);
  subtype  waw_category_t is std_logic_vector(0 downto 0);

  type cfi_t is record
    lp : boolean;
    ss : boolean;
  end record;
  constant cfi_both : cfi_t := (true, true);

  function extension(item : x_type) return extension_type;
  function extension(item : x_type; valid : boolean) return extension_type;
  function enable(active : extension_type; item : x_type) return extension_type;
  function disable(active : extension_type; item : x_type) return extension_type;
  function disable(active : extension_type; item1, item2 : x_type) return extension_type;
  function is_enabled(active : extension_type; item : x_type) return boolean;
  function is_enabled(active : extension_type; item : x_type) return integer;

  function rd_gen(active : extension_type;
                  cfi_en : cfi_t;
                  inst   : word) return std_ulogic;
  function rs1_gen(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return reg_t;
  function rs2_gen(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return reg_t;
  -- Some simulation code requires this.
  -- Under simulation, matching all possible instructions does not hurt.
  function rd_gen(inst : word) return std_ulogic;

  function is_lpad(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return boolean;
  function is_ssamoswap(active : extension_type;
                        cfi_en : cfi_t;
                        inst   : word) return boolean;
  function is_sspush(active : extension_type;
                     cfi_en : cfi_t;
                     inst   : word) return boolean;
  function is_sspopchk(active : extension_type;
                       cfi_en : cfi_t;
                       inst   : word) return boolean;
  function is_ssrdp(active : extension_type;
                    cfi_en : cfi_t;
                    inst   : word) return boolean;

  function pc2xlen(pc_in : std_logic_vector) return wordx;
  function to_addr(addr_in : std_logic_vector;
                   length  : integer) return std_logic_vector;
  function npc_adder(pc   : std_logic_vector;
                     comp : std_ulogic) return std_logic_vector;

  function to_reg(num : reg_t) return string;

  type iword_type is record
    lpc : word2;
    d   : word;
    dc  : word16;
    xc  : word3;
    c   : std_ulogic;
  end record;

  constant iword_none : iword_type := ("00", zerow, zerow16, "000", '0');

  type    iword_tuple_type is array (integer range <>) of iword_type;
  subtype iword_pair_type  is iword_tuple_type(0 to 1);

  -- Prediction -----------------------------------------------------------------
  type prediction_type is record
    taken       : std_ulogic;                          -- branch predicted to be taken
    hit         : std_ulogic;                          -- branch has been found in BTB
  end record;

  constant prediction_none : prediction_type := (
    taken       => '0',
    hit         => '0'
    );

  type prediction_array_type is array (0 to 3) of prediction_type;

  -- Instruction Queue ------------------------------------------------------
  -- The instruction queue is a single-entry instruction buffer located in the
  -- decode stage.
  type iqueue_type is record
    pc              : wordx;            -- program counter
    inst            : iword_type;       -- instruction
    cinst           : word16;           -- compressed instruction
    valid           : std_ulogic;       -- instruction buffer entry is valid
    comp            : std_ulogic;  -- instruction buffer entry is compressed
    xc              : std_ulogic;  -- instruction buffer entry has generated a trap in previous stages
    bjump           : std_ulogic;       -- 1-> branch or jump inst
    bjump_predicted : std_ulogic;       -- 1-> bjump already predicted before buffering
    prediction      : prediction_type;  -- prediction as from the BHT
    comp_ill        : std_ulogic; --compressed instruction is invalid
  end record;

  constant iqueue_none : iqueue_type := (
    pc              => zerox,
    inst            => ("00", zerow, (others => '0'), "000", '0'),
    cinst           => zerow16,
    valid           => '0',
    comp            => '0',
    xc              => '0',
    --xc_msb          => '0',
    bjump           => '0',
    bjump_predicted => '0',
    prediction      => prediction_none,
    comp_ill        => '0'
    );

  type lane_select is record
    fpu    : integer range 0 to 1;
    csr    : integer range 0 to 1;
    branch : integer range 0 to 1;
    memory : integer range 0 to 1;
  end record;

  type csr_hstatus_type is record
    vsxl        : word2;
    vtsr        : std_ulogic;
    vtw         : std_ulogic;
    vtvm        : std_ulogic;
    vgein       : std_logic_vector(5 downto 0);
    hu          : std_ulogic;
    spvp        : std_ulogic;
    spv         : std_ulogic;
    gva         : std_ulogic;
    vsbe        : std_ulogic;
  end record;

  constant csr_hstatus_rst : csr_hstatus_type := (
    vsxl        => "10",
    vtsr        => '0',
    vtw         => '0',
    vtvm        => '0',
    vgein       => "000000",
    hu          => '0',
    spvp        => '0',
    spv         => '0',
    gva         => '0',
    vsbe        => '0'
    );

  subtype csr_tdata_vector is wordx_arr(0 to MAX_TRIGGER_NUM - 1);
  subtype csr_tinfo_vector is word16_arr(0 to MAX_TRIGGER_NUM - 1);
  subtype csr_mhcontext_type is std_logic_vector(13 downto 0);
  subtype csr_scontext_type is std_logic_vector(33 downto 0);
  type csr_tcsr_type is record
    tselect     : std_logic_vector(log2(MAX_TRIGGER_NUM) - 1 downto 0);
    tdata1      : csr_tdata_vector;
    tdata2      : csr_tdata_vector;
    tdata3      : csr_tdata_vector;
    tinfo       : csr_tinfo_vector;
    tcontrol    : word8;
    mhcontext   : csr_mhcontext_type;
    scontext    : csr_scontext_type;
  end record;

  constant csr_tcsr_rst : csr_tcsr_type := (
    tselect     => (others => '0'),
    tdata1      => (others => (others => '0')),
    tdata2      => (others => (others => '0')),
    tdata3      => (others => (others => '0')),
    tinfo       => (others => (others => '0')),
    tcontrol    => (others => '0'),
    mhcontext   => (others => '0'),
    scontext    => (others => '0')

    );

  type csr_dcsr_type is record
    xdebugver   : word4;
    extcause    : word3;
    cetrig      : std_ulogic;
    pelp        : std_ulogic;
    ebreakm     : std_ulogic;
    ebreaks     : std_ulogic;
    ebreaku     : std_ulogic;
    ebreakvs    : std_ulogic;
    ebreakvu    : std_ulogic;
    stepie      : std_ulogic;
    stopcount   : std_ulogic;
    stoptime    : std_ulogic;
    cause       : word3;
    mprven      : std_ulogic;
    nmip        : std_ulogic;
    step        : std_ulogic;
    prv         : word2;
    v           : std_ulogic;
  end record;

  constant csr_dcsr_rst : csr_dcsr_type := (
    xdebugver   => "0100",
    extcause    => "000",
    cetrig      => '0',
    pelp        => '0',
    ebreakm     => '0',
    ebreaks     => '0',
    ebreaku     => '0',
    ebreakvs    => '0',
    ebreakvu    => '0',
    stepie      => '0',
    stopcount   => '0',
    stoptime    => '0',
    cause       => "000",
    mprven      => '0',
    nmip        => '0',
    step        => '0',
    prv         => "11",
    v           => '0'
    );

  type csr_dfeaturesen_type is record
    tpbuf_en     : std_ulogic;   -- Include program buffer execution in trace/sim-disas
    nostream     : std_ulogic;   -- Do not make use of stream buffer for instruction fetch
    h_ade        : std_ulogic;   -- Take exception on hPT access/modify (disregarding menvcfg.adue).
    mmu_sptfault : std_ulogic;   -- Take page fault on any sPT walk.
    mmu_hptfault : std_ulogic;   -- Take page fault on any hPT walk.
    mmu_oldfence : std_ulogic;   -- Use old sfence/hfence implementation.
    diag_s       : std_ulogic;   -- Allow diagnostic instructions in S/U mode
    x0           : std_ulogic;   -- Force MISA X to 0 - no more NOEL-V extensions.
                                 -- (Also means that this CSR can no longer be accessed.)
    -- Dual Issue Capabilities
    dual_dis     : std_ulogic;
    -- Branch Prediction
    btb_dis      : std_ulogic;
    jprd_dis     : std_ulogic;
    staticbp     : std_ulogic;
    staticdir    : std_ulogic;
    -- Return Address Stack
    ras_dis      : std_ulogic;
    -- Performance Features
    lbranch_dis  : std_ulogic;
    lalu_dis     : std_ulogic;
    b2bst_dis    : std_ulogic;
    fs_dirty     : std_ulogic;   -- Always mark FPU state as dirty, if FPU is enabled.
    dm_trace     : std_ulogic;   -- Force DM only access to trace buffer.
    -- HPM Counters dependencies
    hpmc_mode    : std_ulogic;   -- 0: Better performance; 1: Better accuracy
    pma_fault_46    : std_ulogic; -- PMA Fault between 4 -> 6 GB
    pma_fault_02    : std_ulogic; -- PMA Fault between 0 -> 2 GB
  end record;

  constant csr_dfeaturesen_rst : csr_dfeaturesen_type := (
    tpbuf_en     => '0',
    nostream     => '0',
    h_ade        => '0',
    mmu_sptfault => '0',
    mmu_hptfault => '0',
    mmu_oldfence => '0',
    diag_s       => '0',
    x0           => '0',
    dual_dis     => '0',
    btb_dis      => '0',
    jprd_dis     => '0',
    staticbp     => '0',
    staticdir    => '0',
    ras_dis      => '0',
    lbranch_dis  => '0',
    lalu_dis     => '0',
    b2bst_dis    => '0',
    fs_dirty     => '0',
    dm_trace     => '0',
    hpmc_mode    => '0',
    pma_fault_46 => '0',
    pma_fault_02 => '0'
    );


  constant HWPERFMONITORS    : integer := 29;

  -- Set of counters with advanced event filtering (AND of multiple events)
  constant MHPCOUNT_FIL      : std_logic_vector(HWPERFMONITORS + 3 - 1 downto 0) := (others => '1');
  -- Set number of events Classes
  constant MHPEVENT_C        : integer := 16;
  -- Set maximum number of Events in each Class
  constant MHPEVENT_EC       : integer := 32;
  -- Set the purpose of each event class
  constant PIPELINE_EV_0     : integer := 0;
  constant CACHETLB_EV_0     : integer := 1;
  constant FPU_EV_0          : integer := 2;
  constant DBG_EV            : integer := MHPEVENT_C - 1;
  subtype events_type is std_logic_vector(MHPEVENT_EC - 1 downto 0);
  -- 0-2 of hpmcounter_type and hpmevent_vec are not used!
  subtype hpmcounter_type is word64_arr(0 to HWPERFMONITORS + 3 - 1);
  type hpmevent_type is record
    overflow : std_ulogic;
    minh     : std_ulogic;
    sinh     : std_ulogic;
    uinh     : std_ulogic;
    vsinh    : std_ulogic;
    vuinh    : std_ulogic;
    class    : std_logic_vector(log2(MHPEVENT_C) - 1 downto 0);  -- Class  Event selector
    events   : events_type;                                      -- Class  Event selector
  end record ;

  constant hpmevent_none : hpmevent_type := ('0', '0', '0', '0', '0', '0', (others => '0'), (others => '0'));

  type hpmevent_vec is array (0 to HWPERFMONITORS + 3 - 1) of hpmevent_type;
  -- Define event array type
  type evt_type is array (MHPEVENT_C - 1 downto 0) of events_type;
  constant evt_none_type : evt_type := ((others => (others => '0')));
  function filter_hpmevent(hpmevent : hpmevent_type; evt : evt_type; cnt : integer) return std_logic;

  -- CSR Type -----------------------------------------------------------------
  type csr_status_type is record
    mdt         : std_ulogic; -- Added by Smdbltrp extension
    mbe         : std_ulogic;
    sbe         : std_ulogic;
    sxl         : word2;
    uxl         : word2;
    sdt         : std_ulogic; -- Added by Ssdbltrp extension
    tsr         : std_ulogic;
    tw          : std_ulogic;
    tvm         : std_ulogic;
    mxr         : std_ulogic;
    sum         : std_ulogic;
    mprv        : std_ulogic;
    xs          : word2;
    fs          : word2;
    mpp         : word2;
    spp         : std_ulogic;
    mpie        : std_ulogic;
    ube         : std_ulogic;
    spie        : std_ulogic;
    upie        : std_ulogic;
    mie         : std_ulogic;
    sie         : std_ulogic;
    uie         : std_ulogic;
    -- Added by Hypervisor extension
    mpv         : std_ulogic;
    gva         : std_ulogic;
    -- Zicfiss / Zicfilp
    mpelp       : std_ulogic;
    spelp       : std_ulogic;
  end record;

  constant csr_status_rst : csr_status_type := (
    mdt         => '1',
    mbe         => '0',
    sbe         => '0',
    sxl         => "10",
    uxl         => "10",
    sdt         => '0',
    tsr         => '0',
    tw          => '0',
    tvm         => '0',
    mxr         => '0',
    sum         => '0',
    mprv        => '0',
    xs          => "00",
    fs          => "00",
    mpp         => "00",
    spp         => '0',
    mpie        => '0',
    ube         => '0',
    spie        => '0',
    upie        => '0',
    mie         => '0',
    sie         => '0',
    uie         => '0',
    mpv         => '0',
    gva         => '0',
    mpelp       => '0',
    spelp       => '0'
    );


  type csr_mnstatus_type is record
    mnpp   : std_logic_vector(1 downto 0);
    mnpv   : std_ulogic;
    nmie   : std_ulogic;
    mnpelp : std_ulogic;  -- Zicfiss / Zicfilp
  end record;
  constant csr_mnstatus_rst : csr_mnstatus_type := (
    mnpp   => "00",
    mnpv   => '0',
    nmie   => '0',
    mnpelp => '0'
  );

  type csr_mstateen0_type is record
    -- High 32 bits
    stateen  : std_ulogic;  -- 63
    envcfg   : std_ulogic;  -- 62
    iselect  : std_ulogic;  -- 60
    aia      : std_ulogic;  -- 59
    imsic    : std_ulogic;  -- 58
    ctx      : std_ulogic;  -- 57
    p1p13    : std_ulogic;  -- 56
    p1p14    : std_ulogic;  -- 55
    ctr      : std_ulogic;  -- 54
    -- Low 32 bits
    jvt      : std_ulogic;  -- 2
    fcsr     : std_ulogic;  -- 1
    c        : std_ulogic;  -- 0
  end record;
  constant csr_mstateen0_rst : csr_mstateen0_type := (
    stateen  => '0',
    envcfg   => '0',
    iselect  => '0',
    aia      => '0',
    imsic    => '0',
    ctx      => '0',
    p1p13    => '0',
    p1p14    => '0',
    ctr      => '0',
    jvt      => '0',
    fcsr     => '0',
    c        => '0'
  );

  type csr_hstateen0_type is record
    -- High 32 bits
    stateen  : std_ulogic;  -- 63
    envcfg   : std_ulogic;  -- 62
    iselect  : std_ulogic;  -- 60
    aia      : std_ulogic;  -- 59
    imsic    : std_ulogic;  -- 58
    ctx      : std_ulogic;  -- 57
    ctr      : std_ulogic;  -- 54
    -- Low 32 bits
    jvt      : std_ulogic;  -- 2
    fcsr     : std_ulogic;  -- 1
    c        : std_ulogic;  -- 0
  end record;

  constant csr_hstateen0_rst : csr_hstateen0_type := (
    stateen  => '0',
    envcfg   => '0',
    iselect  => '0',
    aia      => '0',
    imsic    => '0',
    ctx      => '0',
    ctr      => '0',
    jvt      => '0',
    fcsr     => '0',
    c        => '0'
  );
  -- Type for mstateen/hstateen CSRs whose only writable bit is 63
  type csr_mstateen_void_type is record
    stateen  : std_ulogic;
  end record;
  constant csr_mstateen_void_rst : csr_mstateen_void_type := (
    stateen  => '0'
  );

  -- Unused: stateen0 has no writable bit in the NOEL-V so far
  type csr_sstateen0_type is record
    jvt      : std_ulogic;  -- 2
    fcsr     : std_ulogic;  -- 1
    c        : std_ulogic;  -- 0
  end record;

  constant csr_sstateen0_rst : csr_sstateen0_type := (
    jvt      => '0',
    fcsr     => '0',
    c        => '0'
  );

  type stateen_bits is record
    m : std_logic;
    s : std_logic;
    h : std_logic;
  end record;

  constant stateen_bits_rst : stateen_bits := (
    m => '0',
    s => '0',
    h => '0'
  );

  type csr_envcfg_type is record
    stce  : std_ulogic;
    pbmte : std_ulogic;
    dte   : std_ulogic;
    cbze  : std_ulogic;
    cbcfe : std_ulogic;
    cbie  : word2;
    fiom  : std_ulogic;
    adue  : std_logic;
    sse   : std_ulogic;
    lpe   : std_ulogic;
    cde   : std_ulogic;
  end record;
  constant csr_envcfg_rst : csr_envcfg_type := (
    stce  => '0',
    pbmte => '0',
    dte   => '0',
    cbze  => '0',
    cbcfe => '0',
    cbie  => (others => '0'),
    fiom  => '0',
    adue  => '0',
    sse   => '0',
    lpe   => '0',
    cde   => '0'
    );

  subtype csr_menvcfg_const_type is csr_envcfg_type;
  subtype csr_henvcfg_const_type is csr_envcfg_type;
  subtype csr_senvcfg_const_type is csr_envcfg_type;
  subtype csr_menvcfg_type is csr_envcfg_type;
  subtype csr_henvcfg_type is csr_envcfg_type;
  subtype csr_senvcfg_type is csr_envcfg_type;

  type csr_seccfg_type is record
    mml    : std_ulogic;
    mmwp   : std_ulogic;
    rlb    : std_ulogic;  -- Allow PMP lock bits to be cleared.
    mlpe   : std_ulogic;
  end record;
  constant csr_seccfg_rst : csr_seccfg_type := (
    mml    => '0',
    mmwp   => '0',
    rlb    => '0',
    mlpe   => '0'
  );


  type csr_hvictl_type is record
    vti    : std_ulogic;
    iid    : int_cause_type;
    dpr    : std_ulogic;
    ipriom : std_ulogic;
    iprio  : std_logic_vector(7 downto 0);
  end record;
  constant csr_hvictl_rst : csr_hvictl_type := (
    vti    => '0',
    iid    =>  0,
    dpr    => '0',
    ipriom => '0',
    iprio  => (others => '0'));

  -- (V)S/MISELECT are required to hold at least 12 low bits.
  -- The top bit (XLEN - 1) signifies custom registers.
  -- For now, assume the minimum is enough.
  type select_t is record
    custom : std_ulogic;
    sel    : std_logic_vector(11 downto 0);
  end record;
  constant select_none : select_t := ('0', (others => '0'));

 type csr_reg_type is record
    -- Machine ISA (needs to be configured before use!)
    misa        : wordx;
    -- Privilege Level (not addressable as a CSR register)
    prv         : priv_lvl_type;
    -- Virtualization mode
    v           : std_ulogic;
    -- FPU enabled (pre-calculated)
    fpu_enabled : boolean;
    -- Envcfg (pre-calculated)
    envcfg      : csr_menvcfg_type;
    -- CFI state (pre-calculated)
    cfi_en      : cfi_t;
    -- Expecting landing pad
    elp         : std_ulogic;
    -- User Floating-Point CSRs
    fctrl       : std_logic_vector(16 downto 8);
    frm         : std_logic_vector(7 downto 5);
    fflags      : word5;
    -- Hypervisor
    hstatus     : csr_hstatus_type;
    hedeleg     : wordx;
    hideleg     : wordx;
    hvip        : wordx;
    -- When hvien[i]='1' vsie[i] is a independent writable bit (vsie[i])
    vsie       : wordx;
    hip         : wordx;
    hie         : wordx;
    hgeip       : wordx;
    hgeie       : wordx;
    hcounteren  : word;
    htimedelta  : word64;
    htval       : wordx;
    htinst      : wordx;
    hgatp       : atp_type;
    henvcfg     : csr_henvcfg_type;
    -- Hypervisor Smstateen
    hstateen0   : csr_hstateen0_type;
    hstateen1   : csr_mstateen_void_type;
    hstateen2   : csr_mstateen_void_type;
    hstateen3   : csr_mstateen_void_type;
    -- Virtual Supervisor
    vsstatus    : csr_status_type;
    vstvec      : wordx;
    vsscratch   : wordx;
    vsepc       : wordx;
    vscause     : cause_type;
    vstval      : wordx;
    vstimecmp   : word64;
    vsatp       : atp_type;
    -- VS Indirect CSR Access (Sscsrind)
    vsiselect   : select_t;
    vsireg      : wordx;
    -- VS AIA (Smaia and Ssaia)
    hvien       : wordx;
    hvictl      : csr_hvictl_type;
    hviprio1    : wordx;
    hviprio2    : wordx;
    vstopei     : wordx;
    vstopi      : wordx;
    -- Supervisor Trap Setup
    stvec       : wordx;
    scounteren  : word;
    senvcfg     : csr_senvcfg_type;
    -- Supervisor Trap Handling
    sscratch    : wordx;
    sepc        : wordx;
    scause      : cause_type;
    stval       : wordx;
    stimecmp    : word64;
    -- VS Indirect CSR Access (Sscsrind)
    siselect    : select_t;
    sireg       : wordx;
    -- Supervisor AIA (Smaia or Ssaia)
    stopei      : wordx;
    stopi       : wordx;
    -- Supervisor Ssstateen
    sstateen0   : csr_sstateen0_type;
    -- Fills no purpose right now
    -- sstateen1   : csr_sstateen_void_type;
    -- sstateen2   : csr_sstateen_void_type;
    -- sstateen3   : csr_sstateen_void_type;
    -- Supervisor Protection and Translation
    satp        : atp_type;
    -- Machine Trap Setup
    mstatus     : csr_status_type;
    medeleg     : wordx;
    mideleg     : wordx;
    mie         : wordx;
    mtvec       : wordx;
    mcounteren  : word;
    -- Machine Trap Handling
    mscratch    : wordx;
    mepc        : wordx;
    mcause      : cause_type;
    mtval       : wordx;
    mip         : wordx;
    -- RNMI Trap Handling
    mnscratch   : wordx;
    mnepc       : wordx;
    mncause     : cause_type;
    mnstatus    : csr_mnstatus_type;
    -- Machine Smstateen
    mstateen0   : csr_mstateen0_type;
    mstateen1   : csr_mstateen_void_type;
    mstateen2   : csr_mstateen_void_type;
    mstateen3   : csr_mstateen_void_type;
    -- Machine Indirect CSR Access (Smcsrind)
    miselect    : select_t;
    mireg       : wordx;
    -- Machine AIA (Smaia)
    mtopei      : wordx;
    mtopi       : wordx;
    mvien       : wordx;
    mvip        : wordx;
    -- When mvien[i]='1' sie[i] is a independent writable bit (sie[i])
    sie       : wordx;
    -- Machine Trap Handling added by Hypervisor extension
    mtval2      : wordx;
    mtinst      : wordx;
    -- Machine Configuration
    menvcfg     : csr_menvcfg_type;
    mseccfg     : csr_seccfg_type;
    -- Machine Protection and Translation
    pmpcfg      : pmpcfg_vec_type;
    pmpaddr     : pmpaddr_vec_type;
    pmp_precalc : pmp_precalc_vec(0 to PMPENTRIES - 1);
    pma_addr    : word64_arr(0 to PMAENTRIES - 1);
    pma_data    : word64_arr(0 to PMAENTRIES - 1);
    pma_precalc : pmp_precalc_vec(0 to PMPENTRIES - 1);
    -- Machine Counter/Timers
    mcycle      : word64;
    mtime       : word64;
    minstret    : word64;
    -- Debug/Trace Registers
    tcsr        : csr_tcsr_type;
    -- Core Debug Registers
    dcsr        : csr_dcsr_type;
    dpc         : wordx;
    dscratch0   : wordx;
    dscratch1   : wordx;
    -- Hardware Performance Monitors
    hpmcounter  : hpmcounter_type;
    hpmevent    : hpmevent_vec;
    mcountinhibit : word;
    -- Custom Read/Write Unprivileged Registers
    trace       : trace_type;
    -- Custom Read/Write Registers
    dfeaturesen : csr_dfeaturesen_type;
    cctrl       : csr_out_cctrl_type;
    ssp         : wordx;
  end record;

  constant CSRRES : csr_reg_type := (
    misa        => zerox,
    prv         => PRIV_LVL_M,
    v           => '0',
    fpu_enabled => false,
    envcfg      => csr_envcfg_rst,
    cfi_en      => (false, false),
    elp         => '0',
    fctrl       => (others => '0'),
    frm         => (others => '0'),
    fflags      => (others => '0'),
    hstatus     => csr_hstatus_rst,
    hedeleg     => zerox,
    hideleg     => zerox,
    hvip        => zerox,
    vsie       => zerox,
    hip         => zerox,
    hie         => zerox,
    hgeip       => zerox,
    hgeie       => zerox,
    hcounteren  => zerow,
    htimedelta  => zerow64,
    htval       => zerox,
    htinst      => zerox,
    hgatp       => atp_none,
    henvcfg     => csr_envcfg_rst,
    hstateen0   => csr_hstateen0_rst,
    hstateen1   => csr_mstateen_void_rst,
    hstateen2   => csr_mstateen_void_rst,
    hstateen3   => csr_mstateen_void_rst,
    vsstatus    => csr_status_rst,
    vstvec      => zerox,
    vsscratch   => zerox,
    vsepc       => zerox,
    vscause     => cause_res,
    vstval      => zerox,
    vstimecmp   => zerow64,
    vsatp       => atp_none,
    vsiselect   => select_none,
    vsireg      => zerox,
    hvien       => zerox,
    hvictl      => csr_hvictl_rst,
    hviprio1    => zerox,
    hviprio2    => zerox,
    vstopei     => zerox,
    vstopi      => zerox,
    stvec       => zerox,
    scounteren  => zerow,
    senvcfg     => csr_envcfg_rst,
    sscratch    => zerox,
    sepc        => zerox,
    scause      => cause_res,
    stval       => zerox,
    stimecmp    => zerow64,
    siselect    => select_none,
    sireg       => zerox,
    stopei      => zerox,
    stopi       => zerox,
    sstateen0   => csr_sstateen0_rst,
    satp        => atp_none,
    mstatus     => csr_status_rst,
    medeleg     => zerox,
    mideleg     => zerox,
    mie         => zerox,
    mtvec       => zerox,
    mcounteren  => zerow,
    mscratch    => zerox,
    mepc        => zerox,
    mcause      => cause_res,
    mtval       => zerox,
    mip         => zerox,
    mnscratch   => zerox,
    mnepc       => zerox,
    mncause     => cause_res,
    mnstatus    => csr_mnstatus_rst,
    mstateen0   => csr_mstateen0_rst,
    mstateen1   => csr_mstateen_void_rst,
    mstateen2   => csr_mstateen_void_rst,
    mstateen3   => csr_mstateen_void_rst,
    miselect    => select_none,
    mireg       => zerox,
    mtopei      => zerox,
    mtopi       => zerox,
    mvien       => zerox,
    mvip        => zerox,
    sie       => zerox,
    mtval2      => zerox,
    mtinst      => zerox,
    menvcfg     => csr_envcfg_rst,
    mseccfg     => csr_seccfg_rst,
    pmpcfg      => (others => (others => '0')),
    pmpaddr     => (others => pmpaddrzero),
    pmp_precalc => (others => pmp_precalc_none),
    pma_addr    => (others => (others => '0')),
    pma_data    => (others => (others => '0')),
    pma_precalc => (others => pmp_precalc_none),
    mcycle      => zerow64,
    mtime       => zerow64,
    minstret    => zerow64,
    tcsr        => csr_tcsr_rst,
    dcsr        => csr_dcsr_rst,
    dpc         => zerox,
    dscratch0   => zerox,
    dscratch1   => zerox,
    hpmcounter  => (others => zerow64),
    hpmevent    => (others => hpmevent_none),
    mcountinhibit => zerow,
    cctrl       => csr_out_cctrl_rst,
    trace       => trace_rst,
    dfeaturesen => csr_dfeaturesen_rst,
    ssp         => zerox
    );

  -- A set bit marks that the corresponding extention etc can be disabled.
  -- Note that each such bit added will need code changes to actually be useful.
  -- Current things that can be disabled:
  constant c_ctrl      : integer := 2;   -- Compressed instructions extension (C)
  constant h_ctrl      : integer := 7;   -- Hypervisor extension (H)
  constant x_ctrl      : integer := 23;  -- Non-standard extensions (X)
  constant ISA_CONTROL : wordx   := (
    h_ctrl => '1',
    x_ctrl => '1',
    others => '0'
  );

  -- xENVCFG bits
  constant envcfg_sstc : integer := 63;

  -- Load types
  constant SZBYTE       : word2 := "00";
  constant SZHALF       : word2 := "01";
  constant SZWORD       : word2 := "10";
  constant SZDBL        : word2 := "11";

  -- Functional Units Encoding: one-hot encoding for easier decode.
  constant NONE         : fuseltype;
  constant ALU          : fuseltype;  -- ALU
  constant BRANCH       : fuseltype;  -- Branch Unit
  constant JAL          : fuseltype;  -- JAL
  constant JALR         : fuseltype;  -- JALR
  constant FLOW         : fuseltype;  -- Jump (JAL/JALR)
  constant MUL          : fuseltype;  -- Mul/Div
  constant LD           : fuseltype;  -- Load
  constant ST           : fuseltype;  -- Store
  constant AMO          : fuseltype;  -- Atomics
  constant FPU          : fuseltype;  -- From FPU
  constant ALU_SPECIAL  : fuseltype;  -- Only for early ALU in lane 0!
  constant DIAG         : fuseltype;  -- Diagnostic cache load/store
  constant CFI          : fuseltype;  -- CFI
  constant NOT_LATE     : fuseltype;  -- All except ALU and Branch Unit


  -- CSR Operation
  constant CSR_BYPASS   : word2 := "00";
  constant CSR_CLEAR    : word2 := "10";
  constant CSR_SET      : word2 := "11";

  -- Core State ---------------------------------------------------------------
  type core_state is (run, dhalt, dexec);

  function to64(v : std_logic_vector) return word64;
  function to0x(v : std_logic_vector) return wordx;
  function to0x(v : unsigned) return wordx;

  procedure rvc_aligner(active           : in  extension_type;
                        inst_in          : in  iword_tuple_type;
                        rvc_pc           : in  std_logic_vector;
                        valid_in         : in  std_ulogic;
                        fpu_en           : in  boolean;
                        inst_out         : out iword_tuple_type;
                        comp_ill         : out word2;
                        hold_out         : out std_ulogic;
                        npc_out          : out word3;
                        valid_out        : out std_logic_vector;
                        buffer_first_out : out std_logic;  -- buffer first instruction
                        buffer_sec_out   : out std_logic;  -- buffer second instruction
                                                           --  if not issued
                        buffer_third_out : out std_logic;  -- buffer the third instruction
                        buffer_inst      : out iword_type;
                        buff_comp_ill    : out std_logic;
                        unaligned_out    : out std_ulogic);

  procedure no_rvc_aligner(active        : in  extension_type;
                        inst_in          : in  iword_tuple_type;
                        rvc_pc           : in  std_logic_vector;
                        valid_in         : in  std_ulogic;
                        inst_out         : out iword_tuple_type;
                        comp_ill         : out word2;
                        hold_out         : out std_ulogic;
                        npc_out          : out word3;
                        valid_out        : out std_logic_vector;
                        buffer_first_out : out std_logic;  -- buffer first instruction
                        buffer_sec_out   : out std_logic;  -- buffer second instruction
                                                           --  if not issued
                        buffer_third_out : out std_logic;  -- buffer the third instruction
                        buffer_inst      : out iword_type;
                        buff_comp_ill    : out std_logic;
                        unaligned_out    : out std_ulogic);

  procedure rvc_expander(active   : in  extension_type;
                         inst_in  : in  word16;
                         fpu_en   : in  boolean;
                         inst_out : out word;
                         xc_out   : out std_ulogic);

  procedure bjump_gen(active        : in  extension_type;
                      inst_in       : in  iword_tuple_type;
                      buffer_in     : in  iqueue_type;
                      bjump_pre     : in  std_logic_vector;
                      jump_pre      : in  std_logic_vector;
                      prediction    : in  prediction_array_type;
                      dvalid        : in  std_ulogic;
                      dpc_in        : in  std_logic_vector;
                      bjump_buf_out : out std_ulogic;  --bjump is from the buffer
                      bjump_out     : out std_ulogic;  --bjump is taken
                      btb_taken     : out std_ulogic;  --btb was taken
                      btb_taken_buf : out std_ulogic;  --btb was taken for buffer
                      bjump_pos     : out word4;
                      bjump_addr    : out std_logic_vector);   --bjump addr

  procedure bjump_pregen(inst_word : in  word64;
                         buffer_in : in  iqueue_type;
                         bjump_out : out std_logic_vector;
                         jump_out  : out std_logic_vector);

  procedure buffer_ic(active         : in  extension_type;
                      r_d_buff_valid : in  std_ulogic;
                      valid_in       : in  std_logic_vector;
                      dvalid_in      : in  std_logic_vector;
                      buffer_third   : in  std_ulogic;
                      buffer_sec     : in  std_ulogic;
                      buffer_first   : in  std_ulogic;
                      unaligned      : in  std_ulogic;
                      issue_in       : in  std_logic_vector;
                      hold_pc        : out std_ulogic;
                      buff_valid     : out std_ulogic);

  procedure imm_gen(active    : in  extension_type;
                    inst_in   : in  word;
                    valid_out : out std_ulogic;
                    imm_out   : out wordx;
                    bj_imm    : out wordx);

  function csr_raw_category(addr : csratype) return raw_category_t;
  function csr_waw_category(addr : csratype) return waw_category_t;
  function csr_hold_category(addr : csratype; hpmc_mode : std_ulogic) return hold_category_t;

  function hpmc_ind_hold_check(virt   : std_ulogic;
                               csr    : csr_reg_type;
                               hpmc_dep_cfg : std_ulogic) return boolean;

  procedure exception_check(active    : in  extension_type;
                            menvcfg   : in  csr_menvcfg_type;
                            henvcfg   : in  csr_henvcfg_type;
                            senvcfg   : in  csr_senvcfg_type;
                            fpu_en    : in  boolean;
                            fpu_ok    : in  boolean;
                            alu_ok    : in  boolean;
                            tval_ill0 : in  boolean;
                            diag_s    : in  boolean;
                            inst_in   : in  word;
                            cinst_in  : in  word16;
                            comp      : in  std_ulogic;
                            pc_in     : in  std_logic_vector;
                            comp_ill  : in  std_ulogic;
                            misa_in   : in  wordx;
                            prv_in    : in  priv_lvl_type;
                            v_in      : in  std_ulogic;
                            tsr_in    : in  std_ulogic;
                            tw_in     : in  std_ulogic;
                            tvm_in    : in  std_ulogic;
                            vtsr_in   : in  std_ulogic;
                            vtw_in    : in  std_ulogic;
                            vtvm_in   : in  std_ulogic;
                            hu        : in  std_ulogic;
                            xc_out    : out std_ulogic;
                            cause_out : out cause_type;
                            tval_out  : out wordx);

  function for_lane0(active : extension_type;
                     cfi_en : cfi_t;
                     lane   : lane_select;
                     inst   : word) return boolean;
  function for_lane1(active : extension_type;
                     cfi_en : cfi_t;
                     lane   : lane_select;
                     inst   : word) return boolean;

  procedure dual_issue_check(active      : in  extension_type;
                             cfi_en      : in  cfi_t;
                             lane        : in  lane_select;
                             instx_in    : in  iword_tuple_type;
                             valid_in    : in  std_logic_vector;
                             lbranch_dis : in  std_ulogic;
                             lalu_dis    : in  std_ulogic;
                             dual_dis    : in  std_ulogic;
                             hpmc_mode   : in  std_ulogic;
                             step_in     : in  std_ulogic;
                             lalu_in     : in  std_logic_vector;
                             xc          : in  std_logic_vector;
                             mexc        : in  std_ulogic;
                             rd0_in      : in  reg_t;
                             rdv0_in     : in  std_ulogic;
                             rd1_in      : in  reg_t;
                             rdv1_in     : in  std_ulogic;
                             lane0_out   : out std_ulogic;
                             issue_out   : out std_logic_vector);

  procedure dual_issue_swap(active   : in  extension_type;
                            cfi_en   : in  cfi_t;
                            lane     : in  lane_select;
                            inst_in  : in  iword_tuple_type;
                            valid_in : in  std_logic_vector;
                            swap_out : out std_ulogic);

  function fusel_gen(active : extension_type;
                     inst   : word;
                     cfi_en : cfi_t := cfi_both
                    ) return fuseltype;

  function v_fusel_eq(fusel1 : fuseltype; fusel2 : fuseltype) return boolean;

  function csr_access_addr(inst : word) return csratype;
  function csr_access_read(inst : word) return boolean;
  function csr_access_read_only(inst : word) return boolean;
  function csr_addr(active : extension_type; inst : word) return csratype;
  function require_envcfg(mode_s : boolean;
                          prv    : priv_lvl_type;
                          virt   : boolean;
                          m      : boolean;
                          h      : boolean;
                          s      : boolean )
                          return xc_type;
  function require_envcfg(mode_s : boolean;
                          prv    : priv_lvl_type;
                          virt   : std_logic;
                          m      : std_logic;
                          h      : std_logic;
                          s      : std_logic )
                          return xc_type;
  function is_csr_high_half(csra : csratype) return boolean;
  function csr_read_only(active  : extension_type; inst : word) return boolean;
  function csr_write_only(active : extension_type; inst : word) return boolean;
  function csr_xc_check(csra_in     : csratype;
                        is_write    : boolean;
                        active      : extension_type;
                        csr_file    : csr_reg_type;
                        rstate_in   : core_state;
                        imsic       : boolean;
                        pmp_entries : integer;
                        perf_cnts   : integer;
                        trigger     : integer
                    ) return xc_type;
  function zicfiss_csr_xc(csra        : csratype;
                          csr         : csr_reg_type;
                          ext_zicfiss : boolean;
                          mode_s      : boolean)
                          return xc_type;
  function smcsrind_reg_xc(csr_file   : csr_reg_type;
                           csra       : csratype;
                           active     : extension_type;
                           imsic      : boolean) return xc_type;
  function check_stateen_xc(bits          : stateen_bits;
                            priv          : priv_lvl_type;
                            v_mode        : boolean;
                            ext_smstateen : boolean;
                            mode_s        : boolean) return xc_type;
  function csrind_check_stateen_xc(csra          : csratype;
                                   csr_file      : csr_reg_type;
                                   ext_smstateen : boolean;
                                   mode_s        : boolean) return xc_type;
  procedure csr_write_flush(csra_in       : in  csratype;
                            active        : in  extension_type;
                            pipeflush_out : out std_ulogic;
                            addrflush_out : out std_ulogic);
  function get_stateen_bits(csra : csratype; csr_file : csr_reg_type) return stateen_bits;
  function is_sfence_vma(active : extension_type; inst : word) return boolean;
  function is_hfence_vvma(active : extension_type; inst : word) return boolean;
  function is_hfence_gvma(active : extension_type; inst : word) return boolean;
  function is_tlb_fence(active : extension_type;
                        inst   : word) return boolean;
  function is_hlv(inst : word) return boolean;
  function is_hsv(inst : word) return boolean;
  function is_hlsv(inst : word) return boolean;
  function is_hlvx(inst : word) return boolean;
  function is_fence_i(inst : word) return boolean;
  function is_fence(inst : word) return boolean;
  function is_diag(active : extension_type; inst : word) return boolean;
  function is_diag_store(inst : word) return boolean;
  function is_csr_access(inst : word) return boolean;
  function is_csr(active : extension_type;
                  cfi_en : cfi_t;
                  inst   : word) return boolean;
  function maybe_csr(active : extension_type;
                     cfi_en : cfi_t;
                     inst   : word) return boolean;
  function is_xret(inst : word) return boolean;
  function is_system0(inst : word) return boolean;
  function is_system1(inst : word) return boolean;
  function is_wfi(inst :word) return boolean;
  function is_cbo(inst : word) return boolean;
-- pragma translate_off
  -- Some simulation code requires this.
  -- Under simulation, matching all possible instructions does not hurt.
  function is_csr(inst : word) return boolean;
-- pragma translate_on

  function is_fpu(inst : word) return boolean;
  function is_fpu_mem(inst : word) return boolean;
  function is_fpu_fsd(inst : word) return boolean;
  function is_fpu_from_int(inst : word) return boolean;
  function is_fpu_rd(inst : word) return boolean;
  function is_fpu_modify(inst : word) return boolean;


  function tie_status(active : extension_type;
                      status : csr_status_type;
                      misa   : wordx      := (others => '1')) return csr_status_type;
  procedure tie_csrs(active      : extension_type;
                     pmp_entries : integer range 0 to PMPENTRIES - 1;
                     pma_entries : integer range 0 to PMAENTRIES - 1;
                     pma_masked  : integer range 0 to 1;
                     perf_cnts   : integer range 0 to 29;
                     perf_bits   : integer range 0 to 64;
                     mmuen       : integer range 0 to 1;
                     csr         : inout csr_reg_type);

  function data_addr_misaligned(addr : std_logic_vector;
                                size : word2) return boolean;
  function inst_addr_misaligned(active : extension_type;
                                pc     : std_logic_vector) return boolean;

  function pmpcfg(pmp_entries : integer range pmpcfg_vec_type'range;
                  cfg : pmpcfg_vec_type; n : natural; bit : integer
                  ) return std_logic;
  function pmpcfg(pmp_entries : integer range pmpcfg_vec_type'range;
                  cfg : pmpcfg_vec_type; n : natural;
                  start : integer; bits : integer
                  ) return std_logic_vector;
  function pmpcfg(cfg : pmpcfg_vec_type; first : integer; last : integer) return wordx;

  function pc_valid(
                    active : extension_type;
                    cfi_en : cfi_t;
                    inst : word) return std_ulogic;

  procedure branch_unit(active    : in  extension_type;
                        op1_in    : in  wordx;
                        op2_in    : in  wordx;
                        valid_in  : in  std_ulogic;
                        branch_in : in  std_ulogic;
                        ctrl_in   : in  word3;
                        addr_in   : in  std_logic_vector;
                        npc_in    : in  std_logic_vector;
                        taken_in  : in  std_ulogic;
                        pc_in     : in  std_logic_vector;
                        valid_out : out std_ulogic;
                        mis_out   : out std_ulogic;
                        addr_out  : out std_logic_vector;
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        tval_out  : out wordx);

  function csralu_gen(inst : word) return word2;
  function csralu_op(op1  : wordx;
                     op2  : wordx;
                     ctrl : word2) return wordx;

  procedure addr_gen(active    : in  extension_type;
                     inst_in   : in  word;
                     fusel_in  : in  fuseltype;
                     valid_in  : in  std_ulogic;
                     op1_in    : in  wordx;
                     op2_in    : in  wordx;
                     ssp       : in  wordx;
                     address   : out wordx;
                     xc_out    : out std_ulogic;
                     cause_out : out cause_type;
                     tval_out  : out wordx);
  function ld_align64(data   : word64;
                      size   : word2;
                      laddr  : word3;
                      signed : std_ulogic) return word64;

  function stimecmp_xc(csr_file : csr_reg_type;
                       h_en     : boolean;
                       is_rv64  : boolean;
                       csra     : csratype;
                       v_mode   : boolean) return xc_type;
  function smcdeleg_indirect_xc(csr_file      : csr_reg_type;
                                ext_smcdeleg  : boolean;
                                ext_sscofpmf  : boolean;
                                ext_zicntr    : boolean;
                                ext_zihpm     : boolean;
                                ext_smcntrpmf : boolean;
                                is_rv64       : boolean;
                                csra          : csratype;
                                v_mode        : boolean) return xc_type;
  function ssaia_indirect_xc(csr_file   : csr_reg_type;
                             sel        : select_t;
                             active     : extension_type;
                             imsic      : boolean) return xc_type;
  function  smcdeleg_indirect_read(csr_file  : csr_reg_type; csra : csratype) return wordx;
  procedure smcdeleg_indirect_write(csra         : in csratype;
                                    wcsr_in      : in wordx;
                                    csr_file     : inout csr_reg_type;
                                    upd_mcycle   : inout std_logic;
                                    upd_minstret : inout std_logic;
                                    upd_counter  : inout std_logic_vector);


  -- Exception Codes

  constant XC_INST_ADDR_MISALIGNED      : cause_type;
  constant XC_INST_ACCESS_FAULT         : cause_type;
  constant XC_INST_ILLEGAL_INST         : cause_type;
  constant XC_INST_BREAKPOINT           : cause_type;
  constant XC_INST_LOAD_ADDR_MISALIGNED : cause_type;
  constant XC_INST_LOAD_ACCESS_FAULT    : cause_type;
  constant XC_INST_STORE_ADDR_MISALIGNED: cause_type;
  constant XC_INST_STORE_ACCESS_FAULT   : cause_type;
  constant XC_INST_ENV_CALL_UMODE       : cause_type;
  constant XC_INST_ENV_CALL_SMODE       : cause_type;
  constant XC_INST_ENV_CALL_VSMODE      : cause_type;
  constant XC_INST_ENV_CALL_MMODE       : cause_type;
  constant XC_INST_INST_PAGE_FAULT      : cause_type;
  constant XC_INST_LOAD_PAGE_FAULT      : cause_type;
  constant XC_INST_STORE_PAGE_FAULT     : cause_type;
  constant XC_INST_DOUBLE_TRAP          : cause_type;
  constant XC_INST_SOFTWARE_CHECK       : cause_type;
  constant XC_INST_INST_G_PAGE_FAULT    : cause_type;
  constant XC_INST_LOAD_G_PAGE_FAULT    : cause_type;
  constant XC_INST_VIRTUAL_INST         : cause_type;
  constant XC_INST_STORE_G_PAGE_FAULT   : cause_type;
  constant XC_INST_NV_INST_SPT_FAULT    : cause_type;
  constant XC_INST_NV_LOAD_SPT_FAULT    : cause_type;
  constant XC_INST_NV_STORE_SPT_FAULT   : cause_type;
  constant XC_INST_NV_INST_HPT_FAULT    : cause_type;
  constant XC_INST_NV_LOAD_HPT_FAULT    : cause_type;
  constant XC_INST_NV_STORE_HPT_FAULT   : cause_type;
  constant XC_INST_RFFT                 : cause_type;

  constant cause_none                   : cause_type;

  -- Interrupt Codes
 -- constant IRQ_U_SOFTWARE               : integer;
 -- constant CAUSE_IRQ_U_SOFTWARE          : cause_type;
  constant IRQ_S_SOFTWARE               : integer;
  constant CAUSE_IRQ_S_SOFTWARE         : cause_type;
  constant IRQ_VS_SOFTWARE              : integer;
  constant CAUSE_IRQ_VS_SOFTWARE        : cause_type;
  constant IRQ_M_SOFTWARE               : integer;
  constant CAUSE_IRQ_M_SOFTWARE         : cause_type;
--  constant IRQ_U_TIMER                  : integer;
--  constant CAUSE_IRQ_U_TIMER            : cause_type;
  constant IRQ_S_TIMER                  : integer;
  constant CAUSE_IRQ_S_TIMER            : cause_type;
  constant IRQ_VS_TIMER                 : integer;
  constant CAUSE_IRQ_VS_TIMER           : cause_type;
  constant IRQ_M_TIMER                  : integer;
  constant CAUSE_IRQ_M_TIMER            : cause_type;
--  constant IRQ_U_EXTERNAL               : integer;
--  constant CAUSE_IRQ_U_EXTERNAL         : cause_type;
  constant IRQ_S_EXTERNAL               : integer;
  constant CAUSE_IRQ_S_EXTERNAL         : cause_type;
  constant IRQ_VS_EXTERNAL              : integer;
  constant CAUSE_IRQ_VS_EXTERNAL        : cause_type;
  constant IRQ_M_EXTERNAL               : integer;
  constant CAUSE_IRQ_M_EXTERNAL         : cause_type;
  constant IRQ_SG_EXTERNAL              : integer;
  constant CAUSE_IRQ_SG_EXTERNAL        : cause_type;
  constant IRQ_LCOF                     : integer;
  constant CAUSE_IRQ_LCOF               : cause_type;
  constant IRQ_NMI                      : integer;
  constant CAUSE_IRQ_NMI                : cause_type;
  constant IRQ_RAS_LOW_PRIO             : integer;
  constant CAUSE_IRQ_RAS_LOW_PRIO       : cause_type;
  constant IRQ_RAS_HIGH_PRIO            : integer;
  constant CAUSE_IRQ_RAS_HIGH_PRIO      : cause_type;

  -- Reset Codes
  constant RST_HARD_ALL                 : cause_type;
  constant RST_ASYNC                    : cause_type;

  -- Interrupt code priority
  type     cause_arr     is array (integer range <>) of cause_type;
  type     int_cause_arr is array (integer range <>) of int_cause_type;

  constant cause_prio                   : cause_arr(0 to 34);
  constant cause_prio_m                 : cause_arr(0 to 7);
  constant cause_prio_s                 : cause_arr(0 to 7);
  constant cause_prio_v                 : cause_arr(0 to 7);
  constant int_cause2prio               : int_cause_arr(0 to 63);

  function check_cause_update(new_cause  : cause_type;
                              prev_cause : cause_type;
                              tval       : wordx := zerox) return cause_type;

  -- Indirect CSR Access
  function selector2wordx(v : select_t) return wordx;
  function wordx2selector(v : wordx) return select_t;
  function is_custom(v : select_t) return boolean;
  function is_imsic(v : select_t) return boolean;
  function is_smcdeleg(v : select_t) return boolean;
  function is_aia_iprio(v : select_t) return boolean;
  function is_vsireg(csra : csratype) return boolean;
  function is_sireg(csra : csratype) return boolean;

  -- AIA interrupt files exception calculation
  function intFile_addrExcp(sel : select_t; imsic : integer; is_rv64 : boolean) return std_logic;
  function vgein_legal(vgein : integer) return boolean;

  constant CSR_VENDORID                 : wordx := zerox(zerox'high downto 12) & x"324"; -- Gaisler JEDEC ID (0xA4, bank 7)
  constant CSR_ARCHID                   : wordx := (others => '0');
  constant CSR_IMPID                    : wordx := (others => '0');
  constant RST_VEC                      : wordx;
  constant CSR_MEDELEG_MASK             : wordx;
  constant CSR_MIDELEG_MASK             : wordx;
  constant CSR_MIE_MASK                 : wordx;
  constant CSR_MIP_MASK                 : wordx;
  constant CSR_SIE_MASK                 : wordx;
  constant CSR_SIP_MASK                 : wordx;
  constant CSR_HEDELEG_MASK             : wordx;
  constant CSR_HIDELEG_MASK             : wordx;
  constant CSR_HIE_MASK                 : wordx;
  constant CSR_HIP_MASK                 : wordx;

  constant TINST_LOAD_MASK              : word := "00000000000000000111111111111111";
  constant TINST_H_MASK                 : word := "11111111111100000111111111111111";
  constant TINST_STORE_MASK             : word := "00000001111100000111000001111111";
  constant TINST_AMO_MASK               : word := "11111111111100000111111111111111";

  function tinst_vs_pt_read return word;
  function tinst_vs_pt_write return word;

  -- Hardware Performance Monitors
  -- PIPELINE_EV_0
  constant CSR_HPM_HOLD                 :  integer := 0;
  constant CSR_HPM_HOLD_ISSUE           :  integer := CSR_HPM_HOLD              + 1;
  constant CSR_HPM_SINGLE_ISSUE         :  integer := CSR_HPM_HOLD_ISSUE        + 1;
  constant CSR_HPM_DUAL_ISSUE           :  integer := CSR_HPM_SINGLE_ISSUE      + 1;
  constant CSR_HPM_BRANCH_MISS          :  integer := CSR_HPM_DUAL_ISSUE        + 1;
  constant CSR_HPM_BTB_HIT              :  integer := CSR_HPM_BRANCH_MISS       + 1;
  constant CSR_HPM_BRANCH               :  integer := CSR_HPM_BTB_HIT           + 1;
  constant CSR_HPM_LOAD_DEP             :  integer := CSR_HPM_BRANCH            + 1;
  constant CSR_HPM_STORE_B2B            :  integer := CSR_HPM_LOAD_DEP          + 1;
  constant CSR_HPM_JALR                 :  integer := CSR_HPM_STORE_B2B         + 1;
  constant CSR_HPM_JAL                  :  integer := CSR_HPM_JALR              + 1;
  constant CSR_HPM_RAS_HIT              :  integer := CSR_HPM_JAL               + 1;
  constant CSR_HPM_CPU_CYCLES           :  integer := CSR_HPM_RAS_HIT           + 1;
  constant CSR_HPM_IDLE_CYCLES_FRONTEND :  integer := CSR_HPM_CPU_CYCLES        + 1;
  constant CSR_HPM_IDLE_CYCLES_BACKEND  :  integer := CSR_HPM_IDLE_CYCLES_FRONTEND + 1;
    --constant CSR_HPM_END_IU               :  integer := CSR_HPM_CPU_CYCLES;
  constant CSR_HPM_SFENCE_VMA           :  integer := CSR_HPM_IDLE_CYCLES_BACKEND  + 1;
  constant CSR_HPM_HFENCE_VVMA          :  integer := CSR_HPM_SFENCE_VMA        + 1;
  constant CSR_HPM_HFENCE_GVMA          :  integer := CSR_HPM_HFENCE_VVMA       + 1;
  constant CSR_HPM_TLB_FENCE_00         :  integer := CSR_HPM_HFENCE_GVMA       + 1;
  constant CSR_HPM_TLB_FENCE_01         :  integer := CSR_HPM_TLB_FENCE_00      + 1;
  constant CSR_HPM_TLB_FENCE_10         :  integer := CSR_HPM_TLB_FENCE_01      + 1;
  constant CSR_HPM_TLB_FENCE_11         :  integer := CSR_HPM_TLB_FENCE_10      + 1;
  constant CSR_HPM_IU_INTERNALS         :  integer := CSR_HPM_TLB_FENCE_11      + 1;
  constant CSR_HPM_AFTER_IU             :  integer :=
                                                      0;
  -- CACHETLB_EV_0
  constant CSR_HPM_ICACHE_MISS          :  integer := 0;
  constant CSR_HPM_DCACHE_MISS          :  integer := CSR_HPM_ICACHE_MISS       + 1;
  constant CSR_HPM_ITLB_MISS            :  integer := CSR_HPM_DCACHE_MISS       + 1;
  constant CSR_HPM_DTLB_MISS            :  integer := CSR_HPM_ITLB_MISS         + 1;
  constant CSR_HPM_HTLB_MISS            :  integer := CSR_HPM_DTLB_MISS         + 1;
  constant CSR_HPM_DCACHE_FLUSH         :  integer := CSR_HPM_HTLB_MISS         + 1;
  constant CSR_HPM_DCACHE_ACCESS        :  integer := CSR_HPM_DCACHE_FLUSH      + 1;
  constant CSR_HPM_DCACHE_LOAD          :  integer := CSR_HPM_DCACHE_ACCESS     + 1;
  constant CSR_HPM_DCACHE_STORE         :  integer := CSR_HPM_DCACHE_LOAD       + 1;
  constant CSR_HPM_DCACHE_LOAD_HIT      :  integer := CSR_HPM_DCACHE_STORE      + 1;
  constant CSR_HPM_DCACHE_STORE_HIT     :  integer := CSR_HPM_DCACHE_LOAD_HIT   + 1;
  constant CSR_HPM_DCACHE_STBUF_FULL    :  integer := CSR_HPM_DCACHE_STORE_HIT  + 1;
  constant CSR_HPM_ICACHE_STREAM        :  integer := CSR_HPM_DCACHE_STBUF_FULL + 1;
  constant CSR_HPM_DTLB_ENTRY_FLUSH     :  integer := CSR_HPM_ICACHE_STREAM     + 1;
  constant CSR_HPM_ITLB_ENTRY_FLUSH     :  integer := CSR_HPM_DTLB_ENTRY_FLUSH  + 1;
  constant CSR_HPM_HTLB_ENTRY_FLUSH     :  integer := CSR_HPM_ITLB_ENTRY_FLUSH  + 1;
  constant CSR_HPM_DCACHE_LOAD_MISS     :  integer := CSR_HPM_HTLB_ENTRY_FLUSH  + 1;
  constant CSR_HPM_DCACHE_STORE_MISS    :  integer := CSR_HPM_DCACHE_LOAD_MISS  + 1;
  constant CSR_HPM_ICACHE_ACCESS        :  integer := CSR_HPM_DCACHE_STORE_MISS + 1;
    --constant CSR_HPM_AFTER_CCTRL          :  integer := CSR_HPM_HTLB_ENTRY_FLUSH  + 1;
  -- FPU_EV_0
  -- FPU events
  constant CSR_HPM_FPU_LOW              :  integer := 0;

  -- PMP Configuration Codes
  constant PMP_OFF                      : word2 := "00";
  constant PMP_TOR                      : word2 := "01";
  constant PMP_NA4                      : word2 := "10";
  constant PMP_NAPOT                    : word2 := "11";

  -- PMP Access Type
  subtype  pmpcfg_access_type is word2;
  constant PMP_ACCESS_X : pmpcfg_access_type := "00"; -- Execute
  constant PMP_ACCESS_R : pmpcfg_access_type := "01"; -- Read
  constant PMP_ACCESS_W : pmpcfg_access_type := "11"; -- Write

  function to_floating(fpulen : integer;  set : integer) return integer;

  -- Definitions for CCTRLNV

  type lru_bits_type is array(1 to 4) of integer;
  constant lru_table : lru_bits_type          := (1, 1, 3, 5);

  -- 3-way set permutations
  -- s012 => set 0 - least recently used
  --         set 2 - most recently used
  constant s012 : word3 := "000";
  constant s021 : word3 := "001";
  constant s102 : word3 := "010";
  constant s120 : word3 := "011";
  constant s201 : word3 := "100";
  constant s210 : word3 := "101";


  -- 4-way set permutations
  -- s0123 => set 0 - least recently used
  --          set 3 - most recently used
  -- bits assigned so bits 4:3 is LRU and 1:0 is MRU
  -- middle bit is 0 for 01 02 03 12 13 23, 1 for 10 20 30 21 31 32
  constant s0123 : word5 := "00011";
  constant s0132 : word5 := "00010";
  constant s0213 : word5 := "00111";
  constant s0231 : word5 := "00001";
  constant s0312 : word5 := "00110";
  constant s0321 : word5 := "00101";
  constant s1023 : word5 := "01011";
  constant s1032 : word5 := "01010";
  constant s1203 : word5 := "01111";
  constant s1230 : word5 := "01000";
  constant s1302 : word5 := "01110";
  constant s1320 : word5 := "01100";
  constant s2013 : word5 := "10011";
  constant s2031 : word5 := "10001";
  constant s2103 : word5 := "10111";
  constant s2130 : word5 := "10000";
  constant s2301 : word5 := "10101";
  constant s2310 : word5 := "10100";
  constant s3012 : word5 := "11010";
  constant s3021 : word5 := "11001";
  constant s3102 : word5 := "11110";
  constant s3120 : word5 := "11000";
  constant s3201 : word5 := "11101";
  constant s3210 : word5 := "11100";

  type lru_3way_table_vector_type is array(0 to 2) of word3;
  type lru_3way_table_type        is array (0 to 7) of lru_3way_table_vector_type;

  constant lru_3way_table : lru_3way_table_type :=
    ( (s120, s021, s012),                   -- s012
      (s210, s021, s012),                   -- s021
      (s120, s021, s102),                   -- s102
      (s120, s201, s102),                   -- s120
      (s210, s201, s012),                   -- s201
      (s210, s201, s102),                   -- s210
      (s210, s201, s102),                   -- dummy
      (s210, s201, s102)                    -- dummy
      );

  type lru_4way_table_vector_type is array(0 to  3) of word5;
  type lru_4way_table_type        is array(0 to 31) of lru_4way_table_vector_type;

  constant lru_4way_table : lru_4way_table_type :=
    ( (s2310, s0231, s0312, s0213),       -- "00000" (s0231/reset)
      (s2310, s0231, s0312, s0213),       -- "00001" s0231
      (s1320, s0321, s0132, s0123),       -- "00010" s0132
      (s1230, s0231, s0132, s0123),       -- "00011" s0123
      (s3210, s0321, s0312, s0213),       -- "00100" (s0321)
      (s3210, s0321, s0312, s0213),       -- "00101" s0321
      (s3120, s0321, s0312, s0123),       -- "00110" s0312
      (s2130, s0231, s0132, s0213),       -- "00111" s0213
      (s1230, s2301, s1302, s1203),       -- "01000" s1230
      (s1230, s2301, s1302, s1203),       -- "01001" (s1230)
      (s1320, s0321, s1032, s1023),       -- "01010" s1032
      (s1230, s0231, s1032, s1023),       -- "01011" s1023
      (s1320, s3201, s1302, s1203),       -- "01100" s1320
      (s1320, s3201, s1302, s1203),       -- "01101" (s1320)
      (s1320, s3021, s1302, s1023),       -- "01110" s1302
      (s1230, s2031, s1032, s1203),       -- "01111" s1203
      (s2130, s2301, s1302, s2103),       -- "10000" s2130
      (s2310, s2031, s0312, s2013),       -- "10001" s2031
      (s2130, s2031, s0132, s2013),       -- "10010" (s2013)
      (s2130, s2031, s0132, s2013),       -- "10011" s2013
      (s2310, s2301, s3102, s2103),       -- "10100" s2310
      (s2310, s2301, s3012, s2013),       -- "10101" s2301
      (s2130, s2031, s1032, s2103),       -- "10110" (s2103)
      (s2130, s2031, s1032, s2103),       -- "10111" s2103
      (s3120, s3201, s3102, s1203),       -- "11000" s3120
      (s3210, s3021, s3012, s0213),       -- "11001" s3021
      (s3120, s3021, s3012, s0123),       -- "11010" s3012
      (s3120, s3021, s3012, s0123),       -- "11011" (s3012)
      (s3210, s3201, s3102, s2103),       -- "11100" s3210
      (s3210, s3201, s3012, s2013),       -- "11101" s3201
      (s3120, s3021, s3102, s1023),       -- "11110" s3102
      (s3120, s3021, s3102, s1023)        -- "11111" (s3102)
      );

  type lru3_repl_table_single_type is array(0 to 2) of integer range 0 to 2;
  type lru3_repl_table_type        is array(0 to 7) of lru3_repl_table_single_type;

  constant lru3_repl_table : lru3_repl_table_type :=
    ( (0, 1, 2),      -- s012
      (0, 2, 2),      -- s021
      (1, 1, 2),      -- s102
      (1, 1, 2),      -- s120
      (2, 2, 2),      -- s201
      (2, 2, 2),      -- s210
      (2, 2, 2),      -- dummy
      (2, 2, 2)       -- dummy
      );

  type lru4_repl_table_single_type is array(0 to 3) of integer range 0 to 3;
  type lru4_repl_table_type        is array(0 to 31) of lru4_repl_table_single_type;

  constant lru4_repl_table : lru4_repl_table_type :=
    ( (0, 2, 2, 3), -- (s0231/reset)
      (0, 2, 2, 3), -- s0231
      (0, 1, 3, 3), -- s0132
      (0, 1, 2, 3), -- s0123
      (0, 3, 3, 3), -- (s0321)
      (0, 3, 3, 3), -- s0321
      (0, 3, 3, 3), -- s0312
      (0, 2, 2, 3), -- s0213
      (1, 1, 2, 3), -- s1230
      (1, 1, 2, 3), -- (s1230)
      (1, 1, 3, 3), -- s1032
      (1, 1, 2, 3), -- s1023
      (1, 1, 3, 3), -- s1320
      (1, 1, 3, 3), -- (s1320)
      (1, 1, 3, 3), -- s1302
      (1, 1, 2, 3), -- s1203
      (2, 2, 2, 3), -- s2130
      (2, 2, 2, 3), -- s2031
      (2, 2, 2, 3), -- (s2013)
      (2, 2, 2, 3), -- s2013
      (2, 2, 2, 3), -- s2310
      (2, 2, 2, 3), -- s2301
      (2, 2, 2, 3), -- (s2103)
      (2, 2, 2, 3), -- s2103
      (3, 3, 3, 3), -- s3120
      (3, 3, 3, 3), -- s3021
      (3, 3, 3, 3), -- s3012
      (3, 3, 3, 3), -- (s3012)
      (3, 3, 3, 3), -- s3210
      (3, 3, 3, 3), -- s3201
      (3, 3, 3, 3), -- s3102
      (3, 3, 3, 3)  -- (s3102)
      );

  function extend_wordx(v : std_logic_vector) return wordx;
  function medeleg_mask(h_en : boolean) return wordx;
  function to_mideleg(
    wcsr         : wordx;
    mode_s       : boolean;
    h_en         : boolean;
    ext_sscofpmf : boolean) return wordx;
  function mip_mask(mode_s : boolean; h_en : boolean;
                    ext_sscofpmf : boolean;
                    menvcfg_stce : std_ulogic) return wordx;
  function mie_mask(mode_s : boolean; h_en : boolean;
                    ext_sscofpmf : boolean) return wordx;
  function sip_sie_mask(ext_sscofpmf : boolean) return wordx;
  function hideleg_mask(ext_shlcofideleg : integer) return wordx;
  function etrigger_mask(h_en : boolean) return wordx;

  function to_hstatus(status : csr_hstatus_type) return wordx;
  function to_hstatus(wdata : wordx) return csr_hstatus_type;

  -- Note that the to_*status* functions do not deal with
  -- static clearing due to active extensions!
  -- This is rather handled by tie_csrs().

  function to_vsstatus(status      : csr_status_type;
                       ssdbltrp_en : std_ulogic;
                       bcfi_en     : std_ulogic;
                       fcfi_en     : std_ulogic
                      ) return wordx;
  function to_vsstatus(wdata       : wordx;
                       vsstatus_in : csr_status_type;
                       ssdbltrp_en : std_ulogic;
                       bcfi_en     : std_ulogic;
                       fcfi_en     : std_ulogic
                      ) return csr_status_type;

  function to_mstatus(status : csr_status_type) return wordx;
  function to_mstatus(wdata       : wordx;
                      mstatus_in  : csr_status_type;
                      smdbltrp_en : std_ulogic;
                      ssdbltrp_en : std_ulogic) return csr_status_type;

  function to_mstatush(status : csr_status_type) return wordx;
  function to_mstatush(wdata       : wordx;
                       mstatus_in  : csr_status_type;
                       h_en        : boolean;
                       smdbltrp_en : std_ulogic) return csr_status_type;

  function to_sstatus(status  : csr_status_type;
                      bcfi_en : std_ulogic;
                      fcfi_en : std_ulogic;
                      dte     : std_ulogic
                     ) return wordx;
  function to_sstatus(wdata       : wordx;
                      mstatus     : csr_status_type;
                      ssdbltrp_en : std_ulogic;
                      bcfi_en     : std_ulogic;
                      fcfi_en     : std_ulogic
                     ) return csr_status_type;


  function to_mnstatus(mnstatus : csr_mnstatus_type) return wordx;
  function to_mnstatus(wdata    : wordx;
                       mnstatus : csr_mnstatus_type;
                       active   : extension_type;
                       misa     : wordx) return csr_mnstatus_type;

  function to_hvictl(hvictl : csr_hvictl_type) return wordx;
  function to_hvictl(wdata : wordx) return csr_hvictl_type;

  function mvien_mask(ext_sscofpmf  : integer; 
                      ext_smcdeleg  : integer) return wordx;
  function hvien_mask(ext_sscofpmf  : integer; 
                      ext_smcdeleg  : integer) return wordx;
  function to_mvip(mip : wordx; mvip : wordx;
                   mvien : wordx; ext_sstc : integer;
                   menvcfg_stce : std_ulogic) return wordx;
  function "and" (L : csr_mstateen0_type; R : csr_mstateen0_type) return csr_mstateen0_type;
  function "and" (L : csr_hstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type;
  function "and" (L : csr_hstateen0_type; R : csr_mstateen0_type) return csr_hstateen0_type;
  function "and" (L : csr_mstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type;
  function "and" (L : csr_sstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type;
  function "and" (L : csr_sstateen0_type; R : csr_hstateen0_type) return csr_sstateen0_type;
  function "and" (L : csr_hstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type;

  function "not" (I : csr_mstateen0_type) return csr_mstateen0_type;
  function "not" (I : csr_hstateen0_type) return csr_hstateen0_type;

  function "or"  (L : csr_mstateen0_type; R : csr_mstateen0_type) return csr_mstateen0_type;
  function "or"  (L : csr_hstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type;
  function "or"  (L : csr_sstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type;
  function stateen_wpri_write(wcsr_in   : wordx;
                              prev      : csr_hstateen0_type;
                              mask      : csr_mstateen0_type;
                              high_half : boolean) return csr_hstateen0_type;
  function stateen_wpri_write(wcsr_in   : wordx;
                              prev      : csr_sstateen0_type;
                              mask      : csr_hstateen0_type;
                              high_half : boolean) return csr_sstateen0_type;
  function stateen_wpri_write(wcsr_in   : std_logic;
                              prev      : std_logic;
                              mask      : std_logic) return std_logic;
  -- function mstateen0_mask(mstateen0 : csr_mstateen0_type; mask : csr_mstateen0_type) return csr_mstateen0_type;
  -- function hstateen0_mask(hstateen0 : csr_hstateen0_type; mask : csr_mstateen0_type) return csr_hstateen0_type;
  -- function sstateen0_mask(sstateen0 : csr_sstateen0_type;
  --                         mask_m    : csr_mstateen0_type;
  --                         mask_h    : csr_hstateen0_type) return csr_sstateen0_type;
  function gen_mstateen0_mask(active : extension_type) return csr_mstateen0_type;
  function to_mstateen0(mstateen0 : csr_mstateen0_type) return wordx;
  function to_mstateen0(wdata  : wordx;
                        mstateen0 : csr_mstateen0_type) return csr_mstateen0_type;
  function to_hstateen0(hstateen0 : csr_hstateen0_type) return wordx;
  function to_hstateen0(wdata  : wordx;
                        hstateen0 : csr_hstateen0_type) return csr_hstateen0_type;
  function to_sstateen0(sstateen0 : csr_sstateen0_type) return wordx;
  function to_sstateen0(sstateen0 : wordx) return csr_sstateen0_type;
  function to_mstateen0h(mstateen0 : csr_mstateen0_type) return wordx;
  function to_hstateen0h(hstateen0 : csr_hstateen0_type) return wordx;
  function to_mstateen0h(wdata     : wordx;
                         mstateen0 : csr_mstateen0_type) return csr_mstateen0_type;
  function to_hstateen0h(wdata     : wordx;
                         hstateen0 : csr_hstateen0_type) return csr_hstateen0_type;

  function to_mhcontext(wdata : wordx; h_en : boolean) return csr_mhcontext_type;
  function to_scontext(wdata : wordx) return csr_scontext_type;

  function to_envcfg(envcfg : csr_envcfg_type) return wordx;
  function to_envcfg(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return wordx;
  function to_envcfg(wdata  : wordx;
                     envcfg : csr_envcfg_type;
                     mask   : csr_envcfg_type) return csr_envcfg_type;
  function to_envcfgh(envcfg : csr_envcfg_type) return wordx;
  function to_envcfgh(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return wordx;
  function to_envcfgh(wdata   : wordx;
                      envcfg  : csr_envcfg_type;
                      mask    : csr_envcfg_type) return csr_envcfg_type;
  function envcfg_mask(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return csr_envcfg_type;
  function gen_envcfg_const_mmask(active : extension_type) return csr_menvcfg_const_type;
  function gen_envcfg_const_hmask(menvcfg_mask : csr_menvcfg_const_type) return csr_henvcfg_const_type;
  function gen_envcfg_const_smask(menvcfg_mask : csr_menvcfg_const_type) return csr_senvcfg_const_type;
  function calc_henvcfg_write_val(wcsr_in       : wordx;
                                 active_henvcfg : csr_henvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                 return csr_henvcfg_type;
  function calc_henvcfg_read_val(active_henvcfg : csr_henvcfg_const_type;
                                csr_file        : csr_reg_type)
                                return csr_henvcfg_type;
  function calc_senvcfg_write_val(wcsr_in       : wordx;
                                 active_henvcfg : csr_henvcfg_const_type;
                                 active_senvcfg : csr_senvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                 return csr_senvcfg_type;
  function calc_senvcfg_read_val(active_henvcfg : csr_henvcfg_const_type;
                                 active_senvcfg : csr_senvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                return csr_senvcfg_type;

  function to_mseccfg(data   : wordx;
                      seccfg : csr_seccfg_type) return csr_seccfg_type;
  function to_mseccfgh(data   : wordx;
                       seccfg : csr_seccfg_type) return csr_seccfg_type;
  function to_mseccfg(seccfg : csr_seccfg_type) return word64;


  function to_capabilityh(fpuconf : word2; cconfig : word64) return word;
  function to_capability(fpuconf : word2; cconfig : word64) return wordx;

  function to_hpmevent(wdata : wordx; hpmevent_in : hpmevent_type) return hpmevent_type;
  function to_hpmeventh(wdata : wordx; hpmevent_in : hpmevent_type) return hpmevent_type;

  function to_hpmevent(hpmevent : hpmevent_type) return wordx;
  function to_hpmeventh(hpmevent : hpmevent_type) return wordx;
  function to_scountinhibit(mcountinhibit_in : word; mcounteren : word; wcsr : wordx) return word;

  function pmp_precalc(pmpaddr    : pmpaddr_type;
                       pmpaddr_m1 : pmpaddr_type;
                       valid      : boolean;
                       a          : pmpcfg_access_type;
                       no_tor     : integer;
                       g          : integer;
                       msb        : integer := 31
                      ) return pmp_precalc_type;

  procedure pmp_precalc(pmpaddr     : in  pmpaddr_vec_type;
                        pmpcfg_in   : in  pmpcfg_vec_type;
                        precalc     : out pmp_precalc_vec;
                        pmp_entries : in  integer;
                        pmp_no_tor  : in  integer;
                        pmp_g       : in  integer;
                        msb         : in  integer := 31
                       );

  function smepmp_ok_r(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx_in : word3) return boolean;

  function smepmp_ok_w(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx_in : word3) return boolean;

  function smepmp_ok_x(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx    : word3) return boolean;

  function smepmp_rwx(pmpcfg  : pmpcfg_vec_type;
                      mmwp    : std_logic;
                      mml     : std_logic;
                      prv     : priv_lvl_type;
                      hit     : std_logic_vector;
                      entries : integer := 16;
                      smepmp  : integer := 0
                     ) return word3;

  function pmp_match(precalc : pmp_precalc_vec;
                     addr    : std_logic_vector;
                     entries : integer := 16;
                     no_tor  : integer := 1;
                     pmp_g   : integer range 1 to 32 := 1;
                     msb     : integer := 31
                    ) return std_logic_vector;


  -- Currently no reason to support
  -- unaligned access         never possible
  -- I/O vs RAM ordering      TSO
  -- core to core ordering    TSO
  -- cache mode               always write-through, no allocate on write
  -- coherency mode           always hardwired
  -- idempotency for I/O r/w  always the same for r/w
  -- atomic types for I/O     always all or nothing
  -- atomic size for I/O      always bus size
  type pma_t is record
    valid : std_logic;
    r     : std_logic;
    w     : std_logic;
    x     : std_logic;
    pt_r  : std_logic;
    pt_w  : std_logic;
    cache : std_logic;
    burst : std_logic;
    idem  : std_logic;
    amo   : std_logic;
    lrsc  : std_logic;
    busw  : std_logic;
  end record;

  constant PMA_SIZE : integer := 12;

  constant pma_unused : pma_t := (
    valid => '0',
    r     => '0',
    w     => '0',
    x     => '0',
    pt_r  => '0',
    pt_w  => '0',
    cache => '0',
    burst => '0',
    idem  => '0',
    amo   => '0',
    lrsc  => '0',
    busw  => '0'
   );

  constant pma_all : pma_t := (
    valid => '1',
    r     => '1',
    w     => '1',
    x     => '1',
    pt_r  => '1',
    pt_w  => '1',
    cache => '1',
    burst => '1',
    idem  => '1',
    amo   => '1',
    lrsc  => '1',
    busw  => '1'
   );

  function to_pma(v_in : std_logic_vector) return pma_t;
  function from_pma(pma : pma_t) return std_logic_vector;
  function pma_sanitize(data : word64; is_rv64 : boolean) return word64;
  function pma_precalc(addr_arr    : word64_arr;
                       pma_entries : integer range 0 to 16;
                       physaddr    : integer) return pmp_precalc_vec;

  function pma_pbmt_nc(pma_in : pma_t) return pma_t;
  function pma_pbmt_io(pma_in : pma_t) return pma_t;

  function pma_valid(pma : pma_t) return boolean;
  function pma_r(pma : pma_t) return boolean;
  function pma_w(pma : pma_t) return boolean;
  function pma_x(pma : pma_t) return boolean;
  function pma_pt_r(pma : pma_t) return boolean;
  function pma_pt_w(pma : pma_t) return boolean;
  function pma_cache(pma : pma_t) return std_logic;
  function pma_burst(pma : pma_t) return boolean;
  function pma_idem(pma : pma_t) return boolean;
  function pma_amo(pma : pma_t) return boolean;
  function pma_lrsc(pma : pma_t) return boolean;
  function pma_busw(pma : pma_t) return std_logic;
  function pma_rwx(pma : pma_t) return word3;
  function tost_pma_vrwx(pma : pma_t) return string;

  procedure pma_masks(data    : in  word64_arr;
                      addr_in : in  std_logic_vector;
                      valid   : in  std_logic;
                      pma_out : out pma_t;
                      fit_out : out std_logic_vector;
                      msb     : in  integer := 31);

  procedure pma_unit(precalc : in  pmp_precalc_vec;
                     addr    : in  std_logic_vector;
                     valid   : in  std_ulogic;
                     hit_out : out std_logic_vector;
                     entries : in  integer := 16;
                     no_tor  : in  integer := 0;
                     msb     : in  integer := 31
                    );

  procedure pma_mmuu(precalc      : in  pmp_precalc_vec;
                     addr_low     : in  std_logic_vector;
                     addr_mask_in : in  std_logic_vector;
                     valid        : in  std_ulogic;
                     hit_out      : out std_logic_vector;
                     fit_out      : out std_logic_vector;
                     msb          : in  integer := 31
                    );

  procedure pmp_mmuu(precalc   : in  pmp_precalc_vec;
                     pmpcfg_in : in  pmpcfg_vec_type;
                     mml       : in  std_ulogic;
                     addr_low  : in  std_logic_vector;
                     addr_mask : in  std_logic_vector;
                     valid     : in  std_ulogic;
                     hit_out   : out std_logic_vector;
                     fit_out   : out std_logic_vector;
                     l_out     : out std_logic_vector;
                     r_out     : out std_logic_vector;
                     w_out     : out std_logic_vector;
                     x_out     : out std_logic_vector;
                     msb       : in  integer := 31;
                     smepmp    : in  integer := 0
                    );

  function limit_mask(addr_mask_in : std_logic_vector; high : integer := 0) return std_logic_vector;



  function amo_math_op(
    op1_in  : std_logic_vector;
    op2_in  : std_logic_vector;
    ctrl_in : word4) return std_logic_vector;

  function mmuen_set(mmuen : integer) return integer;

  procedure jump_unit(active    : in  extension_type;
                      fusel_in  : in  fuseltype;
                      valid_in  : in  std_ulogic;
                      imm_in    : in  wordx;
                      ras_in    : in  nv_ras_out_type;
                      rf1       : in  wordx;
                      flush_in  : in  std_ulogic;
                      jump_out  : out std_ulogic;
                      mem_jump  : out std_ulogic;
                      xc_out    : out std_ulogic;
                      cause_out : out cause_type;
                      tval_out  : out wordx;
                      addr_out  : out std_logic_vector);
  procedure ujump_resolve(active    : in  extension_type;
                          inst_in   : in  word;
                          valid_in  : in  std_ulogic;
                          xc_in     : in  std_ulogic;
                          target_in : in  std_logic_vector;
                          next_in   : in  std_logic_vector;
                          taken_in  : in  std_ulogic;
                          hit_in    : in  std_ulogic;
                          xc_out    : out std_ulogic;
                          cause_out : out cause_type;
                          tval_out  : out wordx;
                          jump_out  : out std_ulogic;
                          addr_out  : out std_logic_vector);

  procedure branch_resolve(active     : in  extension_type;
                           fusel_in   : in  fuseltype;
                           valid_in   : in  std_ulogic;
                           xc_in      : in  std_ulogic;
                           pc_in      : in  std_logic_vector;
                           comp_in    : in  std_ulogic;
                           taken_in   : in  std_ulogic;
                           hit_in     : in  std_ulogic;
                           imm_in     : in  wordx;
                           valid_out  : out std_ulogic;
                           branch_out : out std_ulogic;
                           taken_out  : out std_ulogic;
                           hit_out    : out std_ulogic;
                           xc_out     : out std_ulogic;
                           cause_out  : out cause_type;
                           next_out   : out std_logic_vector;
                           addr_out   : out std_logic_vector);
  procedure branch_misc(active    : in  extension_type;
                        fusel_in  : in  fuseltype;
                        valid_in  : in  std_ulogic;
                        xc_in     : in  std_ulogic;
                        pc_in     : in  std_logic_vector;
                        comp_in   : in  std_ulogic;
                        taken_in  : in  std_ulogic;
                        hit_in    : in  std_ulogic;
                        imm_in    : in  wordx_arr;
                        swap      : in  std_logic;
                        branch_lane : in  integer;
                        valid_out : out std_ulogic;
                        taken_out : out std_ulogic;
                        hit_out   : out std_ulogic;
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        next_out  : out std_logic_vector;
                        addr_out  : out std_logic_vector);


  procedure ras_update(speculative_in : in  integer;
                       inst_in        : in  word;
                       fusel_in       : in  fuseltype;
                       valid_in       : in  std_ulogic;
                       xc_in          : in  std_ulogic;
                       rdv_in         : in  std_ulogic;
                       wdata_in       : in  std_logic_vector;
                       rasi_in        : in  nv_ras_in_type;
                       hold_in        : in  std_ulogic;
                       rstate         : in  core_state;
                       ras_out        : out nv_ras_in_type);
  procedure ras_resolve(active    : in  extension_type;
                        inst_in   : in  word;
                        fusel_in  : in  fuseltype;
                        valid_in  : in  std_ulogic;
                        xc_in     : in  std_ulogic;
                        rdv_in    : in  std_ulogic;
                        rs1_in    : in  reg_t;
                        ras_in    : in  nv_ras_out_type;
                        ras_out   : out nv_ras_out_type;
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        tval_out  : out wordx);
end;

package body nvsupport is

  function extension(item : x_type) return extension_type is
    -- Non-constant
    variable v : extension_type := extension_none;
  begin
    v(x_type'pos(item)) := '1';

    return v;
  end;

  function extension(item : x_type; valid : boolean) return extension_type is
  begin
    if not valid then
      return extension_none;
    end if;

    return extension(item);
  end;

  function enable(active : extension_type; item : x_type) return extension_type is
  begin
    return active or extension(item);
  end;

  function disable(active : extension_type; item : x_type) return extension_type is
  begin
    return active and not extension(item);
  end;

  function disable(active : extension_type; item1, item2 : x_type) return extension_type is
  begin
    return active and not (extension(item1) or extension(item2));
  end;

  function is_enabled(active : extension_type; item : x_type) return boolean is
  begin
    return active(x_type'pos(item)) = '1';  --jk not all_0(active and extension(item));
  end;

  function is_enabled(active : extension_type; item : x_type) return integer is
  begin
    return b2i(is_enabled(active, item));
  end;

  constant config_all      : extension_type :=
    extension(x_single_issue) or
    extension(x_late_alu)     or
    extension(x_late_branch)  or
    extension(x_muladd)       or
    extension(x_fpu_debug)    or
    extension(x_dtcm)         or
    extension(x_itcm)         or
    extension(x_rv64);

  function fusel(n : integer range 0 to FUSELBITS - 1) return fuseltype is
    -- Non-constant
    variable r : fuseltype := (others => '0');
  begin
    r(n) := '1';

    return r;
  end;

  constant NONE         : fuseltype := (others => '0');
  constant ALU          : fuseltype := fusel(0);     -- ALU
  constant BRANCH       : fuseltype := fusel(1);     -- Branch Unit
  constant JAL          : fuseltype := fusel(2);     -- JAL
  constant JALR         : fuseltype := fusel(3);     -- JALR
  constant FLOW         : fuseltype := JAL or JALR;  -- Jump (JAL/JALR)
  constant MUL          : fuseltype := fusel(4);     -- Mul/Div
  constant LD           : fuseltype := fusel(5);     -- Load
  constant ST           : fuseltype := fusel(6);     -- Store
  constant AMO          : fuseltype := fusel(7);     -- Atomics
  constant FPU          : fuseltype := fusel(8);     -- From FPU
  constant ALU_SPECIAL  : fuseltype := fusel(9);     -- Only for early ALU in lane 0!
  constant DIAG         : fuseltype := fusel(10);    -- Diagnostic cache load/store
  constant UNKNOWN      : fuseltype := fusel(11);    -- Unknown (regarding fusel) instruction
  constant CFI          : fuseltype := fusel(12);    -- CFI
  constant NOT_LATE     : fuseltype := not (ALU or BRANCH);  -- All except ALU and Branch Unit

  -- Shortens addresses to the size that is actually needed (see addr_type).
  -- If an address is "sign extended" above the useable part, the two bits
  -- just above that part will be the same as that one.
  -- A mix of 0s and 1s above the useable part will force the two bits
  -- just above that part to be "10".
  -- Example - MSB is top of actually useable address bits:
  --   Incoming address <n bits (X)><1 MSB><(XLEN - n - 1) LSBs>
  --   1 X = 111...111 -> 11<MSB><LSBs>
  --   2 X = 000...000 -> 00<MSB><LSBs>
  --   3 X = <mix 0/1> -> 10<MSB><LSBs>
  --   ->
  --   1 - The extra bits will be a sign extension if MSB is 1.
  --   2 - The extra bits will be a sign extension if MSB is 0.
  --   3 - Top two bits always different.
  --   ->
  --     A properly sign extended virtual address will stay sign extended in short form.
  --     A badly sign extended virtual address will stay badly sign extended.
  --     A physical address will have "00" at the top if and only if all were zero up there.
  function to_addr(addr_in : std_logic_vector;
                   length  : integer) return std_logic_vector is
    subtype  addr_type  is std_logic_vector(length - 1 downto 0);
    variable addr_bits   : integer                                               := length - 2;
    variable addr_normal : std_logic_vector(addr_in'length - 1 downto 0)         := addr_in;
    variable high_bits   : std_logic_vector(addr_in'length - 1 downto addr_bits) := (others => '0');
    -- Non-constant
    variable addr        : addr_type;  -- Manipulated from _in for efficiency.
  begin
    addr := addr_normal(addr'range);
    if addr_normal'length > addr'length then
      addr(addr'high)     := not all_0(addr_normal(high_bits'range));  -- Some high 1s?
      addr(addr'high - 1) :=     all_1(addr_normal(high_bits'range));  -- All high 1s?
    end if;

    return addr;
  end;

  -- Generate Next PC with adder, depending on whether compressed or not.
  function npc_adder(pc   : std_logic_vector;  -- pctype
                     comp : std_ulogic) return std_logic_vector is
    subtype  pctype is std_logic_vector(pc'range);
    -- Non-constant
    variable op2     : integer;
    variable npc     : pctype;
  begin
    op2   := 4;
    if comp = '1' then
      op2 := 2;
    end if;

    npc   := uadd(pc, op2);

    return to_addr(npc, pc'length);
  end;

  function extend_wordx(v : std_logic_vector) return wordx is
     -- Non-constant
    variable result : wordx := (others => v(v'left));
    variable vv     : std_logic_vector(v'length-1 downto 0) := v;
  begin
    if v'length <= wordx'length then
      result(v'length - 1 downto 0) := v;
    else
      result := vv(wordx'range);
    end if;

    return result;
  end;

  constant XC_INST_ADDR_MISALIGNED      : cause_type := to_cause(0);
  constant XC_INST_ACCESS_FAULT         : cause_type := to_cause(1);
  constant XC_INST_ILLEGAL_INST         : cause_type := to_cause(2);
  constant XC_INST_BREAKPOINT           : cause_type := to_cause(3);
  constant XC_INST_LOAD_ADDR_MISALIGNED : cause_type := to_cause(4);
  constant XC_INST_LOAD_ACCESS_FAULT    : cause_type := to_cause(5);
  constant XC_INST_STORE_ADDR_MISALIGNED: cause_type := to_cause(6);
  constant XC_INST_STORE_ACCESS_FAULT   : cause_type := to_cause(7);
  constant XC_INST_ENV_CALL_UMODE       : cause_type := to_cause(8);
  constant XC_INST_ENV_CALL_SMODE       : cause_type := to_cause(9);
  constant XC_INST_ENV_CALL_VSMODE      : cause_type := to_cause(10);
  constant XC_INST_ENV_CALL_MMODE       : cause_type := to_cause(11);
  constant XC_INST_INST_PAGE_FAULT      : cause_type := to_cause(12);
  constant XC_INST_LOAD_PAGE_FAULT      : cause_type := to_cause(13);
  -- 14    Reserved by Privileged Architecture
  constant XC_INST_STORE_PAGE_FAULT     : cause_type := to_cause(15);
  constant XC_INST_DOUBLE_TRAP          : cause_type := to_cause(16);
  -- 17    Reserved by Privileged Architecture
  constant XC_INST_SOFTWARE_CHECK       : cause_type := to_cause(18);
  -- 19    Hardware error - should probably be used for non-correctable data corruption
  constant XC_INST_INST_G_PAGE_FAULT    : cause_type := to_cause(20);
  constant XC_INST_LOAD_G_PAGE_FAULT    : cause_type := to_cause(21);
  constant XC_INST_VIRTUAL_INST         : cause_type := to_cause(22);
  constant XC_INST_STORE_G_PAGE_FAULT   : cause_type := to_cause(23);
  -- 24-31 Designated for custom use
  constant XC_INST_NV_INST_SPT_FAULT    : cause_type := to_cause(24);
  constant XC_INST_NV_LOAD_SPT_FAULT    : cause_type := to_cause(25);
  constant XC_INST_NV_STORE_SPT_FAULT   : cause_type := to_cause(26);
  constant XC_INST_NV_INST_HPT_FAULT    : cause_type := to_cause(27);
  constant XC_INST_NV_LOAD_HPT_FAULT    : cause_type := to_cause(28);
  constant XC_INST_NV_STORE_HPT_FAULT   : cause_type := to_cause(29);
  constant XC_INST_RFFT                 : cause_type := to_cause(31);
  -- 32-47 Reserved by Privileged Architecture
  -- 48-63 Designated for custom use
  constant XC_UNUSED                    : cause_type := to_cause(30);
  -- >=64  Reserved by Privileged Architecture

  constant cause_none                   : cause_type := XC_UNUSED;


  -- Interrupt Codes
  -- 0     Reserved by Privileged Architecture
  constant IRQ_S_SOFTWARE               : integer    := 1;
  constant CAUSE_IRQ_S_SOFTWARE         : cause_type := to_cause(IRQ_S_SOFTWARE, true);
  constant IRQ_VS_SOFTWARE              : integer    := 2;
  constant CAUSE_IRQ_VS_SOFTWARE        : cause_type := to_cause(IRQ_VS_SOFTWARE, true);
  constant IRQ_M_SOFTWARE               : integer    := 3;
  constant CAUSE_IRQ_M_SOFTWARE         : cause_type := to_cause(IRQ_M_SOFTWARE, true);
  -- 4     Reserved by Privileged Architecture
  constant IRQ_S_TIMER                  : integer    := 5;
  constant CAUSE_IRQ_S_TIMER            : cause_type := to_cause(IRQ_S_TIMER, true);
  constant IRQ_VS_TIMER                 : integer    := 6;
  constant CAUSE_IRQ_VS_TIMER           : cause_type := to_cause(IRQ_VS_TIMER, true);
  constant IRQ_M_TIMER                  : integer    := 7;
  constant CAUSE_IRQ_M_TIMER            : cause_type := to_cause(IRQ_M_TIMER, true);
  -- 8     Reserved by Privileged Architecture
  constant IRQ_S_EXTERNAL               : integer    := 9;
  constant CAUSE_IRQ_S_EXTERNAL         : cause_type := to_cause(IRQ_S_EXTERNAL, true);
  constant IRQ_VS_EXTERNAL              : integer    := 10;
  constant CAUSE_IRQ_VS_EXTERNAL        : cause_type := to_cause(IRQ_VS_EXTERNAL, true);
  constant IRQ_M_EXTERNAL               : integer    := 11;
  constant CAUSE_IRQ_M_EXTERNAL         : cause_type := to_cause(IRQ_M_EXTERNAL, true);
  constant IRQ_SG_EXTERNAL              : integer    := 12;
  constant CAUSE_IRQ_SG_EXTERNAL        : cause_type := to_cause(IRQ_SG_EXTERNAL, true);
  constant IRQ_LCOF                     : integer    := 13;
  constant CAUSE_IRQ_LCOF               : cause_type := to_cause(IRQ_LCOF, true);
  -- 14-15 Reserved by Privileged Architecture
  constant IRQ_NMI                      : integer    := 16;
  constant CAUSE_IRQ_NMI                : cause_type := to_cause(IRQ_NMI, true);
  -- 16-23 Reserved for standard local interrupts
  -- 24-31 Designated for custom use
  -- 32-34 Reserved for standard local interrupts
  constant IRQ_RAS_LOW_PRIO             : integer    := 35;
  constant CAUSE_IRQ_RAS_LOW_PRIO       : cause_type := to_cause(IRQ_RAS_LOW_PRIO, true);
  -- 36-42 Reserved for standard local interrupts
  constant IRQ_RAS_HIGH_PRIO            : integer    := 43;
  constant CAUSE_IRQ_RAS_HIGH_PRIO      : cause_type := to_cause(IRQ_RAS_HIGH_PRIO, true);
  -- 44-47 Reserved for standard local interrupts
  -- 48-   Designated for custom use
  constant IRQ_UNUSED                   : integer    := 63;
  constant CAUSE_IRQ_UNUSED             : cause_type := to_cause(IRQ_UNUSED, true);

  -- Reset Codes
  constant RST_HARD_ALL                 : cause_type := to_cause(0);
  constant RST_ASYNC                    : cause_type := to_cause(1);

  -- Interrupts
  constant I_none : wordx := zerox;                              -- No bits set
  constant I_SS   : wordx := cause2mask(CAUSE_IRQ_S_SOFTWARE);   --
  constant I_VSS  : wordx := cause2mask(CAUSE_IRQ_VS_SOFTWARE);  -- H
  constant I_MS   : wordx := cause2mask(CAUSE_IRQ_M_SOFTWARE);   -- External register only
  constant I_ST   : wordx := cause2mask(CAUSE_IRQ_S_TIMER);      --
  constant I_VST  : wordx := cause2mask(CAUSE_IRQ_VS_TIMER);     -- H
  constant I_MT   : wordx := cause2mask(CAUSE_IRQ_M_TIMER);      -- mtimecmp only
  constant I_SE   : wordx := cause2mask(CAUSE_IRQ_S_EXTERNAL);   --
  constant I_VSE  : wordx := cause2mask(CAUSE_IRQ_VS_EXTERNAL);  -- H
  constant I_ME   : wordx := cause2mask(CAUSE_IRQ_M_EXTERNAL);   -- external interrupt only
  constant I_SGE  : wordx := cause2mask(CAUSE_IRQ_SG_EXTERNAL);  -- H
  constant I_LCOF : wordx := cause2mask(CAUSE_IRQ_LCOF);         -- Sscofpmf
  constant I_NMI  : wordx := cause2mask(CAUSE_IRQ_NMI);          -- NMI
  constant I_RSV0 : wordx := int2mask(0);                        -- Reserved - formerly N extension
  constant I_RSV4 : wordx := int2mask(4);                        -- Reserved - formerly N extension
  constant I_RSV8 : wordx := int2mask(8);                        -- Reserved - formerly N extension
  constant I_RSVE : wordx := int2mask(14);                       -- Reserved
  constant I_RSVF : wordx := int2mask(15);                       -- Reserved

  constant CSR_MIE_MASK     : wordx := I_MS or I_MT or I_ME;              -- Valid
  constant CSR_MIP_MASK     : wordx := I_none;                            -- Writable

  constant CSR_HIDELEG_MASK : wordx := I_VSS or I_VST or I_VSE;           -- Delegate to VS
  constant CSR_HIE_MASK     : wordx := I_VSS or I_VST or I_VSE or I_SGE;  -- Valid
  constant CSR_HIP_MASK     : wordx := I_VSS;                             -- Writable

  constant CSR_MIDELEG_MASK : wordx := I_SS or I_ST or I_SE;              -- Delegate to S
  constant CSR_SIE_MASK     : wordx := I_SS or I_ST or I_SE;              -- Valid
  constant CSR_SIP_MASK     : wordx := I_SS or I_ST or I_SE;              -- Writable

  constant CSR_MVIEN_MASK   : wordx := I_SS or I_SE;                      -- Writable


  constant CSR_IRQ_RSV_MASK : wordx := I_RSV0 or I_RSV4 or I_RSV8 or I_RSVE or I_RSVF;

  constant RST_VEC          : wordx := extend_wordx(x"00010040");

  constant CSR_MEDELEG_MASK : wordx := extend_wordx(x"000cb3ff");
  constant CSR_HEDELEG_MASK : wordx := extend_wordx(x"000cb1ff");


  type xint_arr is array (integer range <>) of integer range 0 to 7;
  constant xc_prio : xint_arr(0 to 63) := (
    2, 4, 2, 2, 1, 0, 1, 0,
    2, 2, 2, 2, 4, 0, 7, 0,
    5, 7, 3, 7, 4, 0, 2, 0,
    7, 7, 7, 7, 7, 7, 0, 6,
    7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 0  -- Unused can be the same as lowest priority
  );

  function get_sync_xc_prio(cause : cause_type;
                            tval  : wordx) return integer is
    variable cause_i : integer := cause2int(cause);
    variable prio : integer;
  begin
    assert not is_irq(cause) report "Should not be called with IRQ type" severity failure;
    assert cause_i >= 0 and cause_i <= 63 report "Bad cause " & tost(cause_i) severity failure;

    prio := xc_prio(cause_i);
    assert prio /= 7 report "Unknown cause " & tost(cause_i);

    return prio;
  end function;

  function check_cause_update(new_cause  : cause_type;
                              prev_cause : cause_type;
                              tval       : wordx := zerox) return cause_type is
    variable intCause      : natural := new_cause.code;
    variable priority_new  : integer := get_sync_xc_prio(new_cause, tval);
    variable priority_prev : integer := get_sync_xc_prio(prev_cause, tval);
  begin
    assert priority_new >= priority_prev
      report "Overriding higher priority exception (" & tost(cause2int(prev_cause)) & ")" &
             " with lower priority (" & tost(cause2int(new_cause)) & ")" severity failure;

    return new_cause;
  end function;


  -- Return GPR name from register number (e.g. x1 -> ra).
  function to_reg(num : reg_t) return string is
    constant n : integer := u2i(num);
  begin
-- pragma translate_off
    case n is
    when 0 => return "zero";
    when 1 => return "ra";
    when 2 => return "sp";
    when 3 => return "gp";
    when 4 => return "tp";
    when 5 | 6 | 7 =>
              return "t" & tost(n - 5);
    when 8 => return "fp";  -- s0
    when 9 => return "s1";
    when 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 =>
              return "a" & tost(n - 10);
    when 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 =>
              return "s" & tost(n - 18 + 2);
    when 28 | 29 | 30 | 31 =>
              return "t" & tost(n - 28 + 3);
    when others =>
              return "error";
    end case;
-- pragma translate_on
    return "";
  end;

  -- Defined as in MISA
  constant rv : word2 := u2vec(log2(XLEN / 32) + 1, 2);

  function is_rv(len : integer; rv : word2) return boolean is
  begin
-- pragma translate_off
    if len /= 32 and len /= 64 and len /= 128 then
      assert false report "Bad XLEN (len)" severity failure;
    end if;
-- pragma translate_on

    case rv is
      when "01"   => return len = 32;
      when "10"   => return len = 64;
      when "11"   => return len = 128;
      when others =>
-- pragma translate_off
        assert false report "Bad XLEN (rv)" severity failure;
-- pragma translate_on
    end case;

    return false;
  end;


  -- Sign extend to 64 bit word.
  function to64(v : std_logic_vector) return word64 is
  begin
    assert v'length <= 64 report "Value does not fit in word64" severity failure;
    return sext(v, 64);
  end;

  -- Zero extend to wordx.
  function to0x(v : std_logic_vector) return wordx is
  begin
    assert v'length <= XLEN report "Value does not fit in wordx" severity failure;
    return uext(v, XLEN);
  end;

  function to0x(v : unsigned) return wordx is
  begin
    assert v'length <= XLEN report "Value does not fit in wordx" severity failure;
    return uext(v, XLEN);
  end;

  -- Mask with all the legal interrupts for ETRIGGER (when h_en = 0)
  constant etrigger_mask_value   : word32 := x"8000bbff";
  constant CSR_ETRIGGER_MASK     : wordx := to0x(etrigger_mask_value);
  -- Mask with all the hypervisor legal interrupts for ETRIGGER
  constant etrigger_h_mask_value : word32 := x"00F00400";
  constant CSR_H_ETRIGGER_MASK   : wordx  := to0x(etrigger_h_mask_value);


  -- Branch and jump generation
  procedure bjump_gen(active        : in  extension_type;
                      inst_in       : in  iword_tuple_type;
                      buffer_in     : in  iqueue_type;
                      bjump_pre     : in  std_logic_vector;
                      jump_pre      : in  std_logic_vector;
                      prediction    : in  prediction_array_type;
                      dvalid        : in  std_ulogic;
                      dpc_in        : in  std_logic_vector;  -- pctype
                      bjump_buf_out : out std_ulogic;  --bjump is from the buffer
                      bjump_out     : out std_ulogic;  --bjump is taken
                      btb_taken     : out std_ulogic;  --btb was taken
                      btb_taken_buf : out std_ulogic;  --btb was taken for buffer
                      bjump_pos     : out word4;
                      bjump_addr    : out std_logic_vector) is   -- pctype bjump addr
    subtype  pctype         is std_logic_vector(dpc_in'range);
    constant high_part       : std_logic_vector(pctype'high downto 12) := (others => '0');
    variable single_issue    : boolean := is_enabled(active, x_single_issue);
    -- Non-constant
    variable pc              : std_logic_vector(high_part'range);
    variable inst_word       : word64;
    variable br_imm0         : wordx;   --buffer immediate
    variable br_imm1         : wordx;   --cinst[15:0]
    variable br_imm2         : wordx;   --cinst[31:16]
    variable br_imm3         : wordx;   --cinst[47:32]
    variable br_imm4         : wordx;   --cinst[63:48]
    variable br_imm5         : wordx;   --inst[31:0]
    variable br_imm6         : wordx;   --inst[47 downto 16]
    variable br_imm7         : wordx;   --inst[63 downto 32]
    variable j_imm0          : wordx;   --buffer immediate
    variable j_imm1          : wordx;   --cinst[15:0]
    variable j_imm2          : wordx;   --cinst[31:16]
    variable j_imm3          : wordx;   --cinst[47:32]
    variable j_imm4          : wordx;   --cinst[63:48]
    variable j_imm5          : wordx;   --inst[31:0]
    variable j_imm6          : wordx;   --inst[47 downto 16]
    variable j_imm7          : wordx;   --inst[63 downto 32]
    variable mux_imm0        : wordx;
    variable mux_imm1        : wordx;
    variable mux_imm2        : wordx;
    variable mux_imm3        : wordx;
    variable mux_imm4        : wordx;
    variable mux_imm5        : wordx;
    variable mux_imm6        : wordx;
    variable mux_imm7        : wordx;
    variable mux_immf        : wordx;
    variable br_imm          : wordx_arr(0 to 7);
    variable j_imm           : wordx_arr(0 to 7);
    variable mux_imm         : wordx_arr(0 to 7);
    variable addlsb0         : std_logic_vector(12 downto 0);
    variable addlsb1         : std_logic_vector(12 downto 0);
    variable addlsb2         : std_logic_vector(12 downto 0);
    variable addlsb3         : std_logic_vector(12 downto 0);
    variable addlsb4         : std_logic_vector(12 downto 0);
    variable addlsb5         : std_logic_vector(12 downto 0);
    variable addlsb6         : std_logic_vector(12 downto 0);
    variable addlsb7         : std_logic_vector(12 downto 0);
    variable addlsbf         : std_logic_vector(12 downto 0);
    variable addlsb0_op1     : std_logic_vector(12 downto 0);
    variable addlsb0_op2     : std_logic_vector(12 downto 0);
    variable addlsb1_op1     : std_logic_vector(12 downto 0);
    variable addlsb1_op2     : std_logic_vector(12 downto 0);
    variable addlsb2_op1     : std_logic_vector(12 downto 0);
    variable addlsb2_op2     : std_logic_vector(12 downto 0);
    variable addlsb3_op1     : std_logic_vector(12 downto 0);
    variable addlsb3_op2     : std_logic_vector(12 downto 0);
    variable addlsb4_op1     : std_logic_vector(12 downto 0);
    variable addlsb4_op2     : std_logic_vector(12 downto 0);
    variable addlsb5_op1     : std_logic_vector(12 downto 0);
    variable addlsb5_op2     : std_logic_vector(12 downto 0);
    variable addlsb6_op1     : std_logic_vector(12 downto 0);
    variable addlsb6_op2     : std_logic_vector(12 downto 0);
    variable addlsb7_op1     : std_logic_vector(12 downto 0);
    variable addlsb7_op2     : std_logic_vector(12 downto 0);
    variable bjump0          : std_logic;
    variable bjump1          : std_logic;
    variable bjump2          : std_logic;
    variable bjump3          : std_logic;
    variable bjump4          : std_logic;
    variable bjump5          : std_logic;
    variable bjump6          : std_logic;
    variable bjump7          : std_logic;
    variable jump0           : std_logic;
    variable jump1           : std_logic;
    variable jump2           : std_logic;
    variable jump3           : std_logic;
    variable jump4           : std_logic;
    variable jump5           : std_logic;
    variable jump6           : std_logic;
    variable jump7           : std_logic;
    variable bj_taken        : std_logic;
    variable addrmsbt        : std_logic_vector(pctype'high downto 11);
    variable btb_hit         : word4;
    variable btaken          : word4;
    variable bjump_buf_out_v : std_logic;
    variable dpc_in_t        : word3;

  begin

    for i in 0 to 3 loop
      btb_hit(i) := prediction(i).hit;
      btaken(i)  := prediction(i).taken;
    end loop;
    bjump_pos     := (others => '0');
    btb_taken     := '0';
    btb_taken_buf := '0';

    inst_word := inst_in(1).d & inst_in(0).d;

    br_imm0              := (others => buffer_in.inst.d(31));
    br_imm0(11 downto 0) := buffer_in.inst.d(7) & buffer_in.inst.d(30 downto 25) & buffer_in.inst.d(11 downto 8) & '0';
    br_imm1              := (others => inst_word(12));
    br_imm1(7 downto 0)  := inst_word( 6 downto  5) & inst_word( 2) & inst_word(11 downto 10) & inst_word( 4 downto  3) & '0';
    br_imm2              := (others => inst_word(28));
    br_imm2(7 downto 0)  := inst_word(22 downto 21) & inst_word(18) & inst_word(27 downto 26) & inst_word(20 downto 19) & '0';
    br_imm3              := (others => inst_word(44));
    br_imm3(7 downto 0)  := inst_word(38 downto 37) & inst_word(34) & inst_word(43 downto 42) & inst_word(36 downto 35) & '0';
    br_imm4              := (others => inst_word(60));
    br_imm4(7 downto 0)  := inst_word(54 downto 53) & inst_word(50) & inst_word(59 downto 58) & inst_word(52 downto 51) & '0';
    br_imm5              := (others => inst_word(31));
    br_imm5(11 downto 0) := inst_word( 7) & inst_word(30 downto 25) & inst_word(11 downto  8) & '0';
    br_imm6              := (others => inst_word(47));
    br_imm6(11 downto 0) := inst_word(23) & inst_word(46 downto 41) & inst_word(27 downto 24) & '0';
    br_imm7              := (others => inst_word(63));
    br_imm7(11 downto 0) := inst_word(39) & inst_word(62 downto 57) & inst_word(43 downto 40) & '0';

    j_imm0              := (others => buffer_in.inst.d(31));
    j_imm0(19 downto 0) := buffer_in.inst.d(19 downto 12) & buffer_in.inst.d(20) & buffer_in.inst.d(30 downto 21) & '0';
    j_imm1              := (others => inst_word(12));
    j_imm1(10 downto 0) := inst_word( 8) & inst_word(10 downto  9) & inst_word( 6) & inst_word( 7) & inst_word( 2) & inst_word(11) & inst_word( 5 downto  3) & '0';
    j_imm2              := (others => inst_word(28));
    j_imm2(10 downto 0) := inst_word(24) & inst_word(26 downto 25) & inst_word(22) & inst_word(23) & inst_word(18) & inst_word(27) & inst_word(21 downto 19) & '0';
    j_imm3              := (others => inst_word(44));
    j_imm3(10 downto 0) := inst_word(40) & inst_word(42 downto 41) & inst_word(38) & inst_word(39) & inst_word(34) & inst_word(43) & inst_word(37 downto 35) & '0';
    j_imm4              := (others => inst_word(60));
    j_imm4(10 downto 0) := inst_word(56) & inst_word(58 downto 57) & inst_word(54) & inst_word(55) & inst_word(50) & inst_word(59) & inst_word(53 downto 51) & '0';
    j_imm5              := (others => inst_word(31));
    j_imm5(19 downto 0) := inst_word(19 downto 12) & inst_word(20) & inst_word(30 downto 21) & '0';
    j_imm6              := (others => inst_word(47));
    j_imm6(19 downto 0) := inst_word(35 downto 28) & inst_word(36) & inst_word(46 downto 37) & '0';
    j_imm7              := (others => inst_word(63));
    j_imm7(19 downto 0) := inst_word(51 downto 44) & inst_word(52) & inst_word(62 downto 53) & '0';

    mux_imm0   := br_imm0;
    if buffer_in.inst.d(2) = '1' then
      mux_imm0 := j_imm0;
    end if;

    mux_imm1   := br_imm1;
    if inst_word(14) = '0' then
      mux_imm1 := j_imm1;
    end if;

    mux_imm2   := br_imm2;
    if inst_word(30) = '0' then
      mux_imm2 := j_imm2;
    end if;

    mux_imm3   := br_imm3;
    if inst_word(46) = '0' then
      mux_imm3 := j_imm3;
    end if;

    mux_imm4   := br_imm4;
    if inst_word(62) = '0' then
      mux_imm4 := j_imm4;
    end if;

    mux_imm5   := br_imm5;
    if inst_word(2) = '1' then
      mux_imm5 := j_imm5;
    end if;

    mux_imm6   := br_imm6;
    if inst_word(18) = '1' then
      mux_imm6 := j_imm6;
    end if;

    mux_imm7   := br_imm7;
    if inst_word(34) = '1' then
      mux_imm7 := j_imm7;
    end if;

    addlsb0_op1   := '0' & buffer_in.pc(11 downto 0);
    addlsb0_op2   := '0' & mux_imm0(11 downto 0);
    addlsb0       := uadd(addlsb0_op1, addlsb0_op2);
    addlsb1_op1   := '0' & dpc_in(11 downto 3) & "000";
    if single_issue then
      addlsb1_op1 := '0' & dpc_in(11 downto 2) & "00";
    end if;
    addlsb1_op2   := '0' & mux_imm1(11 downto 0);
    addlsb1       := uadd(addlsb1_op1, addlsb1_op2);
    addlsb2_op1   := '0' & dpc_in(11 downto 3) & "010";
    if single_issue then
      addlsb2_op1 := '0' & dpc_in(11 downto 2) & "10";
    end if;
    addlsb2_op2   := '0' & mux_imm2(11 downto 0);
    addlsb2       := uadd(addlsb2_op1, addlsb2_op2);
    addlsb3_op1   := '0' & dpc_in(11 downto 3) & "100";
    addlsb3_op2   := '0' & mux_imm3(11 downto 0);
    addlsb3       := uadd(addlsb3_op1, addlsb3_op2);
    addlsb4_op1   := '0' & dpc_in(11 downto 3) & "110";
    addlsb4_op2   := '0' & mux_imm4(11 downto 0);
    addlsb4       := uadd(addlsb4_op1, addlsb4_op2);
    addlsb5_op1   := '0' & dpc_in(11 downto 3) & "000";
    if single_issue then
      addlsb5_op1 := '0' & dpc_in(11 downto 2) & "00";
    end if;
    addlsb5_op2   := '0' & mux_imm5(11 downto 0);
    addlsb5       := uadd(addlsb5_op1, addlsb5_op2);
    addlsb6_op1   := '0' & dpc_in(11 downto 3) & "010";
    addlsb6_op2   := '0' & mux_imm6(11 downto 0);
    addlsb6       := uadd(addlsb6_op1, addlsb6_op2);
    addlsb7_op1   := '0' & dpc_in(11 downto 3) & "100";
    addlsb7_op2   := '0' & mux_imm7(11 downto 0);
    addlsb7       := uadd(addlsb7_op1, addlsb7_op2);

    bjump1 := '0';
    bjump2 := '0';
    bjump3 := '0';
    bjump4 := '0';
    bjump5 := '0';
    bjump6 := '0';
    bjump7 := '0';
    jump0  := '0';
    jump1  := '0';
    jump2  := '0';
    jump3  := '0';
    jump4  := '0';
    jump5  := '0';
    jump6  := '0';
    jump7  := '0';

    -- C op=01 funct3=001 RV32 -> c.jal        jal x1,imm  (ret)
    -- C op=01 funct3=101      -> c.j          jal x0,imm  (jmp)
    -- C op=01 funct3=11x      -> c.beqz/bnez  beq/bne rs1',x0,imm
    if (inst_word(15 downto 13) = "001" and XLEN = 32) or inst_word(15 downto 13) = "101" or
       inst_word(15 downto 13) = "110" or inst_word(15 downto 13) = "111" then
      if inst_word(0) = '1' then
        bjump1 := '1';
      end if;
    end if;

    -- Together with the above - the unconditional C jumps
    if (inst_word(15 downto 13) = "001" and XLEN = 32) or inst_word(15 downto 13) = "101" then
      jump1 := '1';
    end if;

    if (inst_word(31 downto 29) = "001" and XLEN = 32) or inst_word(31 downto 29) = "101" or
       inst_word(31 downto 29) = "110" or inst_word(31 downto 29) = "111" then
      if inst_word(16) = '1' then
        bjump2 := '1';
      end if;
    end if;

    if (inst_word(31 downto 29) = "001" and XLEN = 32) or inst_word(31 downto 29) = "101" then
      jump2 := '1';
    end if;

    if (inst_word(47 downto 45) = "001" and XLEN = 32) or inst_word(47 downto 45) = "101" or
       inst_word(47 downto 45) = "110" or inst_word(47 downto 45) = "111" then
      if inst_word(32) = '1' then
        bjump3 := '1';
      end if;
    end if;

    if (inst_word(47 downto 45) = "001" and XLEN = 32) or inst_word(47 downto 45) = "101" then
      jump3 := '1';
    end if;

    if (inst_word(63 downto 61) = "001" and XLEN = 32) or inst_word(63 downto 61) = "101" or
       inst_word(63 downto 61) = "110" or inst_word(63 downto 61) = "111" then
      if inst_word(48) = '1' then
        bjump4 := '1';
      end if;
    end if;

    if (inst_word(63 downto 61) = "001" and XLEN = 32) or inst_word(63 downto 61) = "101" then
      jump4 := '1';
    end if;

    if inst_word(6 downto 5) = "11" and (inst_word(4 downto 2) = "000" or inst_word(4 downto 2) = "011") then
      bjump5 := '1';
      if inst_word(3) = '1' then
        jump5 := '1';
      end if;
    end if;

    if inst_word(22 downto 21) = "11" and (inst_word(20 downto 18) = "000" or inst_word(20 downto 18) = "011") then
      bjump6 := '1';
      if inst_word(19) = '1' then
        jump6 := '1';
      end if;
    end if;

    if inst_word(38 downto 37) = "11" and (inst_word(36 downto 34) = "000" or inst_word(36 downto 34) = "011") then
      bjump7 := '1';
      if inst_word(35) = '1' then
        jump7 := '1';
      end if;
    end if;

    -- Replace the above with precalculated versions
    bjump1 := bjump_pre(1);
    bjump2 := bjump_pre(2);
    bjump3 := bjump_pre(3);
    bjump4 := bjump_pre(4);
    bjump5 := bjump_pre(5);
    bjump6 := bjump_pre(6);
    bjump7 := bjump_pre(7);
    jump1  := jump_pre(1);
    jump2  := jump_pre(2);
    jump3  := jump_pre(3);
    jump4  := jump_pre(4);
    jump5  := jump_pre(5);
    jump6  := jump_pre(6);
    jump7  := jump_pre(7);


    addlsbf         := addlsb0;
    mux_immf        := mux_imm0;
    bj_taken        := '0';
    bjump_buf_out_v := '0';
    dpc_in_t(2 downto 1) := dpc_in(2 downto 1);
    if single_issue then
      dpc_in_t(2)   := '0';
    end if;
    if buffer_in.valid = '1' and buffer_in.prediction.taken = '1' and buffer_in.bjump = '1' and buffer_in.bjump_predicted = '0' then
      -- Buffer always contains the oldest instruction
      addlsbf           := addlsb0;
      mux_immf          := mux_imm0;
      if buffer_in.prediction.hit = '0' then
        bj_taken        := '1';
        bjump_buf_out_v := '1';
      else
        btb_taken       := '1';
        btb_taken_buf   := '1';
      end if;
    elsif dvalid = '1' then
      case dpc_in_t(2 downto 1) is
        when "00" =>
          -- Not Compressed instruction in [31:0]
          if inst_word(1 downto 0) = "11" then
            if bjump5 = '1' and (btaken(0) = '1' or jump5 = '1') then
              addlsbf      := addlsb5;
              mux_immf     := mux_imm5;
              if btb_hit(0) = '0' then
                bj_taken   := '1';
              else
                btb_taken  := '1';
              end if;
              bjump_pos(0) := '1';
            else
              if inst_word(33 downto 32) = "11" then
                -- Not Compressed instruction in [63:32]
                if bjump7 = '1' and (btaken(2) = '1' or jump7 = '1') and not single_issue then
                  addlsbf      := addlsb7;
                  mux_immf     := mux_imm7;
                  if btb_hit(2) = '0' then
                    bj_taken   := '1';
                  else
                    btb_taken  := '1';
                  end if;
                  bjump_pos(2) := '1';
                end if;
              else
                -- Compressed instruction in [47:32]
                if bjump3 = '1' and (btaken(2) = '1' or jump3 = '1') and not single_issue then
                  addlsbf      := addlsb3;
                  mux_immf     := mux_imm3;
                  if btb_hit(2) = '0' then
                    bj_taken   := '1';
                  else
                    btb_taken  := '1';
                  end if;
                  bjump_pos(2) := '1';
                elsif inst_word(49 downto 48) /= "11" then
                  -- Compressed instruction in [63:48]
                  if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') and not single_issue then
                    addlsbf      := addlsb4;
                    mux_immf     := mux_imm4;
                    if btb_hit(3) = '0' then
                      bj_taken   := '1';
                    else
                      btb_taken  := '1';
                    end if;
                    bjump_pos(3) := '1';
                  end if;
                end if;
              end if;  -- inst_word(33 downto 32) = "11" then
            end if;  -- bjump5 = '1' and btb_hit(0) = '0' and btaken(0) = '1'
          else
            -- Compressed instruction in [16:0]
            if bjump1 = '1' and (btaken(0) = '1' or jump1 = '1') then
              addlsbf      := addlsb1;
              mux_immf     := mux_imm1;
              if btb_hit(0) = '0' then
                bj_taken   := '1';
              else
                btb_taken  := '1';
              end if;
              bjump_pos(0) := '1';
            else
              if inst_word(17 downto 16) = "11" then
                -- Not compressed instruction in [47:16]
                if bjump6 = '1' and (btaken(1) = '1' or jump6 = '1') and not single_issue then
                  addlsbf      := addlsb6;
                  mux_immf     := mux_imm6;
                  if btb_hit(1) = '0' then
                    bj_taken   := '1';
                  else
                    btb_taken  := '1';
                  end if;
                  bjump_pos(1) := '1';
                elsif inst_word(49 downto 48) /= "11" then
                  -- Compressed instruction in [63:48]
                  if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') and not single_issue then
                    addlsbf      := addlsb4;
                    mux_immf     := mux_imm4;
                    if btb_hit(3) = '0' then
                      bj_taken   := '1';
                    else
                      btb_taken  := '1';
                    end if;
                    bjump_pos(3) := '1';
                  end if;
                end if;
              else
                -- Compressed instruction in [32:16]
                if bjump2 = '1'and (btaken(1) = '1' or jump2 = '1') and not single_issue then
                  addlsbf      := addlsb2;
                  mux_immf     := mux_imm2;
                  if btb_hit(1) = '0' then
                    bj_taken   := '1';
                  else
                    btb_taken  := '1';
                  end if;
                  bjump_pos(1) := '1';
                else
                  if inst_word(33 downto 32) = "11" then
                    -- Not Compressed instruction in [63:32]
                    if bjump7 = '1' and btaken(2) = '1' and not single_issue then
                      addlsbf      := addlsb7;
                      mux_immf     := mux_imm7;
                      if btb_hit(2) = '0' then
                        bj_taken   := '1';
                      else
                        btb_taken  := '1';
                      end if;
                      bjump_pos(2) := '1';
                    end if;
                  else
                    -- Compressed instruction in [47:32]
                    if bjump3 = '1' and (btaken(2) = '1' or jump3 = '1') and not single_issue then
                      addlsbf      := addlsb3;
                      mux_immf     := mux_imm3;
                      if btb_hit(2) = '0' then
                        bj_taken   := '1';
                      else
                        btb_taken  := '1';
                      end if;
                      bjump_pos(2) := '1';
                    elsif inst_word(49 downto 48) /= "11" then
                      -- Compressed instruction in [63:48]
                      if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') and not single_issue then
                        addlsbf      := addlsb4;
                        mux_immf     := mux_imm4;
                        if btb_hit(3) = '0' then
                          bj_taken   := '1';
                        else
                          btb_taken  := '1';
                        end if;
                        bjump_pos(3) := '1';
                      end if;
                    end if;
                  end if;
                end if;
              end if;  -- inst_word(17 downto 16) = "11" then
            end if;  -- bjump1 = '1' and btb_hit(0) = '0' and btaken(0) = '1'
          end if;  -- inst_word(1 downto 0) = "11" then                     --

        when "01" =>
          if inst_word(17 downto 16) = "11" then
            -- Not compressed instruction in [47:16]
            if bjump6 = '1' and (btaken(1) = '1' or jump6 = '1') and not single_issue then
              addlsbf      := addlsb6;
              mux_immf     := mux_imm6;
              if btb_hit(1) = '0' then
                bj_taken   := '1';
              else
                btb_taken  := '1';
              end if;
              bjump_pos(1) := '1';
            elsif inst_word(49 downto 48) /= "11" then
              -- Compressed instruction in [63:48]
              if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') and not single_issue then
                addlsbf      := addlsb4;
                mux_immf     := mux_imm4;
                if btb_hit(3) = '0' then
                  bj_taken   := '1';
                else
                  btb_taken  := '1';
                end if;
                bjump_pos(3) := '1';
              end if;
            end if;
          else
            -- Compressed instruction in [32:16]
            if bjump2 = '1' and (btaken(1) = '1' or jump2 = '1') then
              addlsbf      := addlsb2;
              mux_immf     := mux_imm2;
              if btb_hit(1) = '0' then
                bj_taken   := '1';
              else
                btb_taken  := '1';
              end if;
              bjump_pos(1) := '1';
            else
              if not single_issue then
                if inst_word(33 downto 32) = "11" then
                  -- Not compressed instruction in [63:32]
                  if bjump7 = '1' and (btaken(2) = '1' or jump7 = '1') and not single_issue then
                    addlsbf      := addlsb7;
                    mux_immf     := mux_imm7;
                    if btb_hit(2) = '0' then
                      bj_taken   := '1';
                    else
                      btb_taken  := '1';
                    end if;
                    bjump_pos(2) := '1';
                  end if;
                else
                  -- Compressed instruction in [47:32]
                  if bjump3 = '1' and (btaken(2) = '1' or jump3 = '1') and not single_issue then
                    addlsbf      := addlsb3;
                    mux_immf     := mux_imm3;
                    if btb_hit(2) = '0' then
                      bj_taken   := '1';
                    else
                      btb_taken  := '1';
                    end if;
                    bjump_pos(2) := '1';
                  elsif inst_word(49 downto 48) /= "11" then
                    -- Compressed instruction in [63:48]
                    if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') and not single_issue then
                      addlsbf      := addlsb4;
                      mux_immf     := mux_imm4;
                      if btb_hit(3) = '0' then
                        bj_taken   := '1';
                      else
                        btb_taken  := '1';
                      end if;
                      bjump_pos(3) := '1';
                    end if;
                  end if;
                end if;
              end if;
            end if;  -- bjump2 = '1' and btb_hit(1) = '0' and btaken(1) = '1' then
          end if;  -- inst_word(17 downto 16) = "11" then

        when "10" =>
          if not single_issue then
            if inst_word(33 downto 32) = "11" then
              -- Not compressed instruction in [63:32]
              if bjump7 = '1' and (btaken(2) = '1' or jump7 = '1') then
                addlsbf      := addlsb7;
                mux_immf     := mux_imm7;
                if btb_hit(2) = '0' then
                  bj_taken   := '1';
                else
                  btb_taken  := '1';
                end if;
                bjump_pos(2) := '1';
              end if;
            else
              -- Comressed instruction in [47:32]
              if bjump3 = '1' and (btaken(2) = '1' or jump3 = '1') then
                addlsbf      := addlsb3;
                mux_immf     := mux_imm3;
                if btb_hit(2) = '0' then
                  bj_taken   := '1';
                else
                  btb_taken  := '1';
                end if;
                bjump_pos(2) := '1';
              elsif inst_word(49 downto 48) /= "11" then
                -- Compressed instruction in [63:48]
                if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') then
                  addlsbf      := addlsb4;
                  mux_immf     := mux_imm4;
                  if btb_hit(3) = '0' then
                    bj_taken   := '1';
                  else
                    btb_taken  := '1';
                  end if;
                  bjump_pos(3) := '1';
                end if;
              end if;
            end if;  -- inst_word(34 downto 33) = "11"
          else
            null;
          end if;  -- not single_issue

        when others =>
          if not single_issue then
            if inst_word(49 downto 48) /= "11" then
              -- Compressed instruction in [63:48]
              if bjump4 = '1' and (btaken(3) = '1' or jump4 = '1') then
                addlsbf      := addlsb4;
                mux_immf     := mux_imm4;
                if btb_hit(3) = '0' then
                  bj_taken   := '1';
                else
                  btb_taken  := '1';
                end if;
                bjump_pos(3) := '1';
              end if;
            end if;
          else
            null;
          end if;  -- not single_issue

      end case;
    end if;

    -- Since the incoming PC values are guaranteed to be "canonical"
    -- (as in OK virtual or physical addresses), any add that would
    -- overflow into higher bits will be visible (and fault on access).
    if bjump_buf_out_v = '1' then
      pc          := buffer_in.pc(high_part'range);
    else
      pc          := dpc_in(high_part'range);
    end if;
    addrmsbt      := uadd(pc & '1', mux_immf(high_part'range) & addlsbf(12));
    bjump_addr    := addrmsbt(high_part'range) & addlsbf(11 downto 0);
    bjump_out     := bj_taken;
    bjump_buf_out := bjump_buf_out_v;
  end;

  -- Branch and jump generation
  procedure bjump_pregen(inst_word : in  word64;
                         buffer_in : in  iqueue_type;
                         bjump_out : out std_logic_vector;
                         jump_out  : out std_logic_vector) is
    -- Non-constant
    variable br_imm          : wordx_arr(0 to 7);
    variable j_imm           : wordx_arr(0 to 7);
    variable mux_imm         : wordx_arr(0 to 7);
    variable xbjump           : std_logic_vector(1 to 7);
    variable xjump            : std_logic_vector(1 to 7);

    -- 11+1 bit
    function br_imm0567(inst : word64; start : integer) return wordx is
      -- Non-constant
      variable imm : wordx := (others => inst(start + 31));
    begin
      imm(11 downto 11) := get(inst, start +  7, 1);
      imm(10 downto  5) := get(inst, start + 25, 6);
      imm( 4 downto  1) := get(inst, start +  8, 4);
      imm( 0)           := '0';

      return imm;
    end;

    -- 7+1 bit
    function br_imm1234(inst : word64; start : integer) return wordx is
      -- Non-constant
      variable imm : wordx := (others => inst(start + 12));
    begin
      imm(7 downto 6) := get(inst, start +  5, 2);
      imm(5 downto 5) := get(inst, start +  2, 1);
      imm(4 downto 3) := get(inst, start + 10, 2);
      imm(2 downto 1) := get(inst, start +  3, 2);
      imm(0)          := '0';

      return imm;
    end;

    -- 19+1 bit
    function j_imm0567(inst : word64; start : integer) return wordx is
      -- Non-constant
      variable imm : wordx := (others => inst(start + 31));
    begin
      imm(19 downto 12) := get(inst, start + 12,  8);
      imm(11 downto 11) := get(inst, start + 20,  1);
      imm(10 downto  1) := get(inst, start + 21, 10);
      imm( 0)           := '0';

      return imm;
    end;

    -- 10+1 bit
    function j_imm1234(inst : word64; start : integer) return wordx is
      -- Non-constant
      variable imm : wordx := (others => inst(start + 12));
    begin
      imm(10 downto 10) := get(inst, start +  8, 1);
      imm( 9 downto  8) := get(inst, start +  9, 2);
      imm( 7 downto  7) := get(inst, start +  6, 1);
      imm( 6 downto  6) := get(inst, start +  7, 1);
      imm( 5 downto  5) := get(inst, start +  2, 1);
      imm( 4 downto  4) := get(inst, start + 11, 1);
      imm( 3 downto  1) := get(inst, start +  3, 3);
      imm( 0)           := '0';

      return imm;
    end;

    -- Is it a compressed unconditional jump?
    -- Assumes that other code checks C and op (see below)!
    -- C op=01 funct3=001 RV32 -> c.jal        jal x1,imm  (ret)
    -- C op=01 funct3=101      -> c.j          jal x0,imm  (jmp)
    function cjump(inst : word64; start : integer) return std_logic is
    begin
      if (inst(start + 15 downto start + 13) = "001" and XLEN = 32) or
         inst(start + 15 downto start + 13) = "101" then
        return '1';
      end if;

      return '0';
    end;
    -- Is it a compressed conditional or unconditional jump?
    -- See above.
    -- C op=01 funct3=11x      -> c.beqz/bnez  beq/bne rs1',x0,imm
    function cbjump(inst : word64; start : integer) return std_logic is
    begin
      if cjump(inst, start) = '1' or
         inst(start + 15 downto start + 13) = "110" or
         inst(start + 15 downto start + 13) = "111" then
        if inst(start + 0) = '1' then
          return '1';
        end if;
      end if;

      return '0';
    end;
    -- Is it a (not compressed) conditional or unconditional jump?
    -- Assumes other code checks for non-compressed!
    function bjump(inst : word64; start : integer) return std_logic is
    begin
      if inst(start + 6 downto start + 5) = "11" and
         (inst(start + 4 downto start + 2) = "000" or     -- OP_BRANCH
          inst(start + 4 downto start + 2) = "011") then  -- OP_JAL
        return '1';
      end if;

      return '0';
    end;
    -- Is it an (not compressed) unconditional jump (OP_JAL)?
    function jump(inst : word64; start : integer) return std_logic is
    begin
      if bjump(inst, start) = '1' and inst(start + 3) = '1' then
        return '1';
      end if;

      return '0';
    end;
  begin
--    inst_word := inst_in(1).d & inst_in(0).d;

    br_imm(0) := br_imm0567(to64(buffer_in.inst.d), 0);
    br_imm(1) := br_imm1234(inst_word,  0);
    br_imm(2) := br_imm1234(inst_word, 16);
    br_imm(3) := br_imm1234(inst_word, 32);
    br_imm(4) := br_imm1234(inst_word, 48);
    br_imm(5) := br_imm0567(inst_word,  0);
    br_imm(6) := br_imm0567(inst_word, 16);
    br_imm(7) := br_imm0567(inst_word, 32);

    j_imm(0)  := j_imm0567(to64(buffer_in.inst.d), 0);
    j_imm(1)  := j_imm1234(inst_word,  0);
    j_imm(2)  := j_imm1234(inst_word, 16);
    j_imm(3)  := j_imm1234(inst_word, 32);
    j_imm(4)  := j_imm1234(inst_word, 48);
    j_imm(5)  := j_imm0567(inst_word,  0);
    j_imm(6)  := j_imm0567(inst_word, 16);
    j_imm(7)  := j_imm0567(inst_word, 32);

    mux_imm(0)   := br_imm(0);
    if buffer_in.inst.d(2) = '1' then
      mux_imm(0) := j_imm(0);
    end if;

    mux_imm(1)   := br_imm(1);
    if inst_word(14) = '0' then
      mux_imm(1) := j_imm(1);
    end if;

    mux_imm(2)   := br_imm(2);
    if inst_word(30) = '0' then
      mux_imm(2) := j_imm(2);
    end if;

    mux_imm(3)   := br_imm(3);
    if inst_word(46) = '0' then
      mux_imm(3) := j_imm(3);
    end if;

    mux_imm(4)   := br_imm(4);
    if inst_word(62) = '0' then
      mux_imm(4) := j_imm(4);
    end if;

    mux_imm(5)   := br_imm(5);
    if inst_word(2) = '1' then
      mux_imm(5) := j_imm(5);
    end if;

    mux_imm(6)   := br_imm(6);
    if inst_word(18) = '1' then
      mux_imm(6) := j_imm(6);
    end if;

    mux_imm(7)   := br_imm(7);
    if inst_word(34) = '1' then
      mux_imm(7) := j_imm(7);
    end if;

    xbjump(1) := cbjump(inst_word,  0);
    xjump(1)  := cjump(inst_word,   0);
    xbjump(2) := cbjump(inst_word, 16);
    xjump(2)  := cjump(inst_word,  16);
    xbjump(3) := cbjump(inst_word, 32);
    xjump(3)  := cjump(inst_word,  32);
    xbjump(4) := cbjump(inst_word, 48);
    xjump(4)  := cjump(inst_word,  48);
    xbjump(5) := bjump(inst_word,   0);
    xjump(5)  := jump(inst_word,    0);
    xbjump(6) := bjump(inst_word,  16);
    xjump(6)  := jump(inst_word,   16);
    xbjump(7) := bjump(inst_word,  32);
    xjump(7)  := jump(inst_word,   32);

    bjump_out := xbjump;
    jump_out  := xjump; 
  end;

  procedure rvc_expander(active   : in  extension_type;
                         inst_in  : in  word16;
                         fpu_en   : in  boolean;
                         inst_out : out word;
                         xc_out   : out std_ulogic) is
    variable is_rv64     : boolean := is_enabled(active, x_rv64);
    variable is_rv32     : boolean := not is_rv64;
    variable ext_f       : boolean := is_enabled(active, x_f);
    variable ext_d       : boolean := is_enabled(active, x_d);
    variable ext_m       : boolean := is_enabled(active, x_m);
    variable ext_zba     : boolean := is_enabled(active, x_zba);
    variable ext_zbb     : boolean := is_enabled(active, x_zbb);
    variable ext_zcb     : boolean := is_enabled(active, x_zcb);
    variable ext_zcmop   : boolean := is_enabled(active, x_zcmop);
    variable ext_zicfiss : boolean := is_enabled(active, x_zicfiss);
    -- Evaluate compressed instruction
    variable op     : word2                         := inst_in( 1 downto  0);
    variable funct2 : funct2_type                   := inst_in( 6 downto  5);
    variable funct3 : funct3_type                   := inst_in(15 downto 13);
    -- Evaluate imm sign-extension, MSB of imm is always bit 12th.
    variable imm12  : std_logic_vector(11 downto 0) := (others => inst_in(12));
    variable rfa1   : reg_t                         := inst_in(11 downto  7);
    variable rfa2   : reg_t                         := inst_in( 6 downto  2);
    variable rd     : reg_t                         := inst_in(11 downto  7);
    variable rfa1c  : reg_t                         := "01" & inst_in(9 downto 7);
    variable rfa2c  : reg_t                         := "01" & inst_in(4 downto 2);
    variable rdc    : reg_t                         := "01" & inst_in(4 downto 2);
    -- Non-constant
    variable inst   : word;
    variable xc     : std_ulogic                    := '0';
  begin

    -- Default to a simple illegal instruction.
    -- All illegals below set the same.
    inst := zerow;

    -- Expand instruction
    case op is

      -- C0
      when "00" =>
        case funct3 is

          -- c.addi4spn -> addi rd', x2, imm
          when "000" =>
            inst := "00" &                   -- imm[11:10]
                    inst_in(10 downto 7) &   -- imm[9:6]
                    inst_in(12 downto 11) &  -- imm[5:4]
                    inst_in(5) &             -- imm[3]
                    inst_in(6) &             -- imm[2]
                    "00" &                   -- imm[1:0]
                    GPR_SP &                 -- rs1
                    I_ADDI &                 -- funct3
                    rdc &                    -- rd
                    OP_IMM;                  -- addi
            -- imm = 0 are reserved by the standard.
            if inst_in(12 downto 5) = "00000000" then
              xc := '1';
              inst := zerow;
            end if;

          -- c.fld -> fld rd', imm(rs1')
          when "001" =>
              inst := "0000" &                 -- imm[11:8]
                      inst_in(6 downto 5) &    -- imm[7:6]
                      inst_in(12 downto 10) &  -- imm[5:3]
                      "000" &                  -- imm[2:0]
                      rfa1c &                  -- rs1
                      I_FLD &                  -- funct3
                      rdc &                    -- rd
                      OP_LOAD_FP;              -- fld
            if not ext_d or not fpu_en then
              xc := '1';
              inst := zerow;
            end if;

          -- c.lw -> lw rd', imm(rs1')
          when "010" =>
            inst := "00000" &                -- imm[11:7]
                    inst_in(5) &             -- imm[6]
                    inst_in(12 downto 10) &  -- imm[5:3]
                    inst_in(6) &             -- imm[2]
                    "00" &                   -- imm[1:0]
                    rfa1c &                  -- rs1
                    I_LW &                   -- funct3
                    rdc &                    -- rd
                    OP_LOAD;                 -- lw

          -- c.flw
          -- c.ld
          when "011" =>
            -- c.flw -> flw rd', imm(rs1')
            if is_rv32 and ext_f then
              inst := "00000" &                -- imm[11:7]
                      inst_in(5) &             -- imm[6]
                      inst_in(12 downto 10) &  -- imm[5:3]
                      inst_in(6) &             -- imm[2]
                      "00" &                   -- imm[1:0]
                      rfa1c &                  -- rs1
                      I_FLW &                  -- funct3
                      rdc &                    -- rd
                      OP_LOAD_FP;              -- flw
              if not fpu_en then
                xc := '1';
                inst := zerow;
              end if;
            -- c.ld -> ld rd', imm(rs1')
            elsif is_rv64 then
              inst := "0000" &                 -- imm[11:8]
                      inst_in(6 downto 5) &    -- imm[7:6]
                      inst_in(12 downto 10) &  -- imm[5:3]
                      "000" &                  -- imm[2:0]
                      rfa1c &                  -- rs1
                      I_LD &                   -- funct3
                      rdc &                    -- rd
                      OP_LOAD;                 -- ld
            else
              xc := '1';
              inst := zerow;
            end if;

          when "100" =>
            if ext_zcb then
              case inst_in(12 downto 10) is
                -- c.lbu -> lbu rd', uimm(rs1')
                when "000" =>
                  inst := "0000000000" &           -- imm[11:2]
                          inst_in(5) &             -- imm[1]
                          inst_in(6) &             -- imm[0]
                          rfa1c &                  -- rs1
                          I_LBU &                  -- funct3
                          rdc &                    -- rd
                          OP_LOAD;                 -- lbu
                when "001" =>
                  -- c.lhu -> lhu rd', uimm(rs1')
                  if inst_in(6) = '0' then
                    inst := "0000000000" &           -- imm[11:2]
                            inst_in(5) &             -- imm[1]
                            "0" &                    -- imm[0]
                            rfa1c &                  -- rs1
                            I_LHU &                  -- funct3
                            rdc &                    -- rd
                            OP_LOAD;                 -- lhu
                  -- c.lh -> lh rd', uimm(rs1')
                  else
                    inst := "0000000000" &           -- imm[11:2]
                            inst_in(5) &             -- imm[1]
                            "0" &                    -- imm[0]
                            rfa1c &                  -- rs1
                            I_LH &                   -- funct3
                            rdc &                    -- rd
                            OP_LOAD;                 -- lh
                  end if;
                -- c.sb -> sb rs2', uimm(rs1')
                when "010" =>
                  inst := "0000000" &              -- imm[11:5]
                          rfa2c &                  -- rs2
                          rfa1c &                  -- rs1
                          S_SB &                   -- funct3
                          "000" &                  -- imm[4:2]
                          inst_in(5) &             -- imm[1]
                          inst_in(6) &             -- imm[0]
                          OP_STORE;                -- sb
                when "011" =>
                  -- c.sh -> sh rs2', uimm(rs1')
                  if inst_in(6) = '0' then
                    inst := "0000000" &              -- imm[11:5]
                            rfa2c &                  -- rs2
                            rfa1c &                  -- rs1
                            S_SH &                   -- funct3
                            "000" &                  -- imm[4:2]
                            inst_in(5) &             -- imm[1]
                            "0" &                    -- imm[0]
                            OP_STORE;                -- sh
                  else
                    xc := '1';
                    inst := zerow;
                  end if;
                when others =>
                  xc := '1';
                  inst := zerow;
              end case;
            else
              xc := '1';
              inst := zerow;
            end if;

          -- c.fsd -> fsd rs2', imm(rs1')
          when "101" =>
            if ext_d and fpu_en then
              inst := "0000" &                 -- imm[11:8]
                      inst_in(6 downto 5) &    -- imm[7:6]
                      inst_in(12) &            -- imm[5]
                      rfa2c &                  -- rs2
                      rfa1c &                  -- rs1
                      S_FSD &                  -- funct3
                      inst_in(11 downto 10) &  -- imm[4:3]
                      "000" &                  -- imm[2:0]
                      OP_STORE_FP;             -- fsd
            else
              xc := '1';
              inst := zerow;
            end if;

          -- c.sw -> sw rs2', imm(rs1')
          when "110" =>
            inst := "00000" &                -- imm[11:7]
                    inst_in(5) &             -- imm[6]
                    inst_in(12) &            -- imm[5]
                    rfa2c &                  -- rs2
                    rfa1c &                  -- rs1
                    S_SW &                   -- funct3
                    inst_in(11 downto 10) &  -- imm[4:3]
                    inst_in(6) &             -- imm[2]
                    "00" &                   -- imm[1:0]
                    OP_STORE;                -- sw
          -- c.fsw
          -- c.sd
          when others =>
            -- c.fsw -> fsw rs2', imm(rs1')
            if is_rv32 and ext_f then
              inst := "00000" &                -- imm[11:7]
                      inst_in(5) &             -- imm[6]
                      inst_in(12) &            -- imm[5]
                      rfa2c &                  -- rs2
                      rfa1c &                  -- rs1
                      S_FSW &                  -- funct3
                      inst_in(11 downto 10) &  -- imm[4:3]
                      inst_in(6) &             -- imm[2]
                      "00" &                   -- imm[1:0]
                      OP_STORE_FP;             -- fsw
              if not fpu_en then
                xc := '1';
                inst := zerow;
              end if;
            -- c.sd -> sd rs2', imm(rs1')
            elsif is_rv64 then
              inst := "0000" &                 -- imm[11:8]
                      inst_in(6 downto 5) &    -- imm[7:6]
                      inst_in(12) &            -- imm[5]
                      rfa2c &                  -- rs2
                      rfa1c &                  -- rs1
                      S_SD &                   -- funct3
                      inst_in(11 downto 10) &  -- imm[4:3]
                      "000" &                  -- imm[2:0]
                      OP_STORE;                -- sd
            else
              xc := '1';
              inst := zerow;
            end if;
        end case;  -- funct3

      -- C1
      when "01" =>
        case funct3 is

          -- c.nop -> addi x0, x0, 0
          -- c.addi -> addi rd, rd, imm
          when "000" =>
            inst := imm12(11 downto 6) &   -- imm[11:6]
                    inst_in(12) &          -- imm[5]
                    inst_in(6 downto 2) &  -- imm[4:0]
                    rfa1 &                 -- rs1
                    I_ADDI &               -- funct3
                    rd &                   -- rd
                    OP_IMM;                -- addi
            -- For the c.nop case, imm /= 0 are standard HINTs.
            -- For the c.addi case, imm = 0 are standard HINTs.

          -- c.jal
          -- c.addiw
          when "001" =>
            if is_rv32 then
              -- c.jal -> jal x1, imm
              inst := inst_in(12) &           -- imm[20]
                      inst_in(8) &            -- imm[10]
                      inst_in(10 downto 9) &  -- imm[9:8]
                      inst_in(6) &            -- imm[7]
                      inst_in(7) &            -- imm[6]
                      inst_in(2) &            -- imm[5]
                      inst_in(11) &           -- imm[4]
                      inst_in(5 downto 3) &   -- imm[3:1]
                      inst_in(12) &           -- imm[11]
                      imm12(11 downto 4) &    -- imm[19:12]
                      GPR_RA &                -- rd
                      OP_JAL;                 -- jal
            else
              -- c.addiw -> addiw rd, rd, imm
              inst := imm12(11 downto 6) &    -- imm[11:6]
                      inst_in(12) &           -- imm[5]
                      inst_in(6 downto 2) &   -- imm[4:0]
                      rfa1 &                  -- rs1
                      I_ADDI &                -- funct3
                      rd &                    -- rd
                      OP_IMM_32;              -- addi
              -- rd = x0 are reserved by the standard.
              if rd = "00000" then
                xc := '1';
                inst := zerow;
              end if;
            end if;

          -- c.li -> addi rd, x0, imm
          when "010" =>
            inst := imm12(11 downto 6) &   -- imm[11:6]
                    inst_in(12) &          -- imm[5]
                    inst_in(6 downto 2) &  -- imm[4:0]
                    GPR_X0 &               -- rs1
                    I_ADDI &               -- funct3
                    rd &                   -- rd
                    OP_IMM;                -- addi
            -- rd = x0 are standard HINTs.

          -- c.addi16sp
          -- c.lui
          -- c.mop.0-7
          -- c.sspush / c.sspopchk
          when "011" =>
            if rd = GPR_SP then
              -- c.addi16sp -> addi x2, x2, imm
              inst := imm12(11 downto 10) &  -- imm[11:10]
                      inst_in(12) &          -- imm[9]
                      inst_in(4 downto 3) &  -- imm[8:7]
                      inst_in(5) &           -- imm[6]
                      inst_in(2) &           -- imm[5]
                      inst_in(6) &           -- imm[4]
                      "0000" &               -- imm[3:0]
                      GPR_SP &               -- rs1
                      I_ADDI &               -- funct3
                      GPR_SP &               -- rd
                      OP_IMM;                -- addi
            else
              -- rd = x0, imm /= 0 are standard HINTs.
              -- c.lui -> lui rd, imm
              inst := imm12 &                -- imm[31:20]
                      imm12(11 downto 10) &  -- imm[19:18]
                      inst_in(12) &          -- imm[17]
                      inst_in(6 downto 2) &  -- imm[16:12]
                      rd &                   -- rd
                      LUI;                   -- lui
            end if;
            -- c.addi16sp and c.lui are reserved with imm = 0.
            if inst_in(12) = '0' and rfa2 = "00000" then
              xc     := '1';
              inst := zerow;
              -- But c.mop comes in here (x1/3/5/7/9/11/13/15).
              if ext_zcmop and rfa1(0) = '1' and rfa1(4) = '0' then
                xc   := '0';
                inst := "000000000000" &
                        "00000" &        -- rs1
                        I_ADDI &         -- funct3
                        "00000" &        -- rd
                        OP_IMM;          -- addi x0, x0, 0 (nop)
                if ext_zicfiss then
                  if    rfa1 = "00001" then
                    inst := F7_SSPUSH &
                            "00001" &        -- rs2
                            "00000" &        -- rs1
                            R_XOR &          -- funct3
                            "00000" &        -- rd
                            OP_SYSTEM;       -- sspush x1
                  elsif rfa1 = "00101" then
                    inst := F12_SSRDPOPCHK &
                            "00101" &        -- rs1
                            R_XOR &          -- funct3
                            "00000" &        -- rd
                            OP_SYSTEM;       -- sspopchk x5
                  end if;
                end if;
              end if;
            end if;

          -- ALU
          when "100" =>
            case inst_in(11 downto 10) is

              -- c.srli -> srli rd', rs1', shamt
              -- c.srai -> srai rd', rs1', shamt
              when "00" | "01" =>
                inst := inst_in(11 downto 10) &  -- funct7[6:5]
                        "0000" &                 -- funct7[4:1]
                        inst_in(12) &            -- shamt[5]
                        inst_in(6 downto 2) &    -- shamt[4:0]
                        rfa1c &                  -- rs1
                        I_SRLI &                 -- funct3
                        rfa1c &                  -- rd
                        OP_IMM;                  -- srli/srai
                -- For RV32, the code points with the high bit set
                -- are designated for custom extensions.
                if is_rv32 and inst_in(12) = '1' then
                  xc := '1';
                  inst := zerow;
                end if;
                -- shamt = 0 are custom HINTs.

              -- c.andi -> andi rd', rs1', imm
              when "10" =>
                inst := imm12(11 downto 6) &   -- imm[11:6]
                        inst_in(12) &          -- imm[5]
                        inst_in(6 downto 2) &  -- imm[4:0]
                        rfa1c &                -- rs1
                        I_ANDI &               -- funct3
                        rfa1c &                -- rd
                        OP_IMM;                -- andi

              -- misc
              when others =>
                case funct2 is

                  -- c.sub[w] -> sub[w] rd', rs1', rs2'
                  when "00" =>
                    inst := F7_SUB &    -- funct7
                            rfa2c &     -- rs2
                            rfa1c &     -- rs1
                            R_SUB &     -- funct3
                            rfa1c &     -- rd
                            OP_REG;     -- sub
                    if inst_in(12) = '1' then
                      if is_rv64 then
                        inst(6 downto 0) := OP_32;
                      else
                        xc := '1';
                        inst := zerow;
                      end if;
                    end if;

                  -- c.xor -> xor rd', rs1', rs2'
                  -- c.addw -> addw rd', rs1', rs2'
                  when "01" =>
                    inst := F7_BASE &   -- funct7
                            rfa2c &     -- rs2
                            rfa1c &     -- rs1
                            R_XOR &     -- funct3
                            rfa1c &     -- rd
                            OP_REG;     -- sub
                    if inst_in(12) = '1' then
                      if is_rv64 then
                        inst(14 downto 12) := R_ADDW;
                        inst(6 downto 0)   := OP_32;
                      else
                        xc := '1';
                        inst := zerow;
                      end if;
                    end if;

                  -- c.or -> or rd', rs1', rs2'
                  when "10" =>
                    inst := F7_BASE &   -- funct7
                            rfa2c &     -- rs2
                            rfa1c &     -- rs1
                            R_OR &      -- funct3
                            rfa1c &     -- rd
                            OP_REG;     -- or
                    -- c.mul -> mul rsd'/rs1', rsd'/rs1', rs2'
                    if inst_in(12) = '1' then
                      if ext_zcb and ext_m then
                        inst := F7_MUL &             -- funct7
                                rfa2c &              -- rs2
                                rfa1c &              -- rs1
                                R_MUL &              -- funct3
                                rfa1c &              -- rd
                                OP_REG;              -- mul
                      else
                        xc := '1';
                        inst := zerow;
                      end if;
                    end if;

                  -- c.and -> and rd', rs1', rs2'
                  when others =>
                    inst := F7_BASE &   -- funct7
                            rfa2c &     -- rs2
                            rfa1c &     -- rs1
                            R_AND &     -- funct3
                            rfa1c &     -- rd
                            OP_REG;     -- and
                    if inst_in(12) = '1' then
                      if ext_zcb then
                        case inst_in(4 downto 2) is
                          -- c.zext.b -> andi rd'/rs1', rd'/rs1', 0xff
                          when "000" =>
                            inst := x"0ff" &               -- imm[11:0]
                                    rfa1c &                -- rs1
                                    I_ANDI &               -- funct3
                                    rfa1c &                -- rd
                                    OP_IMM;                -- andi
                          -- c.sext.b -> sext.b rd'/rs1', rd'/rs1'
                          when "001" =>
                            if ext_zbb then
                              inst := F12_SEXTB &          -- funct12
                                      rfa1c &              -- rs1
                                      I_SLLI &             -- funct3
                                      rfa1c &              -- rd
                                      OP_IMM;              -- sext.b
                            else
                              xc := '1';
                              inst := zerow;
                            end if;
                          -- c.zext.h -> zext.h rd'/rs1', rd'/rs1'
                          when "010" =>
                            if ext_zbb then
                              if is_rv32 then
                                inst := F12_ZEXTH &          -- funct12
                                        rfa1c &              -- rs1
                                        I_XORI &             -- funct3
                                        rfa1c &              -- rd
                                        OP_REG;              -- zext.h
                              else
                                inst := F12_ZEXTH &          -- funct12
                                        rfa1c &              -- rs1
                                        I_XORI &             -- funct3
                                        rfa1c &              -- rd
                                        OP_32;               -- zext.h
                              end if;
                            else
                              xc := '1';
                              inst := zerow;
                            end if;
                          -- c.sext.h -> sext.h rd'/rs1', rd'/rs1'
                          when "011" =>
                            if ext_zbb then
                              inst := F12_SEXTH &          -- funct12
                                      rfa1c &              -- rs1
                                      I_SLLI &             -- funct3
                                      rfa1c &              -- rd
                                      OP_IMM;              -- sext.h
                            else
                              xc := '1';
                              inst := zerow;
                            end if;
                          -- c.zext.w -> add.uw rd'/rs1', rd'/rs1', zero
                          when "100" =>
                            if ext_zba and is_rv64 then
                              inst := F7_ADDSLLIUW &       -- funct7
                                      GPR_X0 &              -- rs2
                                      rfa1c  &              -- rs1
                                      R_ADD  &              -- funct3
                                      rfa1c  &              -- rd
                                      OP_32;               -- add.uw
                            else
                              xc := '1';
                              inst := zerow;
                            end if;
                          -- c.not -> xori rd'/rs1', rd1'/r1', -1
                          when "101" =>
                            inst := x"fff" &               -- imm[11:0]
                                    rfa1c &                -- rs1
                                    I_XORI &               -- funct3
                                    rfa1c &                -- rd
                                    OP_IMM;                -- xori
                          when others =>
                            xc := '1';
                            inst := zerow;
                        end case;
                      else
                        xc := '1';
                        inst := zerow;
                      end if;
                    end if;

                end case;  -- funct2
            end case;  -- inst_in(11 downto 10)

          -- c.j -> jal x0, imm
          when "101" =>
            inst := inst_in(12) &           -- imm[20]
                    inst_in(8) &            -- imm[10]
                    inst_in(10 downto 9) &  -- imm[9:8]
                    inst_in(6) &            -- imm[7]
                    inst_in(7) &            -- imm[6]
                    inst_in(2) &            -- imm[5]
                    inst_in(11) &           -- imm[4]
                    inst_in(5 downto 3) &   -- imm[3:1]
                    inst_in(12) &           -- imm[11]
                    imm12(11 downto 4) &    -- imm[19:12]
                    GPR_X0 &                -- rd
                    OP_JAL;                 -- jal

          -- c.beqz -> beq rs1', x0, imm
          -- c.bnez -> bne rs1', x0, imm
          when others =>  -- "110" | "111"
            inst := inst_in(12) &            -- imm[12]
                    imm12(10 downto 9) &     -- imm[10:9]
                    inst_in(12) &            -- imm[8]
                    inst_in(6 downto 5) &    -- imm[7:6]
                    inst_in(2) &             -- imm[5]
                    GPR_X0 &                 -- rs2
                    rfa1c &                  -- rs1
                    "00" & inst_in(13) &     -- funct3
                    inst_in(11 downto 10) &  -- imm[4:3]
                    inst_in(4 downto 3) &    -- imm[2:1]
                    inst_in(12) &            -- imm[11]
                    OP_BRANCH;               -- branch

        end case;  -- inst_in(11 downto 10)

      -- C2
      when "10" =>
        case funct3 is

          -- c.slli -> slli rd, rs1, shamt
          when "000" =>
            inst := "000000" &             -- funct7[6:1]
                    inst_in(12) &          -- shamt[5]
                    inst_in(6 downto 2) &  -- shamt[4:0]
                    rfa1 &                 -- rs1
                    I_SLLI &               -- funct3
                    rd &                   -- rd
                    OP_IMM;                -- slli
            -- For RV32, the code points with the high bit set
            -- are designated for custom extensions.
            if is_rv32 and inst_in(12) = '1' then
              xc := '1';
              inst := zerow;
            end if;
            -- rd = x0 are custom HINTs (except as above).

          -- c.fldsp -> fld rd, imm(x2)
          when "001" =>
            inst := "000" &                -- imm[11:9]
                    inst_in(4 downto 2) &  -- imm[8:6]
                    inst_in(12) &          -- imm[5]
                    inst_in(6 downto 5) &  -- imm[4:3]
                    "000" &                -- imm[2:0]
                    GPR_SP &               -- rs1
                    I_LD &                 -- funct3
                    rd &                   -- rd
                    OP_LOAD_FP;            -- fld
            if not ext_d or not fpu_en then
              xc := '1';
              inst := zerow;
            end if;

          -- c.lwsp -> lw rd, imm(x2)
          when "010" =>
            inst := "0000" &               -- imm[11:8]
                    inst_in(3 downto 2) &  -- imm[7:6]
                    inst_in(12) &          -- imm[5]
                    inst_in(6 downto 4) &  -- imm[4:2]
                    "00" &                 -- imm[1:0]
                    GPR_SP &               -- rs1
                    I_LW &                 -- funct3
                    rd &                   -- rd
                    OP_LOAD;               -- ld
            -- rd = x0 are reserved by the standard.
            if rd = "00000" then
              xc := '1';
              inst := zerow;
            end if;

          -- c.flwsp
          -- c.ldsp
          when "011" =>
            -- c.flwsp -> flw rd, imm(x2)
            if is_rv32 then
              inst := "0000" &               -- imm[11:8]
                      inst_in(3 downto 2) &  -- imm[7:6]
                      inst_in(12) &          -- imm[5]
                      inst_in(6 downto 4) &  -- imm[4:2]
                      "00" &                 -- imm[1:0]
                      GPR_SP &               -- rs1
                      I_FLW &                -- funct3
                      rd &                   -- rd
                      OP_LOAD_FP;            -- flw
              if not ext_f or not fpu_en then
                xc := '1';
                inst := zerow;
              end if;
            -- c.ldsp -> ld rd, imm(x2)
            else
              inst := "000" &                -- imm[11:9]
                      inst_in(4 downto 2) &  -- imm[8:6]
                      inst_in(12) &          -- imm[5]
                      inst_in(6 downto 5) &  -- imm[4:3]
                      "000" &                -- imm[2:0]
                      GPR_SP &               -- rs1
                      I_LD &                 -- funct3
                      rd &                   -- rd
                      OP_LOAD;               -- ld
              -- rd = x0 are reserved by the standard.
              if rd = "00000" then
                xc := '1';
                inst := zerow;
              end if;
            end if;

          -- misc
          when "100" =>

            if inst_in(12) = '0' then
              -- c.jr -> jalr x0, 0(rs1)
              if rfa2 = "00000" then
                inst := imm12 &         -- imm[11:0]
                        rfa1 &          -- rs1
                        I_JALR &        -- funct3
                        GPR_X0 &        -- rd
                        OP_JALR;        -- jalr
                -- rs1 = x0 are reserved by the standard.
                if rfa1 = "00000" then
                  xc := '1';
                  inst := zerow;
                end if;
              -- c.mv -> add rd, x0, rs2
              else
                inst := F7_BASE &       -- funct7
                        rfa2 &          -- rs2
                        GPR_X0 &        -- rs1
                        R_ADD &         -- funct3
                        rd &            -- rd
                        OP_REG;         -- add
                -- rd = x0 are standard HINTs.
              end if;

            else

              if rfa2 = "00000" then

                -- c.ebreak -> ebreak
                if rd = "00000" then
                  inst             := (others => '0');
                  inst(20)         := '1';
                  inst(6 downto 0) := OP_SYSTEM;
                -- c.jalr -> jalr x1, 0(rs1)
                else
                  inst := zerow(11 downto 0) &  -- imm[11:0]
                          rfa1 &                -- rs1
                          I_JALR &              -- funct3
                          GPR_RA &              -- rd
                          OP_JALR;              -- jalr
                end if;  -- rd

              -- c.add -> rd, rs1, rs2
              else
                inst := F7_BASE &       -- funct7
                        rfa2 &          -- rs2
                        rfa1 &          -- rs1
                        R_ADD &         -- funct3
                        rd &            -- rd
                        OP_REG;         -- add
              -- rd = x0 are standard HINTs.
              end if;
            end if;  -- inst_in(12)

          -- c.fsdsp -> fsd rs2, imm(x2)
          when "101" =>
            inst := "000" &                  -- imm[11:9]
                    inst_in(9 downto 7) &    -- imm[8:6]
                    inst_in(12) &            -- imm[5]
                    rfa2 &                   -- rs2
                    GPR_SP &                 -- rs1
                    S_FSD &                  -- funct3
                    inst_in(11 downto 10) &  -- imm[4:3]
                    "000" &                  -- imm[2:0]
                    OP_STORE_FP;             -- fld
            if not ext_d or not fpu_en then
              xc := '1';
              inst := zerow;
            end if;

          -- c.swsp -> sw rs2, imm(x2)
          when "110" =>
            inst := "0000" &                -- imm[11:8]
                    inst_in(8 downto 7) &   -- imm[7:6]
                    inst_in(12) &           -- imm[5]
                    rfa2 &                  -- rs2
                    GPR_SP &                -- rs1
                    S_SW &                  -- funct3
                    inst_in(11 downto 9) &  -- imm[4:2]
                    "00" &                  -- imm[1:0]
                    OP_STORE;               -- sw

          -- c.fswsp
          -- c.sdsp
          when others =>
            -- c.fswsp -> fsw rs2, imm(x2)
            if is_rv32 and ext_f then
              inst := "0000" &                 -- imm[11:8]
                      inst_in(8 downto 7) &    -- imm[7:6]
                      inst_in(12) &            -- imm[5]
                      rfa2 &                   -- rs2
                      GPR_SP &                 -- rs1
                      S_FSW &                  -- funct3
                      inst_in(11 downto 9) &   -- imm[4:2]
                      "00" &                   -- imm[1:0]
                      OP_STORE_FP;             -- fsw
              if not fpu_en then
                xc := '1';
                inst := zerow;
              end if;
            -- c.sdsp -> sd rs2, imm(x2)
            elsif is_rv64 then
              inst := "000" &                  -- imm[11:9]
                      inst_in(9 downto 7) &    -- imm[8:6]
                      inst_in(12) &            -- imm[5]
                      rfa2 &                   -- rs2
                      GPR_SP &                 -- rs1
                      S_SD &                   -- funct3
                      inst_in(11 downto 10) &  -- imm[4:3]
                      "000" &                  -- imm[2:0]
                      OP_STORE;                -- sd
            else
              xc := '1';
              inst := zerow;
            end if;

        end case;  -- funct3

      when others =>
        null;

    end case;  -- op

    inst_out := inst;
    xc_out   := xc;
  end;

  function rvc_expander_fpuxc(active  : extension_type;
                              inst_in : word16;
                              fpu_en  : boolean) return boolean is
    variable is_rv64     : boolean := is_enabled(active, x_rv64);
    variable is_rv32     : boolean := not is_rv64;
    variable ext_f       : boolean := is_enabled(active, x_f);
    variable ext_d       : boolean := is_enabled(active, x_d);
    -- Evaluate compressed instruction
    variable op     : word2       := inst_in( 1 downto  0);
    variable funct3 : funct3_type := inst_in(15 downto 13);
  begin
    if op /= "00" and op /= "10" then
      return false;
    end if;

    -- c.fld[sp] / c.fsd[sp]
    if funct3 = "001" or funct3 = "101" then
      return not ext_d or not fpu_en;
    end if;

    if not is_rv32 or fpu_en then
      return false;
    end if;

    -- c.flw[sp] / c.fsw[sp]
    if funct3 = "011" or funct3 = "111" then
      return ext_f;
    end if;

    return false;
  end;

  -- Align compressed instruction
  procedure rvc_aligner(active           : in  extension_type;
                        inst_in          : in  iword_tuple_type;
                        rvc_pc           : in  std_logic_vector;
                        valid_in         : in  std_ulogic;
                        fpu_en           : in  boolean;
                        inst_out         : out iword_tuple_type;
                        comp_ill         : out word2;
                        hold_out         : out std_ulogic;
                        npc_out          : out word3;
                        valid_out        : out std_logic_vector;
                        buffer_first_out : out std_logic;  -- buffer first instruction
                        buffer_sec_out   : out std_logic;  -- buffer second instruction
                                                           --  if not issued
                        buffer_third_out : out std_logic;  -- buffer the third instruction
                        buffer_inst      : out iword_type;
                        buff_comp_ill    : out std_logic;
                        unaligned_out    : out std_ulogic) is
    variable single_issue : boolean    := is_enabled(active, x_single_issue);
    -- Non-constant
    subtype  fetch_pair      is std_logic_vector(inst_in'high downto inst_in'low);
    variable inst         : iword_pair_type;
    variable unaligned    : std_ulogic := '0';
    variable hold         : std_ulogic := '0';
    variable npc          : word3      := (others => '0');
    variable valid        : fetch_pair := (others => '0');
    variable buffer_first : std_ulogic;
    variable buffer_sec   : std_ulogic;
    variable buffer_third : std_ulogic;
    variable inst_c0e     : word;
    variable inst_c1e     : word;
    variable inst_c2e     : word;
    variable inst_c3e     : word;
    variable inst_c0xc    : std_ulogic;
    variable inst_c1xc    : std_ulogic;
    variable inst_c2xc    : std_ulogic;
    variable inst_c3xc    : std_ulogic;
    variable rvc_pc_t     : word3;
  begin

    rvc_expander(active,
                 inst_in(0).d(15 downto 0),
                 fpu_en,
                 inst_c0e,
                 inst_c0xc);
    rvc_expander(active,
                 inst_in(0).d(31 downto 16),
                 fpu_en,
                 inst_c1e,
                 inst_c1xc);
    if not single_issue then
      rvc_expander(active,
                   inst_in(1).d(15 downto 0),
                   fpu_en,
                   inst_c2e,
                   inst_c2xc);
      rvc_expander(active,
                   inst_in(1).d(31 downto 16),
                   fpu_en,
                   inst_c3e,
                   inst_c3xc);
    else
      inst_c2e  := (others => '0');
      inst_c3e  := (others => '0');
      inst_c2xc := '0';
      inst_c3xc := '0';
    end if;
    inst_c2xc := '0';
    inst_c3xc := '0';
    inst_c2xc := '0';
    inst_c3xc := '0';

    inst(0).lpc   := "00";
    inst(0).d     := inst_in(0).d;
    inst(0).dc    := inst_in(0).d(15 downto 0);
    inst(0).xc    := "000";
    inst(0).c     := '0';
    if not single_issue then
      inst(1).lpc   := "10";
      inst(1).d     := inst_in(1).d;
      inst(1).dc    := inst_in(1).d(15 downto 0);
      inst(1).xc    := "000";
      inst(1).c     := '0';
    end if;
    comp_ill      := "00";
    buff_comp_ill := '0';

    buffer_inst.d   := (others => '0');
    buffer_inst.lpc := "00";
    buffer_inst.xc  := "000";
    buffer_inst.c   := '0';
    buffer_first    := '0';
    buffer_sec      := '0';
    buffer_third    := '0';

    rvc_pc_t(2 downto 1) := rvc_pc(2 downto 1);
    if single_issue then
      rvc_pc_t(2) := '0';
    end if;
    case rvc_pc_t(2 downto 1) is
      -- Decode at 0x00
      when "00" =>
        -- Not Compressed instruction in 0
        if inst_in(0).d(1 downto 0) = "11" then
          inst(0)     := inst_in(0);
          inst(0).lpc := "00";
          valid(0)    := '1';
          if single_issue then
            inst(0).lpc := rvc_pc(2) & '0';
          end if;
          -- Not Compressed instruction in 1
          if not single_issue then
            if inst_in(1).d(1 downto 0) = "11" then
              inst(1)     := inst_in(1);
              inst(1).lpc := "10";
              buffer_sec  := '1';
              valid(1)    := '1';
            -- Compressed instruction in 1
            else
              inst(1).d       := inst_c2e;
              inst(1).dc      := inst_in(1).d(15 downto 0);
              inst(1).lpc     := "10";
              valid(1)        := '1';
              inst(1).c       := '1';
              comp_ill(1)     := inst_c2xc;
              -- Generate unaligned flag
              buffer_inst.lpc := "11";
              if inst_in(1).d(17 downto 16) = "11" then
                buffer_third               := '1';
                buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
                unaligned                  := '1';
              else
                -- One more compressed left, buffer it
                buffer_third   := '1';
                buffer_inst.d  := inst_c3e;
                buffer_inst.dc := inst_in(1).d(31 downto 16);
                buffer_inst.c  := '1';
                buff_comp_ill  := inst_c3xc;
              end if;  -- unaligned flag
            end if;  -- instruction in 1
          end if;  -- not single_issue
        -- Compressed instruction in 0
        else
          inst(0).d   := inst_c0e;
          inst(0).dc  := inst_in(0).d(15 downto 0);
          inst(0).c   := '1';
          inst(0).lpc := "00";
          comp_ill(0) := inst_c0xc;
          valid(0)    := '1';
          if single_issue then
            hold        := '1';
            inst(0).lpc := rvc_pc(2) & '0';
          end if;
          if not single_issue then
            -- Not Compressed instruction in 0 1/2
            if inst_in(0).d(17 downto 16) = "11" then
              inst(1).d       := inst_in(1).d(15 downto 0) & inst_in(0).d(31 downto 16);
              inst(1).lpc     := "01";
              valid(1)        := '1';
              -- Generate unaligned flag
              buffer_inst.lpc := "11";
              if inst_in(1).d(17 downto 16) = "11" then
                buffer_third               := '1';
                buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
                unaligned                  := '1';
              else
                -- One more compressed left, buffer it
                buffer_third   := '1';
                buffer_inst.d  := inst_c3e;
                buffer_inst.dc := inst_in(1).d(31 downto 16);
                buffer_inst.c  := '1';
                buff_comp_ill  := inst_c3xc;
              end if;  -- unaligned flag

            -- Compressed instruction in 0 1/2
            else
              --inst(1).d(15 downto 0) := inst_in(0).d(31 downto 16);
              inst(1).d   := inst_c1e;
              inst(1).dc  := inst_in(0).d(31 downto 16);
              inst(1).c   := '1';
              inst(1).lpc := "01";
              comp_ill(1) := inst_c1xc;
              valid(1)    := '1';
              -- More valid instructions
              if inst_in(1).d(1 downto 0) = "11" then
                --one 32-bit instruction left buffer it
                buffer_third               := '1';
                buffer_inst.d(31 downto 0) := inst_in(1).d(31 downto 0);
                buffer_inst.lpc            := "10";
              else
                -- Two more valid instructions left
                hold := '1';
                npc  := "100";
              end if;
            end if;  -- instruction in 0 1/2
          end if;  -- not single_issue
        end if;  -- instruction in 0

      -- Decode at 0x02
      when "01" =>
        -- Not Compressed instruction in 0 1/2
        if inst_in(0).d(17 downto 16) = "11" then
          inst(0).d       := inst_in(1).d(15 downto 0) & inst_in(0).d(31 downto 16);
          inst(0).lpc     := "01";
          valid(0)        := '1';
          -- Generate unaligned flag
          buffer_inst.lpc := "11";
          if single_issue then
            -- Unaligned for single issue
            valid(0)      := '0';
            unaligned     := '1';
            buffer_third  := '1';
            buffer_inst.d(15 downto 0) := inst_in(0).d(31 downto 16);
            buffer_inst.lpc := rvc_pc(2) & '1';
            -- Generate instruction lpc in case it is a mexc on lsb of unaligned instruction.
            inst(0).lpc := rvc_pc(2) & '1';
          end if;
          if not single_issue then
            if inst_in(1).d(17 downto 16) = "11" then
              buffer_third               := '1';
              buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
              unaligned                  := '1';
            else
              buffer_sec  := '1';
              inst(1).d   := inst_c3e;
              inst(1).dc  := inst_in(1).d(31 downto 16);
              inst(1).c   := '1';
              inst(1).lpc := "11";
              comp_ill(1) := inst_c3xc;
              valid(1)    := '1';
            end if;  -- unaligned flag
          end if; -- not single_issue
        -- Compressed instruction in 0 1/2
        else
          inst(0).d   := inst_c1e;
          inst(0).dc  := inst_in(0).d(31 downto 16);
          inst(0).c   := '1';
          inst(0).lpc := "01";
          comp_ill(0) := inst_c1xc;
          valid(0)    := '1';
          if single_issue then
            inst(0).lpc := rvc_pc(2) & '1';
          end if;
          if not single_issue then
            -- Not Compressed instruction in 1
            if inst_in(1).d(1 downto 0) = "11" then
              buffer_sec  := '1';
              inst(1)     := inst_in(1);
              inst(1).lpc := "10";
              valid(1)    := '1';
            -- Compressed instruction in 1
            else
              inst(1).d       := inst_c2e;
              inst(1).dc      := inst_in(1).d(15 downto 0);
              inst(1).c       := '1';
              inst(1).lpc     := "10";
              comp_ill(1)     := inst_c2xc;
              valid(1)        := '1';
              -- Generate unaligned flag
              buffer_inst.lpc := "11";
              if inst_in(1).d(17 downto 16) = "11" then
                buffer_third               := '1';
                buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
                unaligned                  := '1';
              else
                -- Only one compressed inst left buffer it
                buffer_third  := '1';
                --buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
                buffer_inst.d  := inst_c3e;
                buffer_inst.dc := inst_in(1).d(31 downto 16);
                buffer_inst.c  := '1';
                buff_comp_ill  := inst_c3xc;
              end if;  -- unaligned flag
            end if;  -- instruction in 1
          end if;  -- not single_issue
        end if;  -- instruction in 0 1/2

      -- Decode at 0x04
      when "10" =>
        if not single_issue then
          -- Not Compressed instruction in 1
          if inst_in(1).d(1 downto 0) = "11" then
            inst(0)                    := inst_in(1);
            inst(0).lpc                := "10";
            valid(0)                   := '1';
            buffer_first               := '1';
            buffer_inst.d(31 downto 0) := inst_in(1).d(31 downto 0);
            buffer_inst.lpc            := "10";
          -- Compressed instruction in 1
          else
            -- Generate unaligned flag
            if inst_in(1).d(17 downto 16) = "11" then
              inst(0).d                  := inst_c2e;
              inst(0).dc                 := inst_in(1).d(15 downto 0);
              inst(0).c                  := '1';
              inst(0).lpc                := "10";
              comp_ill(0)                := inst_c2xc;
              valid(0)                   := '1';
              buffer_third               := '1';
              buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
              unaligned                  := '1';
              buffer_inst.lpc            := "11";
            else
              buffer_sec  := '1';
              inst(0).d   := inst_c2e;
              inst(0).dc  :=  inst_in(1).d(15 downto 0);
              inst(0).c   := '1';
              inst(0).lpc := "10";
              comp_ill(0) := inst_c2xc;
              valid(0)    := '1';
              inst(1).d   := inst_c3e;
              inst(1).dc  := inst_in(1).d(31 downto 16);
              inst(1).c   := '1';
              inst(1).lpc := "11";
              comp_ill(1) := inst_c3xc;
              valid(1)    := '1';
            end if;  -- unaligned flag
          end if;  -- instruction in 1
        else
          null;
        end if; -- not single_issue

      -- Decode at 0x06
      when others =>
        if not single_issue then
          -- Generate unaligned flag
          buffer_inst.lpc := "11";
          if inst_in(1).d(17 downto 16) = "11" then
            valid                      := "00";
            buffer_third               := '1';
            buffer_inst.d(15 downto 0) := inst_in(1).d(31 downto 16);
            unaligned                  := '1';
          else
            valid(0)       := '1';
            inst(0).c      := '1';
            comp_ill(0)    := inst_c3xc;
            buffer_first   := '1';
            buffer_inst.d  := inst_c3e;
            buffer_inst.dc := inst_in(1).d(31 downto 16);
            buffer_inst.c  := '1';
            buff_comp_ill  := inst_c3xc;
          end if;  -- unaligned flag

          -- Generate instruction information in case it is a memory exception
          -- on lsb part of unaligned inst
          inst(0).d   := inst_c3e;
          inst(0).dc  := inst_in(1).d(31 downto 16);
          inst(0).lpc := "11";
        else
          null;
        end if;  -- not single_issue
    end case;  -- pc_in(2 downto 1)

    if valid_in = '0' then
      valid := "00";
    end if;
    if single_issue then
      valid(1)     := '0';
      buffer_first := '0';
      buffer_sec   := '0';
    end if;

    -- Output Signals
    inst_out         := inst;
    unaligned_out    := unaligned and valid_in;
    valid_out        := valid;
    hold_out         := hold and valid_in;
    npc_out          := npc;
    buffer_sec_out   := buffer_sec and valid_in;
    buffer_third_out := buffer_third and valid_in;
    buffer_first_out := buffer_first and valid_in;
  end;

  procedure no_rvc_aligner(active        : in  extension_type;
                        inst_in          : in  iword_tuple_type;
                        rvc_pc           : in  std_logic_vector;
                        valid_in         : in  std_ulogic;
                        inst_out         : out iword_tuple_type;
                        comp_ill         : out word2;
                        hold_out         : out std_ulogic;
                        npc_out          : out word3;
                        valid_out        : out std_logic_vector;
                        buffer_first_out : out std_logic;  -- buffer first instruction
                        buffer_sec_out   : out std_logic;  -- buffer second instruction
                                                           --  if not issued
                        buffer_third_out : out std_logic;  -- buffer the third instruction
                        buffer_inst      : out iword_type;
                        buff_comp_ill    : out std_logic;
                        unaligned_out    : out std_ulogic) is
    variable single_issue : boolean    := is_enabled(active, x_single_issue);
    -- Non-constant
    subtype  fetch_pair      is std_logic_vector(inst_in'high downto inst_in'low);
    variable inst         : iword_pair_type;
    variable unaligned    : std_ulogic := '0';
    variable hold         : std_ulogic := '0';
    variable npc          : word3      := (others => '0');
    variable valid        : fetch_pair := (others => '0');
    variable buffer_first : std_ulogic;
    variable buffer_sec   : std_ulogic;
    variable buffer_third : std_ulogic;
    variable rvc_pc_t     : std_ulogic;
  begin

    inst(0).lpc   := "00";
    inst(0).d     := inst_in(0).d;
    inst(0).dc    := zerow16;
    inst(0).xc    := "000";
    inst(0).c     := '0';
    if not single_issue then
      inst(1).lpc   := "10";
      inst(1).d     := inst_in(1).d;
      inst(1).dc    := zerow16;
      inst(1).xc    := "000";
      inst(1).c     := '0';
    end if;
    comp_ill      := "00";
    buff_comp_ill := '0';

    buffer_inst.d   := zerow;
    buffer_inst.lpc := "00";
    buffer_inst.xc  := "000";
    buffer_inst.c   := '0';
    buffer_first    := '0';
    buffer_sec      := '0';
    buffer_third    := '0';

    -- No compressed insn, only one bit needed
    rvc_pc_t := rvc_pc(2);
    if single_issue then
      rvc_pc_t := '0';
    end if;
    case rvc_pc_t is
      -- Decode at 0x00
      when '0' =>
          -- Not Compressed instruction in 0
        inst(0)     := inst_in(0);
        inst(0).lpc := "00";
        valid(0)    := '1';
        if single_issue then
          inst(0).lpc := rvc_pc(2) & '0';
        end if;
          -- Not Compressed instruction in 1
        if not single_issue then
          inst(1)     := inst_in(1);
          inst(1).lpc := "10";
          buffer_sec  := '1';
          valid(1)    := '1';
        end if;  -- not single_issue

      -- Decode at 0x04
      when others =>
        if not single_issue then
          -- Not Compressed instruction in 1
            inst(0)                    := inst_in(1);
            inst(0).lpc                := "10";
            valid(0)                   := '1';
            buffer_first               := '1';
            buffer_inst.d(31 downto 0) := inst_in(1).d(31 downto 0);
            buffer_inst.lpc            := "10";
        else
          null;
        end if; -- not single_issue
    end case;  -- pc_in(2)

    if valid_in = '0' then
      valid := "00";
    end if;
    if single_issue then
      valid(1)     := '0';
      buffer_first := '0';
      buffer_sec   := '0';
    end if;

    -- Output Signals
    inst_out         := inst;
    unaligned_out    := unaligned and valid_in;
    valid_out        := valid;
    hold_out         := hold and valid_in;
    npc_out          := npc;
    buffer_sec_out   := buffer_sec and valid_in;
    buffer_third_out := buffer_third and valid_in;
    buffer_first_out := buffer_first and valid_in;
  end;

  -- PC validity check
  -- Returns '1' if pc has to be used as an operand.
  function pc_valid(
                    active : extension_type;
                    cfi_en : cfi_t;
                    inst : word) return std_ulogic is
    variable op  : opcode_type := opcode(inst);
    -- Non-constant
    variable vpc : std_ulogic  := '0';
  begin
    case op is
      when OP_JAL | OP_JALR => vpc := '1';
      when AUIPC =>
        vpc := '1';
        if is_lpad(active, cfi_en, inst) then
          vpc := '0';
        end if;
      when others => null;
    end case;

    return vpc;
  end;

  -- Immediate generation and validity check
  -- Note that ZI-Type (CSRI) are not done here since CSRs have separate handling.
  procedure imm_gen(active    : in  extension_type;
                    inst_in   : in  word;
                    valid_out : out std_ulogic;
                    imm_out   : out wordx;
                    bj_imm    : out wordx) is
    variable op      : opcode_type := opcode(inst_in);
    variable funct5  : funct5_type := funct5(inst_in);
    variable funct3  : funct3_type := funct3(inst_in);
    variable rd      : reg_t       := rd(inst_in);
    -- Non-constant
    variable vimm    : std_ulogic  := '0';
    variable imm     : wordx       := (others => '0');
    variable i_imm   : wordx       := (others => inst_in(31));
    variable s_imm   : wordx       := (others => inst_in(31));
    variable b_imm   : wordx       := (others => inst_in(31));
    variable u_imm   : wordx       := (others => inst_in(31));
    variable j_imm   : wordx       := (others => inst_in(31));
    variable si_imm  : wordx       := (others => '0');
  begin
    -- Instruction Type Immediate --------------------------------------------
    -- I-Type
    i_imm(11 downto 0) := inst_in(31 downto 20);
    -- S-Type
    s_imm(11 downto 0) := inst_in(31 downto 25) & inst_in(11 downto 7);
    -- B-Type
    b_imm(12 downto 0) := inst_in(31) & inst_in(7) & inst_in(30 downto 25) & inst_in(11 downto 8) & '0';
    -- U-Type
    u_imm(31 downto 0) := inst_in(31 downto 12) & zerox(11 downto 0);
    -- J-Type
    j_imm(20 downto 0) := inst_in(31) & inst_in(19 downto 12) & inst_in(20) & inst_in(30 downto 21) & '0';
    -- SI-Type (shift amount)
    si_imm(5 downto 0) := inst_in(25 downto 20);

    case op is
      when LUI | AUIPC =>
        imm   := u_imm;
        vimm  := '1';
      when OP_JAL =>
        imm   := j_imm;
        vimm  := '1';
      when OP_JALR | OP_LOAD | OP_LOAD_FP =>
        imm   := i_imm;
        vimm  := '1';
      when OP_IMM =>
        if funct3 = I_SLLI or funct3 = I_SRLI then -- I_SRAI
          imm := si_imm;
        else
          imm := i_imm;
        end if;
        vimm  := '1';
      when OP_BRANCH =>
        imm   := b_imm;
        vimm  := '1';
      when OP_STORE | OP_STORE_FP =>
        imm   := s_imm;
        vimm  := '1';
      when OP_IMM_32 =>
        if inst_in(12) = '0' then -- I_ADDIW
          imm := i_imm;
        else
          imm := si_imm;
        end if;
        vimm  := '1';
      when others =>
    end case;

    bj_imm := b_imm;
    if inst_in(2) = '1' then
      bj_imm := j_imm;
    end if;

    valid_out := vimm;
    imm_out   := imm;
  end;

  -- There is no need to check for ext_h etc, since
  -- any such instructions would fail at decode.

  -- Currently all instructions with funct3=000 also have rd=0.
  -- For now, assume we don't need to check rd!
  function is_system0(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_SYSTEM and funct3 = "000";
  end;

  function is_system1(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_SYSTEM and funct3 = "100";
  end;

  function is_wfi(inst :word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
    variable funct7 : funct7_type := funct7(inst);
    variable rs2    : reg_t       := rs2(inst);
  begin
    return opcode = OP_SYSTEM and funct3 = "000" and funct7 = F7_WFI and
           rs2 = "00101";
  end;

  function is_xret(inst : word) return boolean is
    variable rd     : reg_t       := rd(inst);
    variable rs1    : reg_t       := rs1(inst);
    variable rs2    : reg_t       := rs2(inst);
    variable funct7 : funct7_type := funct7(inst);
  begin
    return is_system0(inst) and all_0(rd) and all_0(rs1) and rs2 = "00010" and
           (funct7 = F7_SRET or funct7 = F7_MRET or funct7 = F7_MNRET);
  end;

  -- Standard CSR access?
  function is_csr_access(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_SYSTEM and funct3(1 downto 0) /= "00";
  end;

  function is_csr(active : extension_type;
                  cfi_en : cfi_t;
                  inst   : word) return boolean is
  begin
    return is_csr_access(inst)
           or is_sspopchk(active, cfi_en, inst) or is_sspush(active, cfi_en, inst) or
              is_ssrdp(active, cfi_en, inst)
           ;
  end;

  -- CSR, or possibly so. Do not use when certainty is required!
  -- Does not check very carefully when it comes to Zicfiss instructions
  -- (of which many, but not necessarily all, access CSRs when they are active).
  function maybe_csr(active : extension_type;
                     cfi_en : cfi_t;
                     inst   : word) return boolean is
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable funct7      : funct7_type  := funct7(inst);
    variable funct12     : funct12_type := funct12(inst);
  begin
    return is_csr_access(inst)
           or (ext_zicfiss and is_system1(inst) and
               (funct12 = F12_SSRDPOPCHK or funct7 = F7_SSPUSH))
           ;
  end;

  -- Standard CSR read access?
  -- Assumes it is already known that inst is a CSR instruction.
  function csr_access_read(inst : word) return boolean is
    variable rd     : reg_t       := rd(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return ((funct3 = I_CSRRW or funct3 = I_CSRRWI) and rd /= "00000") or
           -- These are read-modify-write.
           funct3 = I_CSRRS  or funct3 = I_CSRRC or
           funct3 = I_CSRRSI or funct3 = I_CSRRCI;
  end;

  -- Standard CSR ready-only access?
  -- Assumes it is already known that inst is a CSR instruction.
  function csr_access_read_only(inst : word) return boolean is
    variable rfa1   : reg_t       := rs1(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    -- CSRR[S/C] and rs1=x0, or CSRR[S/C]I and imm=0, ie read-only?
    -- (CSRR[S/C][I] are read-modify-write.)
    return rfa1 = "00000" and
           (funct3 = I_CSRRS  or funct3 = I_CSRRC or
            funct3 = I_CSRRSI or funct3 = I_CSRRCI);
  end;

  function csr_access_write_only(inst : word) return boolean is
    variable rd     : reg_t       := rd(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    -- CSRRW/CSRRWI and rd=x0, ie write-only?
    return rd = "00000" and (funct3 = I_CSRRW or funct3 = I_CSRRWI);
  end;

-- pragma translate_off
  function is_csr(inst : word) return boolean is
    variable active : extension_type := extension_all xor config_all;
  begin
    return is_csr_access(inst)
           or is_sspopchk(active, cfi_both, inst) or is_sspush(active, cfi_both, inst) or
              is_ssrdp(active, cfi_both, inst);
  end;
-- pragma translate_on

  -- Assumes it is already known that inst is a CSR type instruction.
  function csr_read_only(active  : extension_type;
                         inst    : word) return boolean is
    variable rfa1   : reg_t       := rs1(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    -- CSRR[S/C] and rs1=x0, or CSRR[S/C]I and imm=0, ie read-only?
    -- Do not care about whether it really is an lps/lpc instruction.
    return csr_access_read_only(inst)
           or is_ssrdp(active, cfi_both, inst);
  end;

  -- Assumes it is already known that inst is a CSR instruction.
  function csr_write_only(active  : extension_type;
                          inst    : word) return boolean is
    variable rd     : reg_t       := rd(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return csr_access_write_only(inst);
  end;

  -- There may at some later point be other similar instructions.
  -- Then further checks (rd) will be needed here!
  function is_sfence_vma(active : extension_type;
                         inst   : word) return boolean is
    variable ext_svinval : boolean     := is_enabled(active, x_svinval);
    variable rd          : reg_t       := rd(inst);
    variable funct7      : funct7_type := funct7(inst);
  begin
    return is_system0(inst) and
           (funct7 = F7_SFENCE_VMA or (ext_svinval and funct7 = F7_SINVAL_VMA));
  end;

  -- There may at some later point be other similar instructions.
  -- Then further checks (rd) will be needed here!
  function is_hfence_vvma(active : extension_type;
                          inst   : word) return boolean is
    variable ext_svinval : boolean     := is_enabled(active, x_svinval);
    variable rd          : reg_t       := rd(inst);
    variable funct7      : funct7_type := funct7(inst);
  begin
    return is_system0(inst) and
           (funct7 = F7_HFENCE_VVMA or (ext_svinval and funct7 = F7_HINVAL_VVMA));
  end;

  -- There may at some later point be other similar instructions.
  -- Then further checks (rd) will be needed here!
  function is_hfence_gvma(active : extension_type;
                          inst   : word) return boolean is
    variable ext_svinval : boolean     := is_enabled(active, x_svinval);
    variable rd          : reg_t       := rd(inst);
    variable funct7      : funct7_type := funct7(inst);
  begin
    return is_system0(inst) and
           (funct7 = F7_HFENCE_GVMA or (ext_svinval and funct7 = F7_HINVAL_GVMA));
  end;

  function is_tlb_fence(active : extension_type;
                        inst   : word) return boolean is
    variable ext_h : boolean := is_enabled(active, x_h);
  begin
    return is_sfence_vma(active, inst) or
           (ext_h and (is_hfence_vvma(active, inst) or is_hfence_gvma(active, inst)));
  end;

  -- There may at some later point be other similar instructions.
  -- Then further checks (rd/rs2) will be needed here!
  function is_hlsv(inst : word) return boolean is
    variable funct7 : funct7_type := funct7(inst);
  begin
    if not is_system1(inst) then
      return false;
    end if;
    case funct7 is
      when F7_HLVB | F7_HLVH | F7_HLVW | F7_HLVD |
           F7_HSVB | F7_HSVH | F7_HSVW | F7_HSVD => return true;
      when others                                => return false;
    end case;
  end;

  -- Assumes that it is not necessary to check the rs2 field.
  function is_hlv(inst : word) return boolean is
    variable funct7 : funct7_type := funct7(inst);
  begin
    return is_hlsv(inst) and funct7(0) = '0';
  end;

  function is_hsv(inst : word) return boolean is
    variable funct7 : funct7_type := funct7(inst);
  begin
    return is_hlsv(inst) and funct7(0) = '1';
  end;

  -- Assumes that it is not necessary to completely check the rs2 field.
  function is_hlvx(inst : word) return boolean is
    variable funct7 : funct7_type := funct7(inst);
    variable rfa2   : reg_t       := rs2(inst);
  begin
    return is_hlsv(inst) and funct7(0) = '0' and rfa2(1) = '1';
  end;
  
  function is_fence_i(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_FENCE and funct3 = I_FENCE_I;
  end;

  function is_fence(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_FENCE and funct3 = I_FENCE;
  end;

  function is_diag(active : extension_type; inst : word) return boolean is
    variable ext_noelv : boolean     := is_enabled(active, x_noelv);
    variable opcode    : opcode_type := opcode(inst);
    variable funct7    : funct7_type := funct7(inst);
  begin
    return ext_noelv and opcode = OP_CUSTOM0 and funct7 = F7_BASE;
  end;

  -- Assumes it is already know that inst is a diagnostic instruction.
  function is_diag_store(inst : word) return boolean is
    variable funct3 : funct3_type := funct3(inst);
  begin
    return get_hi(funct3) = '1';
  end;

  function is_custom_alu(active : extension_type; inst : word) return boolean is
    variable ext_noelvalu : boolean     := is_enabled(active, x_noelvalu);
    variable opcode       : opcode_type := opcode(inst);
    variable funct7       : funct7_type := funct7(inst);
  begin
    return ext_noelvalu and opcode = OP_CUSTOM0 and funct7 = F7_BASE_RV64;
  end;

  function is_cbo(inst : word) return boolean is
    variable opcode   : opcode_type := opcode(inst);
    variable funct3   : funct3_type := funct3(inst);
  begin
    return opcode = OP_FENCE and funct3 = I_CBO;
  end;

  function is_mop_r(active : extension_type;
                    inst   : word) return boolean is
    variable ext_zimop : boolean     := is_enabled(active, x_zimop);
    variable funct7    : funct7_type := funct7(inst);
  begin
    if not ext_zimop or not is_system1(inst) then
      return false;
    end if;

    case funct7 is
      when F7_MOPR_0  | F7_MOPR_4  | F7_MOPR_8  | F7_MOPR_12 |
           F7_MOPR_16 | F7_MOPR_20 | F7_MOPR_24 | F7_MOPR_28 =>
        -- MOPR is really 1-00--0 111--,
        -- but other than 111 at the end is currently illegal, so
        -- we do not need to check that here.
        return true;
      when others =>
        return false;
    end case;
  end;

  function is_mop_rr(active : extension_type;
                     inst   : word) return boolean is
    variable ext_zimop : boolean     := is_enabled(active, x_zimop);
    variable funct7    : funct7_type := funct7(inst);
  begin
    if not ext_zimop or not is_system1(inst) then
      return false;
    end if;

    case funct7 is
      when F7_MOPRR_0 | F7_MOPRR_1 | F7_MOPRR_2 | F7_MOPRR_3 |
           F7_MOPRR_4 | F7_MOPRR_5 | F7_MOPRR_6 | F7_MOPRR_7 =>
        return true;
      when others =>
        return false;
    end case;
  end;

  function is_used_mop_rd(active : extension_type;
                          cfi_en : cfi_t;
                          inst   : word) return boolean is
    variable ext_zimop : boolean := is_enabled(active, x_zimop);
  begin
    if not ext_zimop then
      return false;
    end if;

    -- Any MOP_R[R]?
    return is_mop_r(active, inst) or is_mop_rr(active, inst);
  end;

  function is_used_mop_rs1(active : extension_type;
                           cfi_en : cfi_t;
                           inst   : word) return boolean is
    variable ext_zimop   : boolean      := is_enabled(active, x_zimop);
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable rfa2        : reg_t        := rs2(inst);
    variable funct7      : funct7_type  := funct7(inst);
    variable funct12     : funct12_type := funct12(inst);
  begin
    if not ext_zimop or not is_system1(inst)
       or not ext_zicfiss or not cfi_en.ss then
      return false;
    end if;

    if    funct12 = F12_SSRDPOPCHK then
      return (rfa1 = "00001" or rfa1 = "00101") and rd = "00000";  -- SSPOPCHK
    else
      return false;
    end if;
  end;

  function is_used_mop_rs2(active : extension_type;
                           cfi_en : cfi_t;
                           inst   : word) return boolean is
    variable ext_zimop   : boolean     := is_enabled(active, x_zimop);
    variable ext_zicfiss : boolean     := is_enabled(active, x_zicfiss);
    variable rd          : reg_t       := rd(inst);
    variable rfa1        : reg_t       := rs1(inst);
    variable rfa2        : reg_t       := rs2(inst);
    variable funct7      : funct7_type := funct7(inst);
  begin
    if not ext_zimop or not is_system1(inst)
       or not ext_zicfiss or not cfi_en.ss then
      return false;
    end if;

    if funct7 = F7_SSPUSH and rd = "00000" and rfa1 = "00000" then
      return rfa2 = "00001" or rfa2 = "00101";                     -- SSPUSH
    else
      return false;
    end if;
  end;

  function is_lpad(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return boolean is
    variable ext_zicfilp : boolean     := is_enabled(active, x_zicfilp);
    variable rd          : reg_t       := rd(inst);
    variable opcode      : opcode_type := opcode(inst);
  begin
    if not ext_zicfilp or opcode /= AUIPC or not cfi_en.lp then
      return false;
    end if;

    if rd = "00000" then
      return true;
    else
      return false;
    end if;
  end;

  function is_ssamoswap(active : extension_type;
                        cfi_en : cfi_t;
                        inst   : word) return boolean is
    variable ext_zicfiss : boolean     := is_enabled(active, x_zicfiss);
    variable rd          : reg_t       := rd(inst);
    variable opcode      : opcode_type := opcode(inst);
    variable funct5      : funct5_type := funct5(inst);
    variable funct3      : funct3_type := funct3(inst);
  begin
    if not ext_zicfiss or opcode /= OP_AMO or not cfi_en.ss then
      return false;
    end if;

    if funct5 = R_SSAMOSWAP and (funct3 = R_WORD or funct3 = R_DOUBLE) then
      return true;
    else
      return false;
    end if;
  end;

  function is_sspush(active : extension_type;
                     cfi_en : cfi_t;
                     inst   : word) return boolean is
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable rfa2        : reg_t        := rs2(inst);
    variable funct7      : funct7_type  := funct7(inst);
  begin
    if not ext_zicfiss or not is_system1(inst) or not cfi_en.ss then
      return false;
    end if;

    if funct7 = F7_SSPUSH and rd = "00000" and rfa1 = "00000" and
       (rfa2 = "00001" or rfa2 = "00101") then
      return true;
    else
      return false;
    end if;
  end;

  function is_sspopchk(active : extension_type;
                      cfi_en : cfi_t;
                      inst   : word) return boolean is
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable funct12     : funct12_type := funct12(inst);
  begin
    if not ext_zicfiss or not is_system1(inst) or not cfi_en.ss then
      return false;
    end if;

    if funct12 = F12_SSRDPOPCHK and rd = "00000" and
       (rfa1 = "00001" or rfa1 = "00101") then
      return true;
    else
      return false;
    end if;
  end;

  function is_ssrdp(active : extension_type;
                    cfi_en : cfi_t;
                    inst   : word) return boolean is
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable funct12     : funct12_type := funct12(inst);
  begin
    if not ext_zicfiss or not is_system1(inst) or not cfi_en.ss then
      return false;
    end if;

    if funct12 = F12_SSRDPOPCHK and rd /= "00000" and rfa1 = "00000" then
      return true;
    else
      return false;
    end if;
  end;

  -- These (is_fpu...) functions must be used on the unpacked version
  -- of an instruction, i.e. they can not be used on a compressed
  -- instruction directly.
  -- FPU instruction that does not touch memory?
  function is_fpu(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
  begin
    case opcode is
      when OP_FP     |
           OP_FMADD  |
           OP_FMSUB  |
           OP_FNMADD |
           OP_FNMSUB => return true;
      when others    => return false;
    end case;
  end;

  -- FPU instruction that touches memory?
  function is_fpu_mem(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
  begin
    return opcode = OP_LOAD_FP or opcode = OP_STORE_FP;
  end;

  -- FPU double precision store?
  function is_fpu_fsd(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
  begin
    return opcode = OP_STORE_FP and funct3 /= "010";
  end;

  -- FPU instruction with data from integer pipeline?
  function is_fpu_from_int(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct5 : funct5_type := funct5(inst);
  begin
    case opcode is
      when OP_FP =>
        case funct5 is
        when R_FCVT_S_W |
             R_FMV_W_X  => return true;
        when others     => return false;
        end case;
      when OP_LOAD_FP   => return true;
      when others       => return false;
    end case;
  end;

  -- FPU instruction with FPU destination register?
  function is_fpu_rd(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct5 : funct5_type := funct5(inst);
  begin
    case opcode is
      when OP_FP =>
        case funct5 is
        when R_FADD     |
             R_FSUB     |
             R_FMINMAX  |
             R_FSGN     |
             R_FCVT_S_D |
             R_FMUL     |
             R_FCVT_S_W |
             R_FMV_W_X  |
             R_FDIV     |
             R_FMVP_5_X |
             R_FSQRT    => return true;
        when others     => return false;
        end case;
      when OP_LOAD_FP   |
           OP_FMADD     |
           OP_FMSUB     |
           OP_FNMADD    |
           OP_FNMSUB    => return true;
      when others       => return false;
    end case;
  end;

  -- FPU instruction can modify FPU state (including flags)?
  function is_fpu_modify(inst : word) return boolean is
    variable opcode : opcode_type := opcode(inst);
    variable funct5 : funct5_type := funct5(inst);
  begin
    case opcode is
      when OP_FP =>
        case funct5 is
        when R_FADD     |
             R_FSUB     |
             R_FMINMAX  |
             R_FSGN     |
             R_FCVT_S_D |
             R_FMUL     |
             R_FCVT_W_S |
             R_FCMP     |
             R_FCVT_S_W |
             R_FMV_W_X  |
             R_FDIV     |
             R_FSQRT    => return true;
        when others     => return false;
        end case;
      when OP_LOAD_FP   |
           OP_FMADD     |
           OP_FMSUB     |
           OP_FNMADD    |
           OP_FNMSUB    => return true;
      when others       => return false;
    end case;
  end;


  -- Rd register validity check
  -- Returns '1' if the instruction has a valid integer rd field.
  function rd_gen(active : extension_type;
                  cfi_en : cfi_t;
                  inst   : word) return std_ulogic is
    variable op     : opcode_type := opcode(inst);
    variable funct5 : funct5_type := funct5(inst);
    variable rd     : reg_t       := rd(inst);
    -- Non-constant
    variable wreg   : std_ulogic  := '1';
  begin
    -- Check for the cases where there is no rd
    case op is
      when OP_BRANCH | OP_STORE =>
        -- The only two "normal" integer instructions to not have a destination.
        wreg := '0';

      when OP_STORE_FP | OP_LOAD_FP |
           OP_FMADD    | OP_FMSUB   |
           OP_FNMSUB   | OP_FNMADD =>
        -- Most FPU operations have no rd
        wreg := '0';

      when OP_FP =>
        -- Most FPU operations have no rd
        case funct5 is
          when R_FCVT_W_S | R_FMV_X_W | R_FCMP =>
            -- Conversion/move to integer, compare and class check
          when others =>
            wreg := '0';
        end case;

      when OP_SYSTEM =>
        -- Among SYSTEM instructions, rd use is limited to
        -- CSR, hlv, Zimop (of which some Zicfiss).
        if is_used_mop_rd(active, cfi_en, inst) then
          null;
        elsif not (is_csr_access(inst) or is_hlv(inst)) then
          wreg := '0';
        end if;

      when OP_FENCE =>
        -- No destination for fences
        wreg := '0';

      when OP_CUSTOM0 =>
        if is_diag(active, inst) then
          -- Diagnostic stores have no destination
          if is_diag_store(inst) then
            wreg := '0';
          end if;
        else
          -- Non-diagnostic custom0 assumed to have destination
          -- (or are "don't care" due to being illegal).
        end if;

      when others =>
        -- Everything else has an rd (or are "don't care" due to being illegal).
    end case;

    if rd = "00000" then
      wreg := '0';
    end if;

    return wreg;
  end;

  -- Rs1 register validity check
  -- Returns the rs1 field in case it is valid and integer, otherwise x0.
  function rs1_gen(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return reg_t is
    variable ext_zfa     : boolean     := is_enabled(active, x_zfa);
    variable op          : opcode_type := opcode(inst);
    variable funct3      : funct3_type := funct3(inst);
    variable funct5      : funct5_type := funct5(inst);
    variable rs2         : reg_t       := rs2(inst);
    -- Non-constant
    variable rs1         : reg_t       := rs1(inst);
    variable vreg        : std_ulogic  := '1';
  begin
    -- Check for the cases where there is no rs1
    case op is
      when LUI | OP_JAL =>
        -- Immediate value
        vreg := '0';

      when AUIPC =>
        -- Immediate value
        vreg := '0';
        -- Except for an implicit x7 read for LPAD instruction
        if is_lpad(active, cfi_en, inst) then
          rs1  := "00111";
          vreg := '1';
        end if;

      when OP_SYSTEM =>
        -- Among SYSTEM instructions, rs1 use is limited to
        -- (non-immediate value) CSR instructions,
        -- sfence.vma, hfence.v/gvma, hlv/hsv,
        -- and some Zicfiss.
        if is_csr_access(inst) and funct3(2) = '1' then  -- I_CSRRWI, I_CSRRSI, I_CSRRCI?
          vreg  := '0';
        end if;
        if is_used_mop_rs1(active, cfi_en, inst) then
          null;
        elsif not (is_csr_access(inst) or
                   is_sfence_vma(active, inst)  or
                   is_hfence_vvma(active, inst) or is_hfence_gvma(active, inst) or
                   is_hlsv(inst)) then
          vreg  := '0';
        end if;

      when OP_FMADD | OP_FMSUB | OP_FNMSUB | OP_FNMADD =>
        -- Most FPU operations have no rs1
        vreg := '0';

      when OP_FP =>
        -- Most FPU operations have no rs1
        case funct5 is
          when R_FCVT_S_W =>
            -- Conversions from integer
          when R_FMV_W_X =>
            -- Mostly moves from integer (except FLI.S/D/H)
            if ext_zfa and rs2 = "00001" then
              vreg := '0';
            end if;
          when others =>
            vreg   := '0';
        end case;

      when others =>
        -- Everything else has an rs1 (or are "don't care" due to being illegal).
    end case;

    -- This is used to make sure we do not accidentally
    -- use forwarding when there is not a source register at all.
    -- Relies on destination r0 being marked as invalid (.rdv = '0')!
    if vreg = '0' then
      rs1 := "00000";
    end if;

    return rs1;
  end;

  -- Rs2 register validity check
  -- Returns the rs2 field in case it is valid and integer, otherwise x0.
  function rs2_gen(active : extension_type;
                   cfi_en : cfi_t;
                   inst   : word) return reg_t is
    variable is_rv64 : boolean     := is_enabled(active, x_rv64);
    variable is_rv32 : boolean     := not is_rv64;
    variable ext_zfa : boolean     := is_enabled(active, x_zfa);
    variable op      : opcode_type := opcode(inst);
    variable funct3  : funct3_type := funct3(inst);
    variable funct5  : funct5_type := funct5(inst);
    variable funct7  : funct7_type := funct7(inst);
    -- Non-constant
    variable rs2     : reg_t       := rs2(inst);
    variable vreg    : std_ulogic  := '1';
  begin
    -- Check for rs2 use
    case op is
      when OP_REG | OP_BRANCH | OP_STORE | OP_32 =>
        -- All of these do have an rs2.

      when OP_SYSTEM =>
        -- Among SYSTEM instructions, rs2 use is limited to
        -- sfence.vma, sfence.vma, hfence.v/gvma, hsv,
        -- and some Zicfiss.
        if is_used_mop_rs2(active, cfi_en, inst) then
          null;
        elsif not (is_sfence_vma(active, inst)  or
                   is_hfence_vvma(active, inst) or is_hfence_gvma(active, inst) or
                   is_hsv(inst)) then
          vreg := '0';
        end if;

      when OP_AMO =>
        -- Most AMO instructions do have an rs2.
        case funct5 is
          when R_LR   => vreg := '0';
          when others =>
        end case;

      when OP_FP =>
        -- Only a single FPU instruction (FMVP.D.X) has an rs2.
        if not (ext_zfa and is_rv32 and funct7 = R_FMVP_D_X and funct3 = "000") then
          vreg := '0';
        end if;

      when OP_CUSTOM0 =>
        if is_diag(active, inst) then
          -- Diagnostic loads have no rs2
          if not is_diag_store(inst) then
            vreg := '0';
          end if;
        else
          -- Non-diagnostic custom0 assumed to have an rs2
          -- (or are "don't care" due to being illegal).
        end if;

      when others =>
        -- Everything else lacks an rs2.
        vreg := '0';
    end case;

    -- This is used to make sure we do not accidentally
    -- use forwarding when there is not a source register at all.
    -- Relies on destination r0 being marked as invalid (.rdv = '0')!
    if vreg = '0' then
      rs2 := "00000";
    end if;

    return rs2;
  end;

  function rd_gen(inst : word) return std_ulogic is
    variable active : extension_type := extension_all xor config_all;
  begin
    return rd_gen(active,
                  cfi_both,
                  inst);
  end;

  -- Must the instruction be handled in lane 0?
  function for_lane0(active : extension_type;
                     cfi_en : cfi_t;
                     lane   : lane_select;
                     inst   : word) return boolean is
    variable ext_zbc  : boolean     := is_enabled(active, x_zbc);
    variable ext_zbkc : boolean     := is_enabled(active, x_zbkc);
    variable ext_h    : boolean     := is_enabled(active, x_h);
    variable op       : opcode_type := opcode(inst);
    variable funct3   : funct3_type := funct3(inst);
    variable funct7   : funct7_type := funct7(inst);
  begin
    if op = OP_STORE    or op = OP_LOAD    or
       op = OP_STORE_FP or op = OP_LOAD_FP or
       op = OP_AMO      or op = OP_FENCE   or
       is_wfi(inst) then
      return true;
    end if;

    if is_sfence_vma(active, inst) then
      return true;
    end if;

    -- Hypervisor instructions are either fence, load, or store.
    if ext_h and (is_hfence_vvma(active, inst) or is_hfence_gvma(active, inst) or is_hlsv(inst)) then
      return true;
    end if;

    -- Custom diagnostic cache instruction
    if is_diag(active, inst) then
      return true;
    end if;

     -- Writes to PMPCFG lock bits, DFEATURESEN or SATP require the pipeline to be flushed.
     -- To simplify PC logic, such CSR writes always issue alone, but
     -- this also ensures that all CSR accesses are in the proper lane
     -- This covers all of Zicfiss!

    if is_csr(active, cfi_en, inst) then
      return true;
    end if;

    -- While floating point load/store need to be in lane 0, and are taken
    -- care of above, the other FPU instructions may also be forced here.
    if lane.fpu = 0 and is_fpu(inst) then
      return true;
    end if;

    -- Only one CLMUL machinery - and it is in the early lane0 ALU.
    -- R_CLMULR is not actually valid for ext_zbkc, but that does not matter here.
    if (ext_zbc or ext_zbkc) and op = OP_REG and funct7 = F7_MINMAXCLMUL and
      (funct3 = R_CLMUL or funct3 = R_CLMULH or funct3 = R_CLMULR) then
      return true;
    end if;

    return false;
  end;

  -- Must the instruction be handled in lane 1?
  function for_lane1(active : extension_type;
                     cfi_en : cfi_t;
                     lane   : lane_select;
                     inst   : word) return boolean is
    variable op : opcode_type := opcode(inst);
  begin
    if op = OP_JAL or op = OP_JALR or op = OP_BRANCH then
      return true;
    end if;

    -- While floating point load/store need to be in lane 0, the other
    -- FPU instructions may be forced here instead.
    if lane.fpu = 1 and is_fpu(inst) then
      return true;
    end if;

    return false;
  end;

  -- Some CSR accesses has some side effects. This function sets a vecotr
  -- with flags for each acction:
  -- Bits  Meaning
  -- 0     do not dual-issue write to CSR
  -- 1     memory access following write to CSR must be delayed
  -- 2     pipeline flush may be required by write to CSR,or CSR write could
  --       affect upcoming instructions, so hold issue
  -- 3     no FPU instructions under way together with this
  -- 4     no new FPU instructions until this completes
  -- 5     CSR write completes before a new interrupt is taken
  -- 6     CSR read/write need to be hold until previous instructions are committed
  -- 7     hold issue when accesing hpmcounters trhough sireg/sireg4 for an 
  --       accurate reading
  -- 8     hold the pipeline one extra cycle if there is a raw or waw dependency
  --
  -- Note that PMPCFG gets "overlapping" things set here. This is mainly to
  -- clarify for any future improvements to the code.
  --
  -- Note that many CSRs that might seem to require various bits set here
  -- do not, since they cannot affect anything in the same CPU privilege mode.
  -- Any changes to such CSRs will require a privilege change to do anything,
  -- and thus there will be a pipeline flush anyway.
  function csr_hold_category(addr : csratype; hpmc_mode : std_ulogic) return hold_category_t is
    -- Non-constant
    variable category : hold_category_t := (others => '0');
  begin
    -- Some CSR writes need to issue alone. This is achieved setting category(0) to 1


    -- For some CSR writes, nothing more should leave the issue stage
    -- until the writes are completed.
    -- DCSR would be one such, but can only be used from the DSU.
    case addr is
      -- Changes to these may force pipeline flush since the next instruction
      -- fetch may be required to behave differently.
      -- Writes to PMPCFG lock bits may change execute protection.
      when CSR_PMPCFG0 | CSR_PMPCFG1 | CSR_PMPCFG2 | CSR_PMPCFG3 |
           CSR_SATP    |         -- Changes memory mapping.
           CSR_VSATP   |         -- Changes memory mapping.
           CSR_HGATP   |         -- Changes memory mapping.
           CSR_MISA     |         -- May turn on/off extensions and change MXL.
           CSR_MSTATUS  |         -- May turn on/off FPU and extensions.
           CSR_MSTATUSH |         -- May toggle MPV, currently not possible to pair LD/SD
                                  -- with CSR write but it is better to be consistent with the RV64 behavior.
           CSR_SSTATUS  |
           -- VSSTATUS
           --   Should not be included here since writes to it are only done in
           --   modes that are not affected by it!
           -- HSTATUS
           --   Should not be included here since writes to it cannot affect
           --   the immediately following instructions.
           -- May cause illegal on subsequent FPU instruction
           CSR_FRM        | CSR_FCSR       |
           CSR_MENVCFG    | CSR_HENVCFG    | CSR_SENVCFG |
           CSR_MENVCFGH   | CSR_HENVCFGH   |
           CSR_MSECCFG    | CSR_MSECCFGH   |
           -- Changes trap jump behavior, VSTVEC not a concern since a mode change must occur.
           CSR_MTVEC      | CSR_STVEC      |
           -- May affect if an IRQ is taken or not
           CSR_MIDELEG    | CSR_HIDELEG    |
           -- Stateen affects the available extensions, similarly to envcfg
           CSR_MSTATEEN0  | CSR_MSTATEEN1  | CSR_MSTATEEN2  | CSR_MSTATEEN3  |
           CSR_MSTATEEN0H | CSR_MSTATEEN1H | CSR_MSTATEEN2H | CSR_MSTATEEN3H |
           CSR_SSTATEEN0  | CSR_SSTATEEN1  | CSR_SSTATEEN2  | CSR_SSTATEEN3  |
           CSR_HSTATEEN0  | CSR_HSTATEEN1  | CSR_HSTATEEN2  | CSR_HSTATEEN3  |
           CSR_HSTATEEN0H | CSR_HSTATEEN1H | CSR_HSTATEEN2H | CSR_HSTATEEN3H |
           CSR_FEATURES   | CSR_FEATURESH  | CSR_CCTRL      | CSR_FT         |
           -- Triggers CSRs affect firing/not firing in the following instructions
           CSR_TDATA1     | CSR_MCONTEXT   | CSR_SCONTEXT   | CSR_HCONTEXT =>
        category(2) := '1';
        -- To simplify PC logic, ensure that CSR writes that may require pipeline flush
        -- always issue alone (and put them always in the same pipe).
        category(0) := '1';
      when others => null;
    end case;

    -- Some CSR writes may not pair if issued in lane 0, since the behaviour
    -- may change for the very next instruction.
    -- Known examples are mret, sret and uret.
    -- Currently those are handled directly in dual_issue_check(), but
    -- perhaps they should be here instead?

    -- Some CSR writes affect following memory accesses.
    -- The following access must be delayed!
    --
    -- In the case of the FS/XS, FPU and/or other extension instructions may
    -- be enabled/disabled. Affects whether the next instruction is illegal!
    case addr is
      -- MSTATUS
      --   MBE     - switch endianness of following load/store
      --   MXR     - affects following load (allow/disable read from executable space)
      --   SUM     - affects following load/store (allow/disable access to user mode pages)
      --   MPRV    - affects following load/store (physical or virtual addressing in M-mode)
      --   FS/XS   - turning off FPU/ext could cause next instruction to fault
      -- SSTATUS
      --   MXR     - affects following load (allow/disable read from executable space)
      --   SUM     - affects following load/store (allow/disable access to user mode pages)
      --   FS/XS   - turning off FPU/ext which could cause next instruction to fault
      -- HSTATUS
      --   VSBE    - switch endianness of following hypervisor load/store
      --   SPVP    - affects privilege level of following hypervisor load/store
      --   HU      - affects following hypervisor load/store (allow/disable such in user mode)
      -- VSSTATUS
      --   Should not be included here since writes to it are only done in
      --   modes that are not affected by it!
      when CSR_MSTATUS   | CSR_MSTATUSH  | CSR_SSTATUS   | CSR_HSTATUS   |
           -- PMPCFG/PMPADDR affect memory protection.
           CSR_PMPCFG0   | CSR_PMPCFG1   | CSR_PMPCFG2   | CSR_PMPCFG3   |
           CSR_PMPADDR0  | CSR_PMPADDR1  | CSR_PMPADDR2  | CSR_PMPADDR3  |
           CSR_PMPADDR4  | CSR_PMPADDR5  | CSR_PMPADDR6  | CSR_PMPADDR7  |
           CSR_PMPADDR8  | CSR_PMPADDR9  | CSR_PMPADDR10 | CSR_PMPADDR11 |
           CSR_PMPADDR12 | CSR_PMPADDR13 | CSR_PMPADDR14 | CSR_PMPADDR15 |
           -- Special case!
           -- MIE/SIE/UIE can disable interrupts and the interrupt code relies on
           -- there being no load/store directly following that.
           CSR_MIE       | CSR_SIE       | CSR_UIE        | CSR_HIE      |
           CSR_HGEIE     |
           -- Changing delegation can also enable/disable an interrupt.
           CSR_MIDELEG | CSR_SIDELEG | CSR_HIDELEG =>
        category(1) := '1';
      when others => null;
    end case;

    -- FPU instructions in the pipeline must complete before the FPU flags
    -- can be read or written. Then the write needs to happen before any other
    -- FPU instructions may complete and modify them.
    -- For now, no FPU instructions are allowed in the pipeline together with
    -- any accesses to the FPU related CSRs.
    case addr is
      when CSR_FFLAGS | CSR_FCSR =>
        category(3) := '1';
      when others => null;
    end case;

    -- Writes to some CSR:s must take effect before a new FPU instruction is allowed.
    -- (FPU rounding mode can be read at any time.)
    case addr is
      when CSR_FFLAGS | CSR_FCSR | CSR_FRM =>
        category(4) := '1';
      when others => null;
    end case;

    -- Changes to interrupt enable must not dual-issue, to prevent interrupt
    --  traps from being taken in a pair with such a CSR write.
    -- Changing delegation can also enable/disable an interrupt.
    -- A paired instruction faulting would get the wrong exception vector.
    -- Setting of interrupt pending should normally not cause an interrupt
    --  in the current mode, but add those here to avoid any potential issue.
    -- Hold issue if there is a valid instruction in access stage and there
    -- is a CSR write instruction to interrupt related registers in execute.
    -- This way interrupt does not need to be checked in two different stages
    case addr is
      -- VSSTATUS, VSIE, VSIP, VSTVEC
      --   Should perhaps not be included here since writes to them are only
      --   done in modes that are not affected by them!
      when CSR_MSTATUS  | CSR_MIE  | CSR_MIP  | CSR_MIDELEG  | CSR_MTVEC  |
           CSR_HSTATUS  | CSR_HIE  | CSR_HIP  | CSR_HIDELEG  |
           CSR_SSTATUS  | CSR_SIE  | CSR_SIP  |                CSR_STVEC  |
           CSR_VSSTATUS | CSR_VSIE | CSR_VSIP |                CSR_VSTVEC |
           -- HGEIP is read-only
           CSR_HGEIE    | CSR_HVIP =>

        category(0) := '1';
        category(5) := '1';
      when others => null;
    end case;

    -- When reading MINSTRET/INSTRET we need to wait for all the previous instructions 
    -- that still in the pipeline to execute. Otherwise we would be reading a smaller 
    -- value.
    -- This logic can be applied with every counter. However, other counters are not
    -- strict as instret. For that reason a custom configuration bit has been added to
    -- decide if the pipeline should execute all pending instructions before reading any
    -- counter with a possible performance penalty or it should read the value stored 
    -- in the CSR in RA stage in order to be completely accurate.
    case addr is
      when CSR_MINSTRET  | CSR_MINSTRETH  |
           CSR_INSTRET   | CSR_INSTRETH   =>
        category(6) := '1'; -- Not dual issue when reading and enforce holding the pipeline
        category(0) := '1'; -- Not dual issue when writing
      when others => null;
    end case;
    if hpmc_mode = '0' then
      case addr is
        when CSR_MHPMCOUNTER3   |
             CSR_MHPMCOUNTER4   | CSR_MHPMCOUNTER5   | CSR_MHPMCOUNTER6   | CSR_MHPMCOUNTER7   |
             CSR_MHPMCOUNTER8   | CSR_MHPMCOUNTER9   | CSR_MHPMCOUNTER10  | CSR_MHPMCOUNTER11  |
             CSR_MHPMCOUNTER12  | CSR_MHPMCOUNTER13  | CSR_MHPMCOUNTER14  | CSR_MHPMCOUNTER15  |
             CSR_MHPMCOUNTER16  | CSR_MHPMCOUNTER17  | CSR_MHPMCOUNTER18  | CSR_MHPMCOUNTER19  |
             CSR_MHPMCOUNTER20  | CSR_MHPMCOUNTER21  | CSR_MHPMCOUNTER22  | CSR_MHPMCOUNTER23  |
             CSR_MHPMCOUNTER24  | CSR_MHPMCOUNTER25  | CSR_MHPMCOUNTER26  | CSR_MHPMCOUNTER27  |
             CSR_MHPMCOUNTER28  | CSR_MHPMCOUNTER29  | CSR_MHPMCOUNTER30  | CSR_MHPMCOUNTER31  |
             CSR_MHPMCOUNTER3H  |
             CSR_MHPMCOUNTER4H  | CSR_MHPMCOUNTER5H  | CSR_MHPMCOUNTER6H  | CSR_MHPMCOUNTER7H  |
             CSR_MHPMCOUNTER8H  | CSR_MHPMCOUNTER9H  | CSR_MHPMCOUNTER10H | CSR_MHPMCOUNTER11H |
             CSR_MHPMCOUNTER12H | CSR_MHPMCOUNTER13H | CSR_MHPMCOUNTER14H | CSR_MHPMCOUNTER15H |
             CSR_MHPMCOUNTER16H | CSR_MHPMCOUNTER17H | CSR_MHPMCOUNTER18H | CSR_MHPMCOUNTER19H |
             CSR_MHPMCOUNTER20H | CSR_MHPMCOUNTER21H | CSR_MHPMCOUNTER22H | CSR_MHPMCOUNTER23H |
             CSR_MHPMCOUNTER24H | CSR_MHPMCOUNTER25H | CSR_MHPMCOUNTER26H | CSR_MHPMCOUNTER27H |
             CSR_MHPMCOUNTER28H | CSR_MHPMCOUNTER29H | CSR_MHPMCOUNTER30H | CSR_MHPMCOUNTER31H |

             CSR_HPMCOUNTER3    |
             CSR_HPMCOUNTER4    | CSR_HPMCOUNTER5    | CSR_HPMCOUNTER6    | CSR_HPMCOUNTER7    |
             CSR_HPMCOUNTER8    | CSR_HPMCOUNTER9    | CSR_HPMCOUNTER10   | CSR_HPMCOUNTER11   |
             CSR_HPMCOUNTER12   | CSR_HPMCOUNTER13   | CSR_HPMCOUNTER14   | CSR_HPMCOUNTER15   |
             CSR_HPMCOUNTER16   | CSR_HPMCOUNTER17   | CSR_HPMCOUNTER18   | CSR_HPMCOUNTER19   |
             CSR_HPMCOUNTER20   | CSR_HPMCOUNTER21   | CSR_HPMCOUNTER22   | CSR_HPMCOUNTER23   |
             CSR_HPMCOUNTER24   | CSR_HPMCOUNTER25   | CSR_HPMCOUNTER26   | CSR_HPMCOUNTER27   |
             CSR_HPMCOUNTER28   | CSR_HPMCOUNTER29   | CSR_HPMCOUNTER30   | CSR_HPMCOUNTER31   |
             CSR_HPMCOUNTER3H   |
             CSR_HPMCOUNTER4H   | CSR_HPMCOUNTER5H   | CSR_HPMCOUNTER6H   | CSR_HPMCOUNTER7H   |
             CSR_HPMCOUNTER8H   | CSR_HPMCOUNTER9H   | CSR_HPMCOUNTER10H  | CSR_HPMCOUNTER11H  |
             CSR_HPMCOUNTER12H  | CSR_HPMCOUNTER13H  | CSR_HPMCOUNTER14H  | CSR_HPMCOUNTER15H  |
             CSR_HPMCOUNTER16H  | CSR_HPMCOUNTER17H  | CSR_HPMCOUNTER18H  | CSR_HPMCOUNTER19H  |
             CSR_HPMCOUNTER20H  | CSR_HPMCOUNTER21H  | CSR_HPMCOUNTER22H  | CSR_HPMCOUNTER23H  |
             CSR_HPMCOUNTER24H  | CSR_HPMCOUNTER25H  | CSR_HPMCOUNTER26H  | CSR_HPMCOUNTER27H  |
             CSR_HPMCOUNTER28H  | CSR_HPMCOUNTER29H  | CSR_HPMCOUNTER30H  | CSR_HPMCOUNTER31H  =>
            category(6) := '1'; -- Not dual issue when reading and enforce holding the pipeline
            category(0) := '1'; -- Not dual issue when writing
          when others => null;
        end case;
      end if;

      -- SIREG/SIREG4 can be employed to read performance counters and in that case, 
      -- previous instructions must be commited before reading the CSR.
      -- Writes and reads to this instructions must be single-issue for the same reason.
      case addr is
        when CSR_SIREG  =>
          category(7) := '1'; -- Not dual issue when reading and enforce holding the pipeline
          category(0) := '1'; -- Not dual issue when writing
        when CSR_SIREG4 =>
          if XLEN = 32 then
            category(7) := '1'; -- Not dual issue when reading and enforce holding the pipeline
            category(0) := '1'; -- Not dual issue when writing
          end if;
        when others => null;
      end case;

      -- Some CSR dependencies need to be extended by one/two extra cycle even
      -- if the instruction has already left WB stage.
      -- For instance: reading MTOPI after writing MTOPEI 
      -- Writing MTOPEI clears the IMSIC interrupt but there are 2 cycles of
      -- latency. When MIP.MEIP bit is set to 0 another extra cycle is needed
      -- to update MTOPI.
      case addr is
        when CSR_MTOPEI  | CSR_STOPEI   | CSR_VSTOPEI =>
          category(8) := '1';
        when others => null;
      end case;

    return category;
  end;


  function hpmc_ind_hold_check(virt : std_ulogic;
                               csr  : csr_reg_type;
                               hpmc_dep_cfg : std_ulogic) return boolean is
    -- Non-constant
    variable hold : boolean := false;
  begin
    -- SIREG/SIREG4 (VSIREG/VSIREG4) CSRs can access performance counters.
    -- Thus, we need to check in RA stage which address contains
    -- SISELECT/VSISELECT to decide if we should hold the pipeline until all previous 
    -- instructions have committed.
    -- When reading INSTRET CSR, all the previous instructions in the pipeline must
    -- be committed before reading the INSTRET value.
    -- For other CSRs, there is a configuration bits to select between accurate results
    -- waiting for all remaining instructions to commit before reading any HPMCounter and
    -- performance where the pipeline is only hold for INSTRET reads.
    if virt = '0' then
      -- Suervisor CSRs
      if hpmc_dep_cfg = '1' then
        if csr.siselect.sel = x"042" then
          hold := true;
        end if;
      else
        if csr.siselect.sel(7 downto 4) = x"4" or csr.siselect.sel(7 downto 4) = x"5" then
          hold := true;
        end if;
      end if;
    else
      -- Virtual Suervisor CSRs
      -- HPMCOUNTERS can be accessed through indirect accessed registers only
      -- in VS mode (through sireg* CSRs).
      if hpmc_dep_cfg = '1' then
        if csr.vsiselect.sel = x"042" then
          hold := true;
        end if;
      else
        if csr.vsiselect.sel(7 downto 4) = x"4" or csr.vsiselect.sel(7 downto 4) = x"5" then
          hold := true;
        end if;
      end if;
    end if;

    return hold;
  end;

  function csr_raw_category(addr : csratype) return raw_category_t is
    -- Non-constant
    variable category : raw_category_t := (others => '0');
  begin
    -- RaW category dependencies
      -- Writes to any in the numbered category affect all.
    case addr is
      when CSR_MSTATUS | CSR_MSTATUSH | CSR_SSTATUS | CSR_USTATUS =>
        category(0) := '1';
      when others =>
    end case;
    case addr is
      -- Category 0, among others, signals dependencies between *TOPEI, *IP, *IE 
      -- and *TOPI registers. This dependencies appear only when AIA is implemented.
      -- For instance, MTOPI depends on MIE and MIP. Or MIP depends on MTOPEI, since
      -- writes to MTOPEI can clear MIP.MEIP. For this reason, MTOPI depends also
      -- on MTOPEI, and wrting to MTOPEI could affect a read to MTOPI. A buble must be
      -- inserted for reads that come after a write.
      when CSR_MIE     | CSR_SIE      | CSR_VSIE    | CSR_HIE  | CSR_UIE  |
           CSR_MIDELEG | CSR_SIDELEG  | CSR_HIDELEG | 
           CSR_MIP     | CSR_SIP      | CSR_VSIP    | CSR_HIP  | CSR_UIP  |
           CSR_MVIEN   | CSR_HVIEN    |
           CSR_MVIP    | CSR_HVIP     |
           CSR_MTOPEI  | CSR_STOPEI   | CSR_VSTOPEI |
           CSR_MTOPI   | CSR_STOPI    | CSR_VSTOPI   =>
        category(1) := '1';
      when others =>
    end case;
    case addr is
      when CSR_FFLAGS  | CSR_FRM | CSR_FCSR =>
        category(2) := '1';
      when others =>
    end case;
    
    case addr is
      -- Writes to the first in the numbered category affect the rest.
      -- But putting them all in a single category should not matter for performance.

      -- If a write to any of these causes a timer to be disabled, it would be strange
      -- if two immediately following reads of that timer give different results.
      -- Changes to these can be handled by holding the pipeline, since it should not
      -- matter if the writes are somewhat slow.
      -- With the introduction of smcdeleg counters can also be affected through indirect
      -- CSR accesses.
      when CSR_MCOUNTINHIBIT  | CSR_SCOUNTINHIBIT  | CSR_SCOUNTOVF      | CSR_MHPMEVENT3     |
           CSR_MHPMEVENT4     | CSR_MHPMEVENT5     | CSR_MHPMEVENT6     | CSR_MHPMEVENT7     |
           CSR_MHPMEVENT8     | CSR_MHPMEVENT9     | CSR_MHPMEVENT10    | CSR_MHPMEVENT11    |
           CSR_MHPMEVENT12    | CSR_MHPMEVENT13    | CSR_MHPMEVENT14    | CSR_MHPMEVENT15    |
           CSR_MHPMEVENT16    | CSR_MHPMEVENT17    | CSR_MHPMEVENT18    | CSR_MHPMEVENT19    |
           CSR_MHPMEVENT20    | CSR_MHPMEVENT21    | CSR_MHPMEVENT22    | CSR_MHPMEVENT23    |
           CSR_MHPMEVENT24    | CSR_MHPMEVENT25    | CSR_MHPMEVENT26    | CSR_MHPMEVENT27    |
           CSR_MHPMEVENT28    | CSR_MHPMEVENT29    | CSR_MHPMEVENT30    | CSR_MHPMEVENT31    |
           CSR_MHPMEVENT3H    |
           CSR_MHPMEVENT4H    | CSR_MHPMEVENT5H    | CSR_MHPMEVENT6H    | CSR_MHPMEVENT7H    |
           CSR_MHPMEVENT8H    | CSR_MHPMEVENT9H    | CSR_MHPMEVENT10H   | CSR_MHPMEVENT11H   |
           CSR_MHPMEVENT12H   | CSR_MHPMEVENT13H   | CSR_MHPMEVENT14H   | CSR_MHPMEVENT15H   |
           CSR_MHPMEVENT16H   | CSR_MHPMEVENT17H   | CSR_MHPMEVENT18H   | CSR_MHPMEVENT19H   |
           CSR_MHPMEVENT20H   | CSR_MHPMEVENT21H   | CSR_MHPMEVENT22H   | CSR_MHPMEVENT23H   |
           CSR_MHPMEVENT24H   | CSR_MHPMEVENT25H   | CSR_MHPMEVENT26H   | CSR_MHPMEVENT27H   |
           CSR_MHPMEVENT28H   | CSR_MHPMEVENT29H   | CSR_MHPMEVENT30H   | CSR_MHPMEVENT31H   |
      -- Writes to M<x> should be immediately visible in <x>.
      -- The <x> cannot be written at all.
           CSR_MCYCLE         | CSR_MINSTRET       | CSR_MHPMCOUNTER3   |
           CSR_MHPMCOUNTER4   | CSR_MHPMCOUNTER5   | CSR_MHPMCOUNTER6   | CSR_MHPMCOUNTER7   |
           CSR_MHPMCOUNTER8   | CSR_MHPMCOUNTER9   | CSR_MHPMCOUNTER10  | CSR_MHPMCOUNTER11  |
           CSR_MHPMCOUNTER12  | CSR_MHPMCOUNTER13  | CSR_MHPMCOUNTER14  | CSR_MHPMCOUNTER15  |
           CSR_MHPMCOUNTER16  | CSR_MHPMCOUNTER17  | CSR_MHPMCOUNTER18  | CSR_MHPMCOUNTER19  |
           CSR_MHPMCOUNTER20  | CSR_MHPMCOUNTER21  | CSR_MHPMCOUNTER22  | CSR_MHPMCOUNTER23  |
           CSR_MHPMCOUNTER24  | CSR_MHPMCOUNTER25  | CSR_MHPMCOUNTER26  | CSR_MHPMCOUNTER27  |
           CSR_MHPMCOUNTER28  | CSR_MHPMCOUNTER29  | CSR_MHPMCOUNTER30  | CSR_MHPMCOUNTER31  |
           CSR_MCYCLEH        | CSR_MINSTRETH      | CSR_MHPMCOUNTER3H  |
           CSR_MHPMCOUNTER4H  | CSR_MHPMCOUNTER5H  | CSR_MHPMCOUNTER6H  | CSR_MHPMCOUNTER7H  |
           CSR_MHPMCOUNTER8H  | CSR_MHPMCOUNTER9H  | CSR_MHPMCOUNTER10H | CSR_MHPMCOUNTER11H |
           CSR_MHPMCOUNTER12H | CSR_MHPMCOUNTER13H | CSR_MHPMCOUNTER14H | CSR_MHPMCOUNTER15H |
           CSR_MHPMCOUNTER16H | CSR_MHPMCOUNTER17H | CSR_MHPMCOUNTER18H | CSR_MHPMCOUNTER19H |
           CSR_MHPMCOUNTER20H | CSR_MHPMCOUNTER21H | CSR_MHPMCOUNTER22H | CSR_MHPMCOUNTER23H |
           CSR_MHPMCOUNTER24H | CSR_MHPMCOUNTER25H | CSR_MHPMCOUNTER26H | CSR_MHPMCOUNTER27H |
           CSR_MHPMCOUNTER28H | CSR_MHPMCOUNTER29H | CSR_MHPMCOUNTER30H | CSR_MHPMCOUNTER31H |
           -- Affect
           CSR_CYCLE          | CSR_INSTRET        | CSR_HPMCOUNTER3    |
           CSR_HPMCOUNTER4    | CSR_HPMCOUNTER5    | CSR_HPMCOUNTER6    | CSR_HPMCOUNTER7    |
           CSR_HPMCOUNTER8    | CSR_HPMCOUNTER9    | CSR_HPMCOUNTER10   | CSR_HPMCOUNTER11   |
           CSR_HPMCOUNTER12   | CSR_HPMCOUNTER13   | CSR_HPMCOUNTER14   | CSR_HPMCOUNTER15   |
           CSR_HPMCOUNTER16   | CSR_HPMCOUNTER17   | CSR_HPMCOUNTER18   | CSR_HPMCOUNTER19   |
           CSR_HPMCOUNTER20   | CSR_HPMCOUNTER21   | CSR_HPMCOUNTER22   | CSR_HPMCOUNTER23   |
           CSR_HPMCOUNTER24   | CSR_HPMCOUNTER25   | CSR_HPMCOUNTER26   | CSR_HPMCOUNTER27   |
           CSR_HPMCOUNTER28   | CSR_HPMCOUNTER29   | CSR_HPMCOUNTER30   | CSR_HPMCOUNTER31   |
           CSR_CYCLEH         | CSR_INSTRETH       | CSR_HPMCOUNTER3H   |
           CSR_HPMCOUNTER4H   | CSR_HPMCOUNTER5H   | CSR_HPMCOUNTER6H   | CSR_HPMCOUNTER7H   |
           CSR_HPMCOUNTER8H   | CSR_HPMCOUNTER9H   | CSR_HPMCOUNTER10H  | CSR_HPMCOUNTER11H  |
           CSR_HPMCOUNTER12H  | CSR_HPMCOUNTER13H  | CSR_HPMCOUNTER14H  | CSR_HPMCOUNTER15H  |
           CSR_HPMCOUNTER16H  | CSR_HPMCOUNTER17H  | CSR_HPMCOUNTER18H  | CSR_HPMCOUNTER19H  |
           CSR_HPMCOUNTER20H  | CSR_HPMCOUNTER21H  | CSR_HPMCOUNTER22H  | CSR_HPMCOUNTER23H  |
           CSR_HPMCOUNTER24H  | CSR_HPMCOUNTER25H  | CSR_HPMCOUNTER26H  | CSR_HPMCOUNTER27H  |
           CSR_HPMCOUNTER28H  | CSR_HPMCOUNTER29H  | CSR_HPMCOUNTER30H  | CSR_HPMCOUNTER31H  |
           CSR_MIREG          | CSR_MIREG2         | CSR_MIREG3         | CSR_MIREG4         |
           CSR_MIREG5         | CSR_MIREG6         | CSR_MISELECT       | CSR_MTOPEI         |
           CSR_SIREG          | CSR_SIREG2         | CSR_SIREG3         | CSR_SIREG4         |
           CSR_SIREG5         | CSR_SIREG6         | CSR_SISELECT       | CSR_STOPEI         |
           CSR_VSIREG         | CSR_VSIREG2        | CSR_VSIREG3        | CSR_VSIREG4        |
           CSR_VSIREG5        | CSR_VSIREG6        | CSR_VSISELECT      | CSR_VSTOPEI        |
           CSR_HGEIP          | CSR_HSTATUS        | CSR_MTOPI          | CSR_STOPI          |
           CSR_MENVCFG        | CSR_SENVCFG        | CSR_HENVCFG =>
             category(3) :='1';
      when others =>
    end case;


    case addr is
      -- Changes to TSELECT will cause TDATAn to return different things.
      when CSR_TSELECT   |
           -- Affects
           CSR_TDATA1    | CSR_TDATA2    | CSR_TDATA3 | CSR_TINFO =>
        category(4) := '1';
      when others =>
    end case;

    case addr is
      -- The setting in PMPCFG affects values read from PMPADDR.
      when CSR_PMPCFG0   | CSR_PMPCFG1   | CSR_PMPCFG2   | CSR_PMPCFG3   |
           -- Affect
           CSR_PMPADDR0  | CSR_PMPADDR1  | CSR_PMPADDR2  | CSR_PMPADDR3  |
           CSR_PMPADDR4  | CSR_PMPADDR5  | CSR_PMPADDR6  | CSR_PMPADDR7  |
           CSR_PMPADDR8  | CSR_PMPADDR9  | CSR_PMPADDR10 | CSR_PMPADDR11 |
           CSR_PMPADDR12 | CSR_PMPADDR13 | CSR_PMPADDR14 | CSR_PMPADDR15 =>
        category(5) := '1';
      when others =>
    end case;

    return category;
  end;


  function csr_waw_category(addr : csratype) return waw_category_t is
    -- Non-constant
    variable category : waw_category_t := (others => '0');
  begin
     case addr is
      -- This set of CSRs have a Write after Write (WaW) dependency.
      -- For instance: 
      -- A write to *IREG* CSR depends on a previous pending *ISELECT*
      -- CSR write.
      -- A write to the HSTATUS.VGEIN field modifies the behavior of a 
      -- subsequent write to the VSIREG register
      when CSR_MIREG    | CSR_MIREG2   | CSR_MIREG3     | CSR_MIREG4   |
           CSR_MIREG5   | CSR_MIREG6   | CSR_MISELECT   | CSR_MTOPEI   |
           CSR_SIREG    | CSR_SIREG2   | CSR_SIREG3     | CSR_SIREG4   |
           CSR_SIREG5   | CSR_SIREG6   | CSR_SISELECT   | CSR_STOPEI   |
           CSR_VSIREG   | CSR_VSIREG2  | CSR_VSIREG3    | CSR_VSIREG4  |
           CSR_VSIREG5  | CSR_VSIREG6  | CSR_VSISELECT  | CSR_VSTOPEI  =>
             category(0) := '1';
      when others =>
    end case;

    return category;
  end;



  function csr_access_addr(inst : word) return csratype is
    variable addr : csratype := funct12(inst);
  begin
    return addr;
  end;

  function csr_addr(active : extension_type; inst : word) return csratype is
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable funct7      : funct7_type  := funct7(inst);
    variable funct12     : funct12_type := funct12(inst);
  begin
    if ext_zicfiss and is_system1(inst) and
       (funct12 = F12_SSRDPOPCHK or funct7 = F7_SSPUSH) then
      return CSR_SSP;
    else
      return csr_access_addr(inst);
    end if;
  end;

  function require_envcfg(mode_s : boolean;
                          prv    : priv_lvl_type;
                          virt   : boolean;
                          m      : boolean;
                          h      : boolean;
                          s      : boolean )
                          return xc_type is
  begin
    -- HS/U/VS/VU
    -- menvcfg = '0' => illegal
    -- U mode with S_mode implemented
    if (prv /= PRIV_LVL_M and not m) or (mode_s and (prv = PRIV_LVL_U and not virt) and not s) then
      return XC_ILLEGAL;
    -- VS/VU
    -- henvcfg = '0' => virtual
    -- VU
    -- senvcfg = '0' => virtual
    elsif virt and (not h or (prv = PRIV_LVL_U and not s)) then
      return XC_VIRT;
    end if;
    return XC_NONE;
  end;

  function require_envcfg(mode_s : boolean;
                          prv    : priv_lvl_type;
                          virt   : std_logic;
                          m      : std_logic;
                          h      : std_logic;
                          s      : std_logic )
                          return xc_type is
  begin
    return require_envcfg(mode_s, prv, virt = '1', m = '1', h = '1', s = '1');
  end;

  function is_csr_high_half(csra : csratype) return boolean is
  begin
    case csra is
      when CSR_USCRATCH       | CSR_CYCLEH         |
           CSR_TIMEH          | CSR_INSTRETH       | CSR_HPMCOUNTER3H   |
           CSR_HPMCOUNTER4H   | CSR_HPMCOUNTER5H   | CSR_HPMCOUNTER6H   |
           CSR_HPMCOUNTER7H   | CSR_HPMCOUNTER8H   | CSR_HPMCOUNTER9H   |
           CSR_HPMCOUNTER10H  | CSR_HPMCOUNTER11H  | CSR_HPMCOUNTER12H  |
           CSR_HPMCOUNTER13H  | CSR_HPMCOUNTER14H  | CSR_HPMCOUNTER15H  |
           CSR_HPMCOUNTER16H  | CSR_HPMCOUNTER17H  | CSR_HPMCOUNTER18H  |
           CSR_HPMCOUNTER19H  | CSR_HPMCOUNTER20H  | CSR_HPMCOUNTER21H  |
           CSR_HPMCOUNTER22H  | CSR_HPMCOUNTER23H  | CSR_HPMCOUNTER24H  |
           CSR_HPMCOUNTER25H  | CSR_HPMCOUNTER26H  | CSR_HPMCOUNTER27H  |
           CSR_HPMCOUNTER28H  | CSR_HPMCOUNTER29H  | CSR_HPMCOUNTER30H  |
           CSR_HPMCOUNTER31H  | CSR_SIEH           | CSR_SIPH           |
           CSR_STIMECMPH      | CSR_HENVCFGH       | CSR_HTIMEDELTAH    |
           CSR_VSTIMECMPH     | CSR_HIDELEGH       | CSR_HVIENH         |
           CSR_HVIPH          | CSR_HVIPRIO1H      | CSR_HVIPRIO2H      |
           CSR_VSIEH          | CSR_VSIPH          | CSR_HSTATEEN0H     |
           CSR_HSTATEEN1H     | CSR_HSTATEEN2H     | CSR_HSTATEEN3H     |
           CSR_MSTATUSH       | CSR_MIDELEGH       | CSR_MIEH           |
           CSR_MVIENH         | CSR_MVIPH          | CSR_MIPH           |
           CSR_MSTATEEN0H     | CSR_MSTATEEN1H     | CSR_MSTATEEN2H     |
           CSR_MSTATEEN3H     | CSR_MENVCFGH       | CSR_MSECCFGH       |
           CSR_MCYCLEH        | CSR_MINSTRETH      | CSR_MHPMCOUNTER3H  |
           CSR_MHPMCOUNTER4H  | CSR_MHPMCOUNTER5H  | CSR_MHPMCOUNTER6H  |
           CSR_MHPMCOUNTER7H  | CSR_MHPMCOUNTER8H  | CSR_MHPMCOUNTER9H  |
           CSR_MHPMCOUNTER10H | CSR_MHPMCOUNTER11H | CSR_MHPMCOUNTER12H |
           CSR_MHPMCOUNTER13H | CSR_MHPMCOUNTER14H | CSR_MHPMCOUNTER15H |
           CSR_MHPMCOUNTER16H | CSR_MHPMCOUNTER17H | CSR_MHPMCOUNTER18H |
           CSR_MHPMCOUNTER19H | CSR_MHPMCOUNTER20H | CSR_MHPMCOUNTER21H |
           CSR_MHPMCOUNTER22H | CSR_MHPMCOUNTER23H | CSR_MHPMCOUNTER24H |
           CSR_MHPMCOUNTER25H | CSR_MHPMCOUNTER26H | CSR_MHPMCOUNTER27H |
           CSR_MHPMCOUNTER28H | CSR_MHPMCOUNTER29H | CSR_MHPMCOUNTER30H |
           CSR_MHPMCOUNTER31H | CSR_MHPMEVENT3H    | CSR_MHPMEVENT4H    |
           CSR_MHPMEVENT5H    | CSR_MHPMEVENT6H    | CSR_MHPMEVENT7H    |
           CSR_MHPMEVENT8H    | CSR_MHPMEVENT9H    | CSR_MHPMEVENT10H   |
           CSR_MHPMEVENT11H   | CSR_MHPMEVENT12H   | CSR_MHPMEVENT13H   |
           CSR_MHPMEVENT14H   | CSR_MHPMEVENT15H   | CSR_MHPMEVENT16H   |
           CSR_MHPMEVENT17H   | CSR_MHPMEVENT18H   | CSR_MHPMEVENT19H   |
           CSR_MHPMEVENT20H   | CSR_MHPMEVENT21H   | CSR_MHPMEVENT22H   |
           CSR_MHPMEVENT23H   | CSR_MHPMEVENT24H   | CSR_MHPMEVENT25H   |
           CSR_MHPMEVENT26H   | CSR_MHPMEVENT27H   | CSR_MHPMEVENT28H   |
           CSR_MHPMEVENT29H   | CSR_MHPMEVENT30H   | CSR_MHPMEVENT31H   |
           CSR_FEATURESH      | CSR_CCTRLH         | CSR_TCMICTRLH      |
           CSR_TCMDCTRLH      | CSR_FTH            | CSR_EINJECTH       |
           CSR_DFEATURESH     | CSR_CAPABILITYH    | CSR_PMPCFG1        |
           CSR_PMPCFG3        | CSR_HEDELEGH =>
        return true;
      when others =>
        return false;
    end case;
end function;

  -- Zicfiss CSR accessibility
  function zicfiss_csr_xc(csra        : csratype;
                          csr         : csr_reg_type;
                          ext_zicfiss : boolean;
                          mode_s      : boolean)
                          return xc_type is
    variable mSSE : std_ulogic := csr.menvcfg.sse;
    variable sSSE : std_ulogic := csr.senvcfg.sse;
    variable hSSE : std_ulogic := csr.henvcfg.sse;
    variable v    : std_ulogic := csr.v;
    variable prv  : priv_lvl_type := csr.prv;
  begin
    assert csra = CSR_SSP report "Called for incorrect CSR " & tost(csra) severity failure;
	  if not ext_zicfiss then
	    return XC_ILLEGAL;
	  end if;
	  return require_envcfg(mode_s, prv, v, mSSE, hSSE, sSSE);
  end;

  function smcsrind_reg_xc(csr_file   : csr_reg_type;
                           csra       : csratype;
                           active     : extension_type;
                           imsic      : boolean) return xc_type is
    variable ext_smcsrind  : boolean := is_enabled(active, x_smcsrind);
    variable ext_smaia     : boolean := is_enabled(active, x_smaia);
    variable ext_noelv     : boolean := is_enabled(active, x_noelv);
    variable is_rv64       : boolean := is_enabled(active, x_rv64);
    variable x_en          : boolean := csr_file.misa(x_ctrl) = '1';
  begin
    -- Only mireg has implemented indirect CSRs. The spec recomends raising illegal
    -- if miselect points to a range which is not implemented, mireg[2-6] can thus
    -- not have a legal select value and we can return early.
    if csra /= CSR_MIREG then
      return XC_ILLEGAL;
    end if;
    if ext_smcsrind then
      if not is_custom(csr_file.miselect) then
        if is_imsic(csr_file.miselect) then
          if not ext_smaia or intFile_addrExcp(csr_file.miselect, u2i(imsic), is_rv64) = '1' then
            return XC_ILLEGAL;
          end if;
        elsif is_aia_iprio(csr_file.miselect) then
          if is_rv64 and csr_file.miselect.sel(0) = '1' then
            -- only even values are allowed
            return XC_ILLEGAL;
          end if;
        else
          return XC_ILLEGAL;
        end if;
      else -- custom
          return XC_ILLEGAL;
      end if;
    else
      return XC_ILLEGAL;
    end if;

    return XC_NONE;
  end function;

  function sscsrind_reg_xc(stateen_xc : xc_type;
                         csr_file   : csr_reg_type;
                         csra       : csratype;
                         active     : extension_type;
                         perf_cnts  : integer;
                         imsic      : boolean)
                         return xc_type is
    variable ext_smstateen     : boolean := is_enabled(active, x_smstateen);
    variable ext_sscsrind      : boolean := is_enabled(active, x_sscsrind);
    variable mode_s            : boolean := is_enabled(active, x_mode_s);
    variable is_rv64           : boolean := is_enabled(active, x_rv64);
    variable ext_smcdeleg      : boolean := is_enabled(active, x_smcdeleg);
    variable ext_sscofpmf      : boolean := is_enabled(active, x_sscofpmf);
    variable h_en              : boolean := csr_file.misa(h_ctrl) = '1';
    variable v_mode            : boolean := h_en and csr_file.v = '1';
    variable ext_zicntr        : boolean := true;  -- No bit for this
    variable ext_smcntrpmf     : boolean := false; -- No bit for this
    variable ext_zihpm         : boolean := perf_cnts > 0;
    variable csrind_stateen_xc : xc_type := csrind_check_stateen_xc(csra, csr_file, ext_smstateen, mode_s);
    variable is_vsi            : boolean := is_vsireg(csra);
    -- Non-constant
    variable sel               : select_t;
  begin
    if not ext_sscsrind then
      -- Illegal if csrind isn't implemented
      return XC_ILLEGAL;
    end if;

    -- Choose the correct select value
    -- Implicitly vsiselect if v_mode or explicitly if the access was to vsireg*
    if is_vsi or v_mode then
      sel := csr_file.vsiselect;
    else
      assert is_sireg(csra);
      sel := csr_file.siselect;
    end if;

    -- Stateen prevents access to sireg/vsireg, pre-calculated from call site
    assert not(stateen_xc.xc and not ext_smstateen)
    report "stateen can't throw illegal without ext_stateen" severity failure;
    if stateen_xc.xc then
      return stateen_xc;
    end if;

    -- We need to apply a second stateen check to the proxy csr pointed to by (v)siselect.
    assert not(csrind_stateen_xc.xc and not ext_smstateen)
    report "proxy stateen can't throw illegal without ext_stateen" severity failure;
    if csrind_stateen_xc.xc then
      return csrind_stateen_xc;
    end if;

    -- A virtual instruction exception is raised for attempts from VS-mode or VU-mode to directly access
    -- vsireg*, or attempts from VU-mode to access siselect or sireg*.
    if v_mode then
      if is_vsi then
        return XC_VIRT;
      else -- CSR_SIREG*
        if csr_file.prv = PRIV_LVL_U then
          return XC_VIRT;
        end if;
      end if;
      assert csr_file.prv = PRIV_LVL_S report "Only VS mode can pass through this check";
    end if;

    if not is_custom(sel) then
      -- Call specific exception logic based on select
      if is_aia_iprio(sel) and csra = CSR_VSIREG then
        return XC_ILLEGAL;
      elsif (is_imsic(sel) or is_aia_iprio(sel)) and (csra = CSR_SIREG or csra = CSR_VSIREG) then
        return ssaia_indirect_xc(csr_file, sel, active, imsic);
      elsif is_smcdeleg(sel) then
        return smcdeleg_indirect_xc(csr_file, ext_smcdeleg, ext_sscofpmf, ext_zicntr,
                                    ext_zihpm, ext_smcntrpmf, is_rv64, csra, v_mode);
      else
        -- Address is not defined => illegal
        return XC_ILLEGAL;
      end if;
    else -- Custom CSRs goes here
      return XC_ILLEGAL;
    end if;

    return XC_NONE;

  end function;

  function basic_csr_xc_check(csra     : csratype;
                              csr_file : csr_reg_type;
                              h_en     : boolean;
                              mode_s   : boolean) return xc_type is
    constant CSR_PRV_HS     : priv_lvl_type := "10";
    variable csr_priv       : priv_lvl_type := csra(9 downto 8);
    -- Non-constant
    variable effective_priv : priv_lvl_type := csr_file.prv;
  begin
    -- Determine effective CSR privilege, if not virtualized and in S mode we have access to H CSRs.
    if csr_file.prv = PRIV_LVL_S and csr_file.v = '0' then
      effective_priv := CSR_PRV_HS;
    end if;

    -- Access to S register without the priv mode implemented
    if csr_priv = PRIV_LVL_S and not mode_s  then
      return XC_ILLEGAL;
    end if;

    -- Access to HS register without the priv mode implemented/enabled
    if csr_priv = CSR_PRV_HS and not h_en then
      return XC_ILLEGAL;
    end if;

    -- Never okay to access a more privileged CSR!
    if effective_priv < csr_priv then
      -- HS Qualified?
      if csr_priv <= CSR_PRV_HS and csr_file.v = '1' then
        -- Only CSRs accessible to the Hypervisor should end up here.
        return XC_VIRT;
      end if;
      return XC_ILLEGAL;
    end if;
    return XC_NONE;

  end function;

  function csr_xc_check(csra_in     : csratype;
                        is_write    : boolean;
                        active      : extension_type;
                        csr_file    : csr_reg_type;
                        rstate_in   : core_state;
                        imsic       : boolean;
                        pmp_entries : integer;
                        perf_cnts   : integer;
                        trigger     : integer
                       ) return xc_type is
    variable ext_zicfiss   : boolean    := is_enabled(active, x_zicfiss);
    variable ext_zicfilp   : boolean    := is_enabled(active, x_zicfilp);
    variable ext_f         : boolean    := is_enabled(active, x_f);
    variable ext_smaia     : boolean    := is_enabled(active, x_smaia);
    variable ext_ssaia     : boolean    := is_enabled(active, x_ssaia);
    variable ext_smstateen : boolean    := is_enabled(active, x_smstateen);
    variable ext_smcsrind  : boolean    := is_enabled(active, x_smcsrind);
    variable ext_sscsrind  : boolean    := is_enabled(active, x_sscsrind);
    variable ext_smcdeleg  : boolean    := is_enabled(active, x_smcdeleg);
    variable ext_ssdbltrp  : boolean    := is_enabled(active, x_ssdbltrp);
    variable ext_sscofpmf  : boolean    := is_enabled(active, x_sscofpmf);
    variable ext_smrnmi    : boolean    := is_enabled(active, x_smrnmi);
    variable ext_smepmp    : boolean    := is_enabled(active, x_smepmp);
    variable ext_sstc      : boolean    := is_enabled(active, x_sstc);
    variable mode_u        : boolean    := is_enabled(active, x_mode_u);
    variable mode_s        : boolean    := is_enabled(active, x_mode_s);
    variable is_rv64       : boolean    := is_enabled(active, x_rv64);
    variable time_en       : boolean    := ext_sstc;
    variable h_en          : boolean    := csr_file.misa(h_ctrl) = '1';
    variable x_en          : boolean    := csr_file.misa(x_ctrl) = '1';
    variable v_mode        : boolean    := h_en and csr_file.v = '1';
    variable vu_mode       : boolean    := v_mode and csr_file.prv = PRIV_LVL_U;
    variable csra_high     : csratype   := csra_in(csra_in'high downto 4) & "0000";
    variable csra_low      : integer    := u2i(csra_in(3 downto 0));
    variable counter_idx   : integer    := u2i(csra_in(4 downto 0));
    variable is_high_half  : boolean    := is_csr_high_half(csra_in);
    variable read_only     : boolean    := csra_in(11 downto 10) = "11";
    variable stateen_xc    : xc_type    := check_stateen_xc(
                                             get_stateen_bits(csra_in, csr_file),
                                             csr_file.prv,
                                             v_mode,
                                             ext_smstateen,
                                             mode_s);
    -- Non-constant
    variable timecmp_xc    : xc_type    := XC_NONE;
    variable ireg_xc       : xc_type    := XC_NONE;
    variable base_xc       : xc_type    := XC_NONE;
  begin

    -- Never ok to access high-half when RV64
    if is_rv64 and is_high_half then
      return XC_ILLEGAL;
    end if;

    -- Always illegal to write RO CSR.
    if is_write and read_only then
      return XC_ILLEGAL;
    end if;

    -- Check basic csr address properties, raise virtual for HS-qualified CSR
    -- We can't return immediately since for example stateen triumphs the rules
    -- for HS-qualified.
    base_xc := basic_csr_xc_check(csra_in, csr_file, h_en, mode_s);

    -- Sanity check
    assert not(v_mode and not h_en)
    report "Impossible to be virtualized without misa.h" severity failure;

    assert not(stateen_xc /= XC_NONE and not ext_smstateen)
    report "stateen can't throw without ext_stateen" severity failure;

    assert not(csra_in(9 downto 8) = PRIV_LVL_U and base_xc.xc)
    report "U mode csr can't throw" severity failure;

    -- It should not be possible for stateen to raise a virtual instruction if base_xc reports illegal!
    -- base_xc reports illegal if mode_s or h_en is disabled or if permission is not sufficient for the access.
    assert not(stateen_xc = XC_VIRT and base_xc = XC_ILLEGAL) severity error;
    -- Stateen only applies to modes lower than M
    assert not(stateen_xc /= XC_NONE and csr_file.prv = PRIV_LVL_M) severity error;

    -- For most CSRs the base_xc check is what should be checked first.
    -- Howevever the spec lists a few cases where the normal HS qualified rule is overriden.
    -- These cases must first check the overriding rule and then base_xc.
    -- The "when" statements follow the following structure,
    -- 1) is extension implemented, if not return illegal (H and S included in base_xc).
    -- 2) has base_xc thrown an exception (not always applicable)
    -- 3) Check stateen if applicable
    -- 4) Check any other requirements such as envcfg
    -- 5) Return base_xc

    case csra_in is
      when CSR_DCSR | CSR_DPC | CSR_DSCRATCH0 | CSR_DSCRATCH1 =>
        -- Only accessible in debug mode
        return xc_type'(xc => rstate_in = run, xc_v => false);
      -- User Floating-Point CSRs
      when CSR_FFLAGS | CSR_FRM | CSR_FCSR =>
        if not ext_f then
          return XC_ILLEGAL;
        end if;
        -- FPU not enabled
        if csr_file.mstatus.fs = "00" or (v_mode and csr_file.vsstatus.fs = "00") then
          return XC_ILLEGAL;
        end if;
      when CSR_HSTATUS    | CSR_HEDELEG    | CSR_HIDELEG     | CSR_HIE |
           CSR_HCOUNTEREN | CSR_HGEIE      | CSR_HTVAL       | CSR_HIP |
           CSR_HVIP       | CSR_HTINST     | CSR_HGEIP       |
           CSR_HTIMEDELTA | CSR_HTIMEDELTAH =>
        return base_xc;
      -- Hypervisor Protection and Translation
      when CSR_HGATP          =>
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        if csr_file.prv = PRIV_LVL_S and csr_file.mstatus.tvm = '1' then
          assert not v_mode report "VS/VU should already have trapped";
          return XC_ILLEGAL;
        end if;
      -- Virtual Supervisor Registers
      when CSR_VSSTATUS  | CSR_VSIE   | CSR_VSTVEC | CSR_VSSCRATCH | CSR_VSEPC |
           CSR_VSCAUSE   | CSR_VSTVAL | CSR_VSIP   | CSR_VSATP =>
        return base_xc;
      -- CSRs which needs stateen checks
      when CSR_HENVCFGH | CSR_HENVCFG  | CSR_SENVCFG |
           CSR_SCONTEXT | CSR_HCONTEXT | CSR_HEDELEGH =>
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        return base_xc;
      -- AIA registers
      when CSR_STOPI     | CSR_HIDELEGH  | CSR_HVIEN    | CSR_HVIENH    |
           CSR_HVIPH     | CSR_HVICTL    | CSR_HVIPRIO1 | CSR_HVIPRIO1H |
           CSR_HVIPRIO2  | CSR_HVIPRIO2H | CSR_VSIPH    | CSR_VSIEH     |
           CSR_VSTOPI =>
        -- SIEH and SIPH also need to check hvictl.vti and are thus not included
        if not ext_ssaia then
          return XC_ILLEGAL;
        end if;
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        return base_xc;
      -- Hypervisor/Supervisor Sstateen extension CSRs
      when CSR_HSTATEEN0  | CSR_HSTATEEN1  | CSR_HSTATEEN2  | CSR_HSTATEEN3 |
           CSR_SSTATEEN0  | CSR_SSTATEEN1  | CSR_SSTATEEN2  | CSR_SSTATEEN3 |
           CSR_HSTATEEN0H | CSR_HSTATEEN1H | CSR_HSTATEEN2H | CSR_HSTATEEN3H =>
        if not ext_smstateen then
          return XC_ILLEGAL;
        end if;
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        return base_xc;
      -- Csrind registers
      when CSR_VSISELECT | CSR_SISELECT     =>
        if not ext_sscsrind then
          return XC_ILLEGAL;
        end if;
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        return base_xc;
      when CSR_SIREG  | CSR_VSIREG  | CSR_SIREG2 | CSR_VSIREG2 |
           CSR_SIREG3 | CSR_VSIREG3 | CSR_SIREG4 | CSR_VSIREG4 |
           CSR_SIREG5 | CSR_VSIREG5 | CSR_SIREG6 | CSR_VSIREG6 =>
        ireg_xc := sscsrind_reg_xc(stateen_xc, csr_file, csra_in, active, perf_cnts, imsic);
        if ireg_xc.xc then
          return ireg_xc;
        end if;
        return base_xc;
      -- Imsic CSRs
      when CSR_VSTOPEI | CSR_STOPEI        =>
        if not imsic then
          return XC_ILLEGAL;
        end if;
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        if csra_in = CSR_STOPEI then
          -- If the hart has an IMSIC, then when bit 9 of mvien is one, attempts from S-mode to explicitly
          -- access the supervisor-level interrupt file raise an illegal instruction exception. The exception
          -- is raised for attempts to access CSR stopei,
          if csr_file.mvien(IRQ_S_EXTERNAL) = '1' and csr_file.prv = PRIV_LVL_S then
            return XC_ILLEGAL;
          end if;
        else -- csra_in = CSR_VSTOPEI
          if not vgein_legal(u2i(csr_file.hstatus.vgein)) then
            return XC_ILLEGAL;
          end if;
        end if;

        return base_xc;

      when CSR_SIE | CSR_SIP    =>
        if base_xc = XC_NONE and v_mode and csr_file.prv = PRIV_LVL_S and csr_file.hvictl.vti = '1' then
          if csr_file.hvictl.vti = '1' then
            return XC_VIRT;
          end if;
        end if;
        return base_xc;
      -- TODO: What about vsieh/siph?
      when CSR_SIEH | CSR_SIPH  =>
        if not ext_ssaia then
          return XC_ILLEGAL;
        end if;
        if stateen_xc.xc then
          return stateen_xc;
        end if;
        if base_xc = XC_NONE and v_mode and csr_file.prv = PRIV_LVL_S and csr_file.hvictl.vti = '1' then
          if csr_file.hvictl.vti = '1' then
            return XC_VIRT;
          end if;
        end if;
        return base_xc;
      when CSR_SSTATUS | CSR_STVEC  | CSR_SCOUNTEREN | CSR_SSCRATCH |
           CSR_SEPC    | CSR_SCAUSE | CSR_STVAL =>
        return base_xc;
      when CSR_SCOUNTINHIBIT =>
        if not ext_smcdeleg or csr_file.menvcfg.cde = '0' then
          return XC_ILLEGAL;
        end if;
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        if v_mode then
          return XC_VIRT;
        end if;
      when CSR_SCOUNTOVF      =>
        if not ext_sscofpmf then
          return XC_ILLEGAL;
        end if;
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        if v_mode and ext_smcdeleg and csr_file.menvcfg.cde = '1' then
          return XC_VIRT;
        end if;
      when CSR_SSP =>
        -- Zicfiss CSR accessibility (CSR_SSP)
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        return zicfiss_csr_xc(csra_in, csr_file, ext_zicfiss, mode_s);
      -- Supervisor Protection and Translation
      when CSR_SATP           =>
        if base_xc /= XC_NONE then
          return base_xc;
        end if;

        if csr_file.prv = PRIV_LVL_S and v_mode then
          if csr_file.hstatus.vtvm = '1' then
            return XC_VIRT;
          end if;
        end if;
        if csr_file.prv = PRIV_LVL_S and csr_file.mstatus.tvm = '1' then
          return XC_ILLEGAL;
        end if;
      when CSR_STIMECMP | CSR_STIMECMPH | CSR_VSTIMECMP | CSR_VSTIMECMPH  =>
        if not ext_sstc then
          return XC_ILLEGAL;
        end if;
        timecmp_xc := stimecmp_xc(csr_file, h_en, is_rv64, csra_in, v_mode);
        if timecmp_xc.xc then
          return timecmp_xc;
        end if;
        return base_xc;

      -- Machine mode CSRs
      -- Must be listed to not always throw fault.
      when CSR_MVENDORID | CSR_MARCHID    | CSR_MIMPID     | CSR_MIP      |
           CSR_MHARTID   | CSR_MCONFIGPTR | CSR_MSTATUS    | CSR_MISA     |
           CSR_MIE       | CSR_MTVEC      | CSR_MSCRATCH   | CSR_MEPC     |
           CSR_MCAUSE    | CSR_MTVAL      | CSR_MCONTEXT   | CSR_MSTATUSH =>
        return base_xc;
      when CSR_MEDELEG | CSR_MIDELEG =>
        if not mode_s
          then
          return XC_ILLEGAL;
        end if;
      when CSR_MIDELEGH       =>
        if not ext_smaia or(not mode_s
           )
          then
          return XC_ILLEGAL;
        end if;
      when CSR_MIEH | CSR_MIPH =>
        if not ext_smaia then
          return XC_ILLEGAL;
        end if;
      when CSR_MNSCRATCH | CSR_MNEPC | CSR_MNCAUSE | CSR_MNSTATUS =>
        if not ext_smrnmi then
          return XC_ILLEGAL;
        end if;
      when CSR_MISELECT       =>
        if not ext_smcsrind then
          return XC_ILLEGAL;
        end if;
      when CSR_MIREG | CSR_MIREG2 | CSR_MIREG3 | CSR_MIREG4 | CSR_MIREG5 | CSR_MIREG6 =>
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        return smcsrind_reg_xc(csr_file,  csra_in, active, imsic);
      when CSR_MTOPEI         =>
        if not imsic then
          return XC_ILLEGAL;
        end if;
      when CSR_MTOPI          =>
        if not ext_smaia then
          return XC_ILLEGAL;
        end if;
      when CSR_MVIEN  | CSR_MVIP |
           CSR_MVIENH | CSR_MVIPH =>
        -- Minimal implementation
        if not(ext_smaia and mode_s) then
          return XC_ILLEGAL;
        end if;
      when CSR_MSTATEEN0  | CSR_MSTATEEN1  | CSR_MSTATEEN2  | CSR_MSTATEEN3  |
           CSR_MSTATEEN0H | CSR_MSTATEEN1H | CSR_MSTATEEN2H | CSR_MSTATEEN3H =>
        if not ext_smstateen then
          return XC_ILLEGAL;
        end if;
      when CSR_MTINST         =>
        if not h_en then
          return XC_ILLEGAL;
        end if;
      when CSR_MTVAL2         =>
        if not (h_en or ext_ssdbltrp) then
          return XC_ILLEGAL;
        end if;
      when CSR_MENVCFG | CSR_MCOUNTEREN | CSR_MENVCFGH =>
        if not mode_u then
          return XC_ILLEGAL;
        end if;
      when CSR_MSECCFG        =>
        if not (ext_smepmp
           or ext_zicfilp) then
          return XC_ILLEGAL;
        end if;
      when CSR_MSECCFGH       =>
        if not (ext_zicfilp or ext_smepmp) then
          return XC_ILLEGAL;
        end if;
      -- Machine Protection and Translation
      when CSR_PMPCFG0 | CSR_PMPCFG2 | CSR_PMPCFG1 | CSR_PMPCFG3 =>
        if pmp_entries = 0 then
          return XC_ILLEGAL;
        end if;
      when CSR_CYCLEH | CSR_MCYCLEH  =>
      when CSR_TIME   | CSR_TIMEH    =>
        if not time_en then
          return XC_ILLEGAL;
        end if;
      when CSR_INSTRET  | CSR_MINSTRET  |
           CSR_INSTRETH | CSR_MINSTRETH =>
        -- xc := not ext_zicntr;
      when CSR_TSELECT | CSR_TDATA1  | CSR_TDATA2  | CSR_TDATA3  | CSR_TINFO =>
        if trigger = 0 then
          return XC_ILLEGAL;
        end if;
      --when CSR_MSCONTEXT      =>
      -- Custom Registers
      when CSR_FEATURES  | CSR_CCTRL  | CSR_CAPABILITY |
           CSR_FEATURESH | CSR_CCTRLH | CSR_CAPABILITYH
           =>
        -- Just to detect if a CSR address changes
        assert (csra_in(9 downto 8) = PRIV_LVL_M) report "Stateen needs to be checked" severity failure;
        if not x_en then
          return XC_ILLEGAL;
        end if;
      when CSR_TCMICTRL | CSR_TCMDCTRL | CSR_TCMDCTRLH | CSR_TCMICTRLH =>
        return XC_ILLEGAL;
        if stateen_xc /= XC_NONE then
          return stateen_xc;
        end if;
      when others =>
        case csra_high is
          -- Machine|User Hardware Performance Monitoring
          when CSR_CYCLE  | CSR_MCYCLE |
               CSR_CYCLEH | CSR_MCYCLEH =>
            if csra_low = 1 then -- There is no CSR MTIME
              return XC_ILLEGAL;
            end if;
          when CSR_HPMCOUNTER16 | CSR_MHPMCOUNTER16 | -- All the higher counters.
               CSR_HPMCOUNTER16H | CSR_MHPMCOUNTER16H =>
          when CSR_PMPADDR0 =>
            assert (pmp_entries < 16) report "Code can't handle more than 16 entries";
            if pmp_entries = 0 then
              return XC_ILLEGAL;
            end if;
          when CSR_MCOUNTINHIBIT => -- MCOUNTINHIBIT/MHPMEVENT3-15
            if csra_low = 1 or csra_low = 2 or not ext_sscofpmf then
              return XC_ILLEGAL;
            end if;
          when CSR_MHPMEVENT16 =>  -- MHPMEVENT16-31
            if not ext_sscofpmf then
              return XC_ILLEGAL;
            end if;
          when CSR_MHPMEVENT0H =>  -- MHPMEVENT3-15H
            if csra_low < 3 or not ext_sscofpmf then
              return XC_ILLEGAL;
            end if;
          when CSR_MHPMEVENT16H =>  -- MHPMEVENT16-31H
            if not ext_sscofpmf then
              return XC_ILLEGAL;
            end if;
          when others =>
            return XC_ILLEGAL;
        end case;
    end case;

    -- Performance Features
    -- Hardware Performance Features
    -- (CYCLE, TIME, INSTRET, HPMCOUNTERn)
    -- Bit 7 is high for the ...H CSR variants.
    if csra_in(11 downto 8) = x"c" and csra_in(6 downto 5) = "00" then
      if csr_file.mcounteren(counter_idx) = '0' then
        if csr_file.prv /= PRIV_LVL_M then
          return XC_ILLEGAL;
        end if;
      elsif v_mode and csr_file.hcounteren(counter_idx) = '0' then
        if base_xc /= XC_NONE then
          return base_xc;
        end if;
        return XC_VIRT;
      elsif mode_u and csr_file.prv = PRIV_LVL_U and
            csr_file.scounteren(counter_idx) = '0' then
        return xc_type'(xc => true, xc_v => vu_mode);
      end if;
    end if;

    return base_xc;
  end;

  function get_stateen_bits(csra : csratype; csr_file : csr_reg_type) return stateen_bits is
    variable mstateen0 : csr_mstateen0_type     := csr_file.mstateen0;
    variable mstateen1 : csr_mstateen_void_type := csr_file.mstateen1;
    variable mstateen2 : csr_mstateen_void_type := csr_file.mstateen2;
    variable mstateen3 : csr_mstateen_void_type := csr_file.mstateen3;
    variable sstateen0 : csr_sstateen0_type     := csr_file.sstateen0;
    variable hstateen0 : csr_hstateen0_type     := csr_file.hstateen0;
    variable hstateen1 : csr_mstateen_void_type := csr_file.hstateen1;
    variable hstateen2 : csr_mstateen_void_type := csr_file.hstateen2;
    variable hstateen3 : csr_mstateen_void_type := csr_file.hstateen3;

  begin
    -- Set '1' to bits where checks are by default okay, for example hcontext does not need to consider hstateen.ctx
    case csra is
      -- Stateen
      when CSR_HSTATEEN0 | CSR_HSTATEEN0H =>
        return stateen_bits'(mstateen0.stateen, '1', '1');
      when CSR_SSTATEEN0 =>
        return stateen_bits'(mstateen0.stateen, '1', hstateen0.stateen);

      when CSR_HSTATEEN1 | CSR_HSTATEEN1H =>
        return stateen_bits'(mstateen1.stateen, '1', '1');
      when CSR_SSTATEEN1 =>
        return stateen_bits'(mstateen1.stateen, '1', hstateen1.stateen);

      when CSR_HSTATEEN2 | CSR_HSTATEEN2H =>
        return stateen_bits'(mstateen2.stateen, '1', '1');
      when CSR_SSTATEEN2 =>
        return stateen_bits'(mstateen2.stateen, '1', hstateen2.stateen);

      when CSR_HSTATEEN3 | CSR_HSTATEEN3H =>
        return stateen_bits'(mstateen3.stateen, '1', '1');
      when CSR_SSTATEEN3 =>
        return stateen_bits'(mstateen3.stateen, '1', hstateen3.stateen);

      -- Envcfg
      when CSR_HENVCFG   | CSR_HENVCFGH  =>
        return stateen_bits'(mstateen0.envcfg, '1', '1');
      when CSR_SENVCFG =>
        return stateen_bits'(mstateen0.envcfg, '1', hstateen0.envcfg);

      -- Smcsrind
      when CSR_VSISELECT | CSR_SISELECT  |
           CSR_SIREG     | CSR_VSIREG    | CSR_SIREG2 | CSR_VSIREG2 |
           CSR_SIREG3    | CSR_VSIREG3   | CSR_SIREG4 | CSR_VSIREG4 |
           CSR_SIREG5    | CSR_VSIREG5   | CSR_SIREG6 | CSR_VSIREG6 =>
        return stateen_bits'(mstateen0.iselect, '1', hstateen0.iselect);

      -- AIA
      when CSR_HVIEN     | CSR_HVIENH    | CSR_HVICTL   | CSR_HVIPRIO1 | CSR_HVIPRIO1H |
           CSR_HVIPRIO2  | CSR_HVIPRIO2H | CSR_HIDELEGH | CSR_HVIPH    =>
        return stateen_bits'(mstateen0.aia, '1', '1');
      when CSR_VSIEH | CSR_VSIPH | CSR_SIEH | CSR_SIPH | CSR_VSTOPI | CSR_STOPI =>
        return stateen_bits'(mstateen0.aia, '1', hstateen0.aia);

      -- Imsic
      when CSR_VSTOPEI   | CSR_STOPEI =>
        return stateen_bits'(mstateen0.imsic, '1', hstateen0.imsic);

      -- Context
      when CSR_HCONTEXT  =>
        return stateen_bits'(mstateen0.ctx, '1', '1');
      when CSR_SCONTEXT =>
        return stateen_bits'(mstateen0.ctx, '1', hstateen0.ctx);

      -- Priv 1.13
      when CSR_HEDELEGH =>
        return stateen_bits'(mstateen0.p1p13, '1', '1');
      -- when CSR_SRMCFG =>
      --   return stateen_bits'(mstateen0.p1p14, '1', '1');
      when others =>
        return stateen_bits'('1','1','1');
    end case;
  end function;

  function get_stateen_bits(csrindsel : select_t ; csr_file : csr_reg_type) return stateen_bits is
    variable mstateen0 : csr_mstateen0_type := csr_file.mstateen0;
    variable hstateen0 : csr_hstateen0_type := csr_file.hstateen0;
  begin
    if is_aia_iprio(csrindsel) then
      return stateen_bits'(mstateen0.aia, '1', hstateen0.aia);
    elsif is_imsic(csrindsel) then
      return stateen_bits'(mstateen0.imsic, '1', hstateen0.imsic);
    else
      return stateen_bits'('1', '1', '1');
    end if;

  end function;

  function is_vsireg(csra : csratype) return boolean is
  begin
    return csra >= CSR_VSIREG and csra <= CSR_VSIREG6 and csra /= CSR_VSIPH;
  end function;

  function is_sireg(csra : csratype) return boolean is
  begin
    return csra >= CSR_SIREG and csra <= CSR_SIREG6 and csra /= CSR_SIPH;
  end function;

  function check_stateen_xc(bits          : stateen_bits;
                            priv          : priv_lvl_type;
                            v_mode        : boolean;
                            ext_smstateen : boolean;
                            mode_s        : boolean) return xc_type is
    -- Non-constant
  begin
    -- M mode not affected by stateen
    if priv = PRIV_LVL_M or not ext_smstateen then
      return XC_NONE;
    end if;

    -- Less than M mode and mstateen not set -> illegal
    if bits.m = '0' then
      return XC_ILLEGAL;
    end if;

    if v_mode then
      -- VS/VU with mstateen set but without hstateen bit set, virtual exception.
      if bits.h = '0' then
        return XC_VIRT;
      end if;

      -- VU with mstateen and hstateen set but without sstateen bit set, potentially a virtual exception.
      if (priv = PRIV_LVL_U and bits.s = '0') then
        return XC_VIRT;
      end if;
    end if;

    -- U with mstateen set but without sstateen bit set, illegal
    if priv = PRIV_LVL_U and mode_s then
      if bits.s = '0' then
        return XC_ILLEGAL;
      end if;
    end if;

    -- Stateen permits
    return XC_NONE;

  end function;

  -- When accessing a CSR through (v)sireg* further stateen checks may have to be done (eg, imsic, aia).
  -- Always returns (zero, zero) if stateen is not enabled.
  function csrind_check_stateen_xc(csra          : csratype;
                                   csr_file      : csr_reg_type;
                                   ext_smstateen : boolean;
                                   mode_s        : boolean) return xc_type is
  begin
    if csra = CSR_VSIREG then
      return check_stateen_xc(
        get_stateen_bits(csr_file.vsiselect, csr_file), csr_file.prv, csr_file.v = '1', ext_smstateen, mode_s
      );
    elsif csra = CSR_SIREG then
      return check_stateen_xc(
        get_stateen_bits(csr_file.siselect, csr_file), csr_file.prv, csr_file.v = '1', ext_smstateen, mode_s
      );
    else
      -- assert false report "Called with wrong arguments" severity failure;
      return XC_NONE;
    end if;
  end function;

  -- CSR Write
  procedure csr_write_flush(csra_in       : in  csratype;
                            active        : in  extension_type;
                            pipeflush_out : out std_ulogic;
                            addrflush_out : out std_ulogic
                            ) is
    variable is_rv32     : boolean := not is_enabled(active, x_rv64);
    variable ext_smepmp  : boolean := is_enabled(active, x_smepmp);
    variable mode_u      : boolean := is_enabled(active, x_mode_u);
    variable ext_noelv   : boolean := is_enabled(active, x_noelv);
    variable ext_zicfilp : boolean := is_enabled(active, x_zicfilp);
    -- Non-constant
    variable pipeflush : std_ulogic := '0';
    variable addrflush : std_ulogic := '0';
  begin
    case csra_in is
      when CSR_HGATP =>
        pipeflush := '1';
        addrflush := '1';

      when CSR_HENVCFG =>
        pipeflush := '1';
        addrflush := '1';

      when CSR_HENVCFGH =>
        if is_rv32 then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_VSATP =>
        pipeflush := '1';
        addrflush := '1';

      when CSR_SENVCFG =>
        if mode_u then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_SATP =>
        pipeflush := '1';
        addrflush := '1';

      when CSR_MENVCFG =>
        pipeflush := '1';
        addrflush := '1';

      when CSR_MENVCFGH =>
        if is_rv32 then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_MSECCFG =>
        if ext_smepmp
           or ext_zicfilp
           then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_MSECCFGH =>
        if is_rv32 and (
           ext_zicfilp or ext_smepmp) then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_FEATURES =>
        if ext_noelv then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_FEATURESH =>
        if is_rv32 and ext_noelv then
        end if;

      when CSR_CCTRL =>
        if ext_noelv then
          pipeflush := '1';
          addrflush := '1';
        end if;

      when CSR_TCMICTRL =>
        if ext_noelv then
        end if;

      when CSR_TCMDCTRL =>
        if ext_noelv then
        end if;


      when others =>
    end case;

    pipeflush_out := pipeflush;
    addrflush_out := addrflush;
  end;


  -- Dual issue check logic
  -- Check if instructions can be issued in the same clock cycle on both lanes.
  procedure dual_issue_check(active      : in  extension_type;
                             cfi_en      : in  cfi_t;
                             lane        : in  lane_select;
                             instx_in    : in  iword_tuple_type;
                             valid_in    : in  std_logic_vector;
                             lbranch_dis : in  std_ulogic;
                             lalu_dis    : in  std_ulogic;
                             dual_dis    : in  std_ulogic;
                             hpmc_mode   : in  std_ulogic;
                             step_in     : in  std_ulogic;
                             lalu_in     : in  std_logic_vector;
                             xc          : in  std_logic_vector;
                             mexc        : in  std_ulogic;
                             rd0_in      : in  reg_t;
                             rdv0_in     : in  std_ulogic;
                             rd1_in      : in  reg_t;
                             rdv1_in     : in  std_ulogic;
                             lane0_out   : out std_ulogic;
                             issue_out   : out std_logic_vector) is
    variable ext_zbc          : boolean  := is_enabled(active, x_zbc);
    variable ext_zbkc         : boolean  := is_enabled(active, x_zbkc);
    variable ext_f            : boolean  := is_enabled(active, x_f);
    variable ext_h            : boolean  := is_enabled(active, x_h);
    variable single_issue     : boolean  := is_enabled(active, x_single_issue);
    variable late_alu         : boolean  := is_enabled(active, x_late_alu);
    variable late_branch      : boolean  := is_enabled(active, x_late_branch);
    variable one              : integer  := 1 - u2i(single_issue);
    constant lanes            : std_logic_vector(0 to valid_in'length - 1) := (others => '0');
    subtype  lanes_type      is std_logic_vector(valid_in'range);
    subtype  word_lanes_type is word_arr(lanes'range);
    type     rfa_lanes_type  is array (lanes'range) of reg_t;
    type     op_lanes_t      is array (lanes'range) of opcode_type;
    type     f3_lanes_t      is array (lanes'range) of funct3_type;
    type     f7_lanes_t      is array (lanes'range) of funct7_type;
    -- Non-constant
    variable inst_in   : word_lanes_type;
    variable conflict  : std_ulogic := '0';
    variable rfa1      : rfa_lanes_type;
    variable rfa2      : rfa_lanes_type;
    variable rd        : rfa_lanes_type;
    variable rs1_valid : lanes_type;
    variable rs2_valid : lanes_type;
    variable rd_valid  : lanes_type;
    variable opcode    : op_lanes_t;
    variable funct3    : f3_lanes_t;
    variable funct7    : f7_lanes_t;
    variable lane0     : std_ulogic := '0';
    variable opcode_0  : opcode_type;  -- These are needed to have
    variable opcode_1  : opcode_type;  --  locally static object
    variable funct7_1  : funct7_type;  --  subtypes for case statements.
    variable hold_cat_0: hold_category_t;
    variable hold_cat_1: hold_category_t;
  begin
-- pragma translate_off
    assert valid_in'left  >= valid_in'right and
           valid_in'left   = lalu_in'left   and
           valid_in'left   = issue_out'left and
           valid_in'length = lalu_in'length
      report "Bad type" severity failure;
-- pragma translate_on
    for i in lanes'range loop
      inst_in(i)  := instx_in(i).d;
      opcode(i)   := get_opcode(inst_in(i));
      funct3(i)   := get_funct3(inst_in(i));
      funct7(i)   := get_funct7(inst_in(i));
      rfa1(i)     := rs1_gen(active, cfi_en, inst_in(i));
      rfa2(i)     := rs2_gen(active, cfi_en, inst_in(i));
      rd_valid(i) := rd_gen(active,  cfi_en, inst_in(i));
      rd(i)       := get_rd(inst_in(i));
    end loop;

    -- Create locally static objects
    opcode_0   := opcode(0);
    opcode_1   := opcode(one);
    funct7_1   := funct7(one);

    hold_cat_0 := csr_hold_category(csr_access_addr(inst_in(0)), hpmc_mode);
    hold_cat_1 := csr_hold_category(csr_access_addr(inst_in(one)), hpmc_mode);


    -- If both instructions are valid, inst(0) is always the older instruction,
    -- hence only that one should be issued if a dependency exists between the
    -- pair.
    case opcode_0 is
      when OP_LOAD    | OP_STORE | OP_AMO |
           OP_LOAD_FP | OP_STORE_FP =>
        if for_lane0(active, cfi_en, lane, inst_in(one)) then
          conflict := '1';
        end if;

      when OP_CUSTOM0 =>
        -- Diagnostic load/store?
        if is_diag(active, inst_in(0)) then
          if for_lane0(active, cfi_en, lane, inst_in(one)) then
            conflict := '1';
          end if;
        end if;

      when OP_JAL | OP_JALR =>
        -- Raise conflict since we will have a control flow change, so the instruction
        -- after the jal/jalr would not be valid anyway.
        conflict := '1';

      when OP_BRANCH =>
        if late_branch then
          if not (opcode_1 = OP_REG    or opcode_1 = OP_32  or
                  opcode_1 = OP_IMM_32 or opcode_1 = OP_IMM or
                  opcode_1 = LUI       or opcode_1 = AUIPC) then
                  -- LPAD (AUIPC with rd=x0) instruction must not pair with late branch!
                  -- But it is disallowed from second position completely below.
            conflict := '1';
          end if;
        end if;

        if not late_branch then
          case opcode_1 is
            when OP_BRANCH =>
              -- Raise conflict since only one branch unit is available.
              conflict := '1';
            when OP_JAL | OP_JALR =>
              -- Raise conflict since they use the same lane.
              conflict := '1';

            when OP_FP | OP_FMADD | OP_FMSUB | OP_FNMADD | OP_FNMSUB | OP_STORE_FP | OP_LOAD_FP =>
              -- In order for combinatorial branch resolution in execute stage
              -- to not affect FPU, prevent dual issue of FPU with branches.
              conflict := '1';

            when others =>

          end case; -- opcode_1
        end if;

        if mexc = '1' or xc(one) = '1' then
          -- Don't allow dual issue when instruction after branch is exception.
          conflict := '1';
        end if;

      when OP_SYSTEM =>
        case funct3(0) is
        when "000" =>
          -- Some of these need conflict raised since we will have a control
          -- flow change at the exception stage, so the next instruction
          -- will not be valid.
          --   ecall/ebreak
          --   mret/sret/uret
          -- Some of these take a significant amount of time, so raising
          -- conflict does not really matter. At least sfence.vma also
          -- actually may change the behaviour of the next instruction.
          --   sfence.vma/hfence.vvma/hfence.gvma
          --   sinval.vma/sfence.w.inval/sfence.inval.ir/hinval.vvma/hinval.gvma
          -- It does not matter if conflict is raised for this.
          --   wfi
          -- Further extensions with funct3=000 may require a rethink of this.
          conflict := '1';
        when "100"  =>  -- Hypervisor load/store must be in lane 0, and several Zicfiss.
          -- There may at some later point be other instructions with funct3=100.
          -- Then further checks will be needed here!
          if (ext_h and is_hlsv(inst_in(0))) or
             maybe_csr(active, cfi_en, inst_in(0)) then
            -- Raise conflict when the other instruction wants lane 0 as well.
            if for_lane0(active, cfi_en, lane, inst_in(one)) then
              conflict := '1';
            end if;
          end if;
        when others =>  -- CSR
          -- For some CSR writes, raise conflict since the execution of the
          -- next instruction may depend on it.
          if not csr_access_read_only(inst_in(0)) and hold_cat_0(0) = '1' then
            conflict := '1';
          end if;
          -- Do not allow CSR writes to FPU flags or rounding mode to
          -- pair with an FPU instruction.
          if lane.csr /= lane.fpu and is_fpu(inst_in(one)) and
             is_csr_access(inst_in(0)) and hold_cat_0(3) = '1' then
            conflict := '1';
          end if;
          -- CSR accesses use the same pipeline as some other things.
          -- (These checks include other CSR accesses.)
          if for_lane0(active, cfi_en, lane, inst_in(one)) then
            -- Raise conflict since they use the same lane.
            conflict := '1';
          end if;
          if is_system0(inst_in(one)) then
            -- uret/sret/mret depend on UEPC/SEPC/MEPC, so they may not pair
            -- with a write to those in lane 0.
            if rs2(inst_in(one)) = "00010" then
              case funct7_1 is
                when F7_MNRET =>
                  if csr_access_addr(inst_in(0)) = CSR_MNEPC then
                    conflict := '1';
                  end if;
                when F7_MRET =>
                  if csr_access_addr(inst_in(0)) = CSR_MEPC then
                    conflict := '1';
                  end if;
                when F7_SRET =>
                  if csr_access_addr(inst_in(0)) = CSR_SEPC then
                    conflict := '1';
                  end if;
                when others =>
              end case;
            end if;
          end if;
        end case;

      when OP_FENCE =>
        -- Raise conflict
        conflict := '1';

      when OP_REG | OP_32 =>
        if funct7(0) = F7_MUL then
          case opcode_1 is
            when OP_REG | OP_32 =>
              if funct7(one) = F7_MUL then
                -- Mul/Div Operation
                -- Raise conflict since we have only one Mul/Div Unit
                conflict := '1';
              end if;

            when others =>
          end case; -- opcode_1
        end if;

      when OP_FP     |
           OP_FMADD  | OP_FMSUB  |
           OP_FNMADD | OP_FNMSUB =>
        -- Do not allow CSR accesses to FPU flags to
        -- pair with an FPU instruction.
        if lane.csr /= lane.fpu and
           is_csr_access(inst_in(one)) and hold_cat_1(3) = '1' then
          conflict := '1';
        end if;
        -- FPU operations use the same pipeline as some other things.
        -- (These checks include other FPU operations.)
        if lane.fpu = 0 and for_lane0(active, cfi_en, lane, inst_in(one)) then
          -- Raise conflict since they use the same lane.
          conflict := '1';
        end if;
        if lane.fpu = 1 and for_lane1(active, cfi_en, lane, inst_in(one)) then
          -- Raise conflict since they use the same lane.
          conflict := '1';
        end if;

      when OP_IMM =>
      when others =>
    end case; -- opcode(0)

    -- Multi-cycle operations in execute stage do not currently work.
    -- Fortunately, for now that is only divide/remainder and FPU->IU.
    -- This also prevents the problem of division issued together with a branch
    -- because we don't want branch to combinatorially affect ex_hold_pc signal
    -- in execute stage.
    for i in lanes'range loop
      if (opcode(i) = OP_REG or  opcode(i) = OP_32) and
         funct7(i) = F7_MUL and funct3(i)(2) = '1' then   -- DIV[U][W]/REM[U][W]
        conflict := '1';
      end if;
    end loop;
    if ext_f then
      for i in lanes'range loop
        -- For now, never pair FPU with anything.
        if is_fpu(inst_in(i)) or is_fpu_mem(inst_in(i)) then
          conflict := '1';
        end if;
      end loop;
    end if;


    if ext_zbc or ext_zbkc then
      -- There is only one special ALU (currently limited to CLMUL) machinery.
      -- To avoid complications, always issue on its own.
      -- R_CLMULR is not actually valid for ext_zbkc, but that does not matter here.
      for i in lanes'range loop
        if v_fusel_eq(fusel_gen(active, inst_in(i)), ALU_SPECIAL) then
          conflict := '1';
        end if;
      end loop;
    end if;

    -- Never allow LPAD in the second lane!
    if is_lpad(active, cfi_en, inst_in(one)) then
      conflict := '1';
    end if;

    -- This is the same as for pipe 0 above.
    -- Writes to some CSRs require the pipeline to be flushed. To simplify PC logic,
    -- ensure that such CSR writes always issue alone.
    -- There are also other reasons for enforcing single-issue of CSR writes.
    if is_csr_access(inst_in(one)) and not csr_access_read_only(inst_in(one)) and
       hold_cat_1(0) = '1' then
      conflict := '1';
    end if;
    -- If we are issuing a CSR read that reads a performance counter this cannot be
    -- issued together with a instruction that comes first in program order.
    if is_csr_access(inst_in(one)) and not csr_access_write_only(inst_in(one)) and
       (hold_cat_1(6) or hold_cat_1(7)) = '1'  then
      conflict := '1';
    end if;


    -- We want to annull next instructions and it is
    -- easier if wfi is issued alone.
    -- for lane 0 the conflict is already set to 1
    if is_wfi(inst_in(one)) then
      conflict := '1';
    end if;



    -- Instruction register dependency:

    -- case # 1
    -- | INSTA x1, 0(x2)  |
    -- | INSTB x4, x1, x3 |
    -- If rd of the first instruction is valid and the other instruction
    -- uses it as a source operand, raise conflict. Do not raise conflict in
    -- scenarios covered by forwarding or late alu.

    -- case # 2
    -- | INSTA x1, 0(x2)  |
    -- | INSTB x1, x4, x3 |
    -- If rd of the first istruction is valid and the other instruction
    -- uses it as a valid destination register, raise conflict. Do not raise
    -- conflict if the second instruction is a STORE/LOAD, since we will forward
    -- the operand to the memory. It could be resolved after the exception stage
    -- as soon as we have the validity of both instruction and we could decide
    -- which value to write.

    if rd_valid(0) = '1' then
      -- case # 1
      if rd(0) = rfa1(one) or rd(0) = rfa2(one) then
        case opcode_1 is
          when OP_LOAD   | OP_LOAD_FP |  -- Load (address)
            -- It must be ensured that the CFI SSPOPCHK instruction is not
            -- dependent on a swapped instruction. Critical timing in EXC!
               OP_SYSTEM |               -- System or CSR
               OP_FENCE  |               -- Fence
               OP_FP     |               -- Floating point operation with integer input
               OP_JALR =>                -- Jump and link register (this is resolved early)
            conflict   := '1';

          -- Store in second lane (only in case of Address Generation)
          when OP_STORE | OP_STORE_FP | OP_AMO =>
            if rd(0) = rfa1(one) then
              conflict := '1';
            end if;

            -- Right now it is assumed that multiplier is always 2 stage
            if (opcode(0) = OP_REG or opcode(0) = OP_32) and funct7(0) = F7_MUL then
              if rd(0) = rfa2(one) then
                conflict := '1';
              end if;
            end if;

          when OP_CUSTOM0 =>
            if is_diag(active, inst_in(one)) then
              -- Needs swap to lane 0
              conflict   := '1';
            elsif is_custom_alu(active, inst_in(one)) then
              -- Custom ALU operation in second lane (if late ALU feature is disabled)
              -- (This is the same as for normal ALU operations below.)
              if lalu_dis = '1' or not late_alu then
                conflict := '1';
              end if;
               -- Instruction in RA has been issued to late ALUs
              if ((rd0_in = rfa1(0) or rd0_in = rfa2(0)) and lalu_in(0) = '1' and rdv0_in = '1') or
                 ((rd1_in = rfa1(0) or rd1_in = rfa2(0)) and lalu_in(one) = '1' and rdv1_in = '1') then
                conflict := '1';
              end if;
            end if;

          -- Branch in second lane (if late branch feature is disabled)
          when OP_BRANCH =>
            if lbranch_dis = '1' or not late_branch then
              conflict := '1';
            end if;

          -- ALU operation in second lane (if late ALU feature is disabled)
          when OP_REG | OP_32 | OP_IMM_32 | OP_IMM | LUI | AUIPC =>
            if lalu_dis = '1' or not late_alu then
              conflict := '1';
            end if;
             -- Instruction in RA has been issued to late ALUs
            if ((rd0_in = rfa1(0) or rd0_in = rfa2(0)) and lalu_in(0) = '1' and rdv0_in = '1') or
               ((rd1_in = rfa1(0) or rd1_in = rfa2(0)) and lalu_in(one) = '1' and rdv1_in = '1') then
              conflict := '1';
            end if;
            -- MUL/DIV in any case
            if (opcode(one) = OP_REG or opcode(one) = OP_32) and funct7(one) = F7_MUL then
              conflict := '1';
            end if;

          when others =>
            -- FMADD, FMSUB, FNMSUB, FNMADD - No integer source
            -- JAL - No source
            -- The rest are not available:
            -- custom-0
            -- 48b
            -- custom-1
            -- 64b
            -- reserved-10101_11
            -- custom-2
            -- 48b
            -- reserved-11010_11
            -- reserved-11101_11
            -- custom-3
            -- >= 80b
            null;
        end case;

        -- Values from CSRs will not be available until in the exception stage,
        -- at the same time as the late ALU, so it is not possible for another
        -- instruction in the same pair to access it.
        if is_csr_access(inst_in(0)) or
           is_ssrdp(active, cfi_en, inst_in(0)) then
          conflict := '1';
        end if;
      end if;

      -- case # 2
      if rd_valid(one) = '1' and rd(0) = rd(one) then
        -- Generate conflict flag in case of
        -- LOAD and other ALU instruction.
        -- JAL/JALR instruction would be placed in lane1,
        -- thus no conflict arises.
        if v_fusel_eq(fusel_gen(active, inst_in(0)), LD) or
           v_fusel_eq(fusel_gen(active, inst_in(one)), LD) then
          conflict := '1';
        end if;
        -- Generate conflict in case one of the
        -- instructions is a CSR read.
        if is_csr_access(inst_in(0))            or
           is_csr_access(inst_in(one))          or
           is_ssrdp(active, cfi_en, inst_in(0)) or
           is_ssrdp(active, cfi_en, inst_in(one))
           then
          conflict := '1';
        end if;
      end if;
    end if;

    lane0_out := lane0;

    -- If only one instructions is valid, we could issue it without any check.
    issue_out  := valid_in;

    -- If dual issue capability is disabled, raise conflict.
    if dual_dis = '1' then
      conflict := '1';
    end if;

    -- If instruction step, raise conflict.
    if step_in = '1' then
      conflict := '1';
    end if;

    if conflict = '1' and all_1(valid_in) then
      issue_out(one) := '0';
    end if;
  end;

  -- Dual issue swap logic, generate swap flag
  procedure dual_issue_swap(active   : in  extension_type;
                            cfi_en   : in  cfi_t;
                            lane     : in  lane_select;
                            inst_in  : in  iword_tuple_type;
                            valid_in : in  std_logic_vector;
                            swap_out : out std_ulogic) is
    -- Non-constant
    variable swap : std_logic := '0';
  begin
    if for_lane1(active, cfi_en, lane, inst_in(0).d) and valid_in(0) = '1' then
      swap := '1';
    end if;

    if for_lane0(active, cfi_en, lane, inst_in(1).d) and
       (valid_in(0) = '0' or not for_lane0(active, cfi_en, lane, inst_in(0).d)) then
      swap := '1';
    end if;

    swap_out := swap;
  end;

  -- Pad or extend pc to XLEN
  function pc2xlen(pc_in : std_logic_vector) return wordx is
    variable pc : std_logic_vector(pc_in'length - 1 downto 0) := pc_in;
    -- Non-constant
    variable data : wordx;
  begin
    data           := (others => get_hi(pc));
    data(pc'range) := pc;

    return data;
  end;

  -- Generate instruction address misaligned flag
  function inst_addr_misaligned(active : extension_type;
                                pc     : std_logic_vector) return boolean is
    variable ext_c    : boolean := is_enabled(active, x_c);
    -- Non-constant
    variable naligned : boolean := false;
  begin
    -- Unaligned instruction if compressed instructions are supported!
    if not ext_c then
      if pc(1 downto 0) /= "00" then
        naligned := true;
      end if;
    end if;

    return naligned;
  end;

  -- Return whether the two functional units are equivalent.
  -- Or rather that they have at least one bit in common.
  function v_fusel_eq(fusel1 : fuseltype; fusel2 : fuseltype) return boolean is
  begin
    return (fusel1 and fusel2) /= NONE;
  end;


  -- Branch Unit
  procedure branch_unit(active    : in  extension_type;
                        op1_in    : in  wordx;
                        op2_in    : in  wordx;
                        valid_in  : in  std_ulogic;
                        branch_in : in  std_ulogic;
                        ctrl_in   : in  word3;
                        addr_in   : in  std_logic_vector;  -- pctype
                        npc_in    : in  std_logic_vector;  -- pctype
                        taken_in  : in  std_ulogic;
                        pc_in     : in  std_logic_vector;
                        valid_out : out std_ulogic;
                        mis_out   : out std_ulogic;
                        addr_out  : out std_logic_vector;  -- pctype
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        tval_out  : out wordx) is
    subtype pctype is std_logic_vector(addr_in'range);
    -- Non-constant
    variable taken  : std_ulogic := '0';
    variable xc     : std_ulogic := '0';
    variable val    : std_ulogic := '0';
    variable tval   : wordx      := pc2xlen(addr_in);
    variable op1    : wordx1;
    variable op2    : wordx1;
    variable equal  : std_ulogic;
    variable less   : std_ulogic;
    variable target : pctype     := addr_in;
  begin
    -- Signed and unsigned comparison
    op1         := (not ctrl_in(1) and get_hi(op1_in)) & op1_in;
    op2         := (not ctrl_in(1) and get_hi(op2_in)) & op2_in;
    if signed(op1) < signed(op2) then
      less      := '1';
    else
      less      := '0';
    end if;

    if op1 = op2 then
      equal     := '1';
    else
      equal     := '0';
    end if;

    case ctrl_in is
      when B_BEQ          => taken :=     equal;
      when B_BNE          => taken := not equal;
      when B_BLT | B_BLTU => taken :=     less;
      when B_BGE | B_BGEU => taken := not less;
      when others =>
    end case;

    -- Raise valid signal
    if valid_in = '1' and branch_in = '1' then
      val       := '1';
    end if;

    -- Generate Output Branch Signal
    --                        taken
    --                  0       |       1
    --          0     0(xx)         1(addr_in)
    -- dir
    --          1    1(pc+4)          0(xx)

    -- Generate Target Address
    if  val = '1' and taken = '0' and taken_in = '1' then
      target    := npc_in;
    end if;

    -- Raise exception if branch taken and address is misaligned.
    if taken = '1' and val = '1' and inst_addr_misaligned(active, target) then
      xc        := '1';
    end if;

    valid_out   := val;
    mis_out     := taken xor taken_in;
    addr_out    := target;
    xc_out      := xc;
    cause_out   := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    tval_out    := tval;
  end;

    -- Instruction Buffer Control Logic
  procedure buffer_ic(active         : in  extension_type;
                      r_d_buff_valid : in  std_ulogic;
                      valid_in       : in  std_logic_vector;
                      dvalid_in      : in  std_logic_vector;
                      buffer_third   : in  std_ulogic;
                      buffer_sec     : in  std_ulogic;
                      buffer_first   : in  std_ulogic;
                      unaligned      : in  std_ulogic;
                      issue_in       : in  std_logic_vector;
                      hold_pc        : out std_ulogic;
                      buff_valid     : out std_ulogic) is
    variable single_issue : boolean := is_enabled(active, x_single_issue);
  begin
    buff_valid := '0';
    hold_pc    := '0';

    if buffer_third = '1' then
      -- A third instruction or unaligned instruction
      -- in order to buffer all other instructions must be consumed
      if ((valid_in(0) = '1' and issue_in(0) = '1') or (valid_in(0) = '0')) and
         ((valid_in(1) = '1' and issue_in(1) = '1') or (valid_in(1) = '0')) then
        buff_valid := '1';
      end if;

      if valid_in(1) = '1' and issue_in(1) = '0' then
        hold_pc    := '1';
      end if;

      if r_d_buff_valid = '1' and not single_issue  then
        -- If buffer is valid also that means there will be at
        -- least two instructions left to issue, so don't buffer.
        buff_valid       := '0';
        hold_pc          := '1';
        if unaligned = '1' then
          -- If unaligned is asserted there might be less than three instructions.
          if dvalid_in(0) = '0' then
            buff_valid   := '1';
            hold_pc      := '0';
          elsif dvalid_in(0) = '1' and dvalid_in(1) = '0' then
            if issue_in(1) = '1' then
              buff_valid := '1';
              hold_pc    := '0';
            end if;
          end if;
          -- In all other cases buffer needs to be hold so first statement applies.
        end if;
      end if;

    end if;

    if buffer_sec = '1' and issue_in(1) = '0' then
      -- Buffer second instructions, when buffer_sec is asserted second instruction
      -- is always valid.
      buff_valid := '1';
    end if;

    if r_d_buff_valid = '1' and buffer_sec = '1' then
      if issue_in(1) = '0' then
        -- If buffer is also valid that means two instructions will left on
        -- regular queue don't buffer.
        buff_valid := '0';
        hold_pc    := '1';
      else
        buff_valid := '1';
      end if;
    end if;

    if r_d_buff_valid = '1' and buffer_first = '1' then
      if issue_in(1) = '0' then
        buff_valid := '1';
      end if;
    end if;


    if r_d_buff_valid = '1' and buffer_third = '0' and single_issue then
      hold_pc := '1';
    end if;

  end;

  -- Hardwire status CSR bits
  function tie_status(active : extension_type;
                      status : csr_status_type;
                      misa   : wordx      := (others => '1')) return csr_status_type is
    variable h_en         : boolean    := is_enabled(active, x_h) and misa(h_ctrl) = '1';
    variable ext_n        : boolean    := is_enabled(active, x_n);
    variable ext_f        : boolean    := is_enabled(active, x_f);
    variable mode_u       : boolean    := is_enabled(active, x_mode_u);
    variable mode_s       : boolean    := is_enabled(active, x_mode_s);
    variable ext_smdbltrp : boolean    := is_enabled(active, x_smdbltrp);
    variable ext_ssdbltrp : boolean    := is_enabled(active, x_ssdbltrp);
    variable ext_zicfilp  : boolean    := is_enabled(active, x_zicfilp);
    -- Non-constant
    variable mstatus : csr_status_type := status;
  begin
    -- Big-endian not supported
    mstatus.sbe := '0';
    mstatus.ube := '0';

    if not mode_s then
      mstatus.sxl  := "00";
      mstatus.spp  := '0';
      mstatus.mxr  := '0';
      mstatus.sum  := '0';
      mstatus.tvm  := '0';
      mstatus.tsr  := '0';
      mstatus.sie  := '0';
      mstatus.spie := '0';
    end if;

    if not mode_u then
      mstatus.uxl  := "00";
      mstatus.mprv := '0';
      mstatus.tw   := '0';
    end if;

    if not mode_u or not ext_n then
      mstatus.uie  := '0';
      mstatus.upie := '0';
    end if;

    if not h_en then
      mstatus.mpv := '0';
      mstatus.gva := '0';
    end if;

    if not ext_f then
      mstatus.fs := "00";
    end if;

    -- Unsupported privilege mode - default to user-mode.
    if status.mpp = "10" or (not mode_s and status.mpp = "01") or (not mode_u and status.mpp = "00") then
      if mode_u then
        mstatus.mpp := "00";
      else
        mstatus.mpp := "11";
      end if;
    end if;

    if not ext_smdbltrp then
      mstatus.mdt := '0';
    end if;

    if not ext_ssdbltrp then
      mstatus.sdt := '0';
    end if;

    if not ext_zicfilp then
      mstatus.mpelp := '0';
      mstatus.spelp := '0';
    end if;

    return mstatus;
  end;

  -- Hardwire CSR bits
  procedure tie_csrs(active      : extension_type;
                     pmp_entries : integer range 0 to PMPENTRIES - 1;
                     pma_entries : integer range 0 to PMAENTRIES - 1;
                     pma_masked  : integer range 0 to 1;
                     perf_cnts   : integer range 0 to 29;
                     perf_bits   : integer range 0 to 64;
                     mmuen       : integer range 0 to 1;
                     csr         : inout csr_reg_type) is
    variable ext_noelv    : boolean := is_enabled(active, x_noelv);
    variable ext_noelvalu : boolean := is_enabled(active, x_noelvalu);
    variable ext_h        : boolean := is_enabled(active, x_h);
    variable mode_s       : boolean := is_enabled(active, x_mode_s);
    variable mode_u       : boolean := is_enabled(active, x_mode_u);
    variable ext_f        : boolean := is_enabled(active, x_f);
    variable ext_zicfilp  : boolean := is_enabled(active, x_zicfilp);
    variable ext_sscofpmf : boolean := is_enabled(active, x_sscofpmf);
    variable ext_sstc     : boolean := is_enabled(active, x_sstc);
    variable ext_smepmp   : boolean := is_enabled(active, x_smepmp);
    variable ext_smrnmi   : boolean := is_enabled(active, x_smrnmi);
  begin
    csr.mstatus := tie_status(active, csr.mstatus);

    -- Reserved interrupts
    csr.mip     := csr.mip     and not CSR_IRQ_RSV_MASK;
    csr.mie     := csr.mie     and not CSR_IRQ_RSV_MASK;
    csr.mideleg := csr.mideleg and not CSR_IRQ_RSV_MASK;

    -- H-extension not implemented?
    if not ext_h then
      csr.v           := '0';
      csr.dcsr.v      := '0';
      csr.hstatus     := csr_hstatus_rst;
      csr.hideleg     := (others => '0');
      csr.hedeleg     := (others => '0');
      csr.hgatp       := atp_none;
      csr.hvip        := (others => '0');
      csr.vsie        := (others => '0');
      csr.hip         := (others => '0');
      csr.hie         := (others => '0');
      csr.hgeip       := (others => '0');
      csr.hgeie       := (others => '0');
      csr.hcounteren  := (others => '0');
      csr.htimedelta  := (others => '0');
      csr.htval       := (others => '0');
      csr.htinst      := (others => '0');
      csr.vsstatus    := csr_status_rst;
      csr.vsepc       := (others => '0');
      csr.vsatp       := atp_none;
      csr.vsscratch   := (others => '0');
      csr.vscause     := cause_res;
      csr.vstval      := (others => '0');
      csr.vstimecmp   := (others => '0');
      csr.mtval2      := (others => '0');
      csr.mtinst      := (others => '0');
      csr.mip         := csr.mip     and not CSR_HIE_MASK;
      csr.mie         := csr.mie     and not CSR_HIE_MASK;
      csr.mideleg     := csr.mideleg and not CSR_HIE_MASK;
    end if;

    -- S-mode not implemented?
    if not mode_s then
      csr.satp        := atp_none;
      csr.stvec       := (others => '0');
      csr.sepc        := (others => '0');
      csr.stval       := (others => '0');
      csr.stimecmp    := (others => '0');
      csr.scause      := cause_res;
      csr.sscratch    := (others => '0');
      csr.mip         := csr.mip     and not CSR_SIE_MASK;
      csr.mie         := csr.mie     and not CSR_SIE_MASK;
      csr.mideleg     := csr.mideleg and not CSR_SIE_MASK;
    end if;

    -- U-mode not implemented?
    if not mode_u then
      csr.scounteren  := (others => '0');
    end if;

    -- S-mode or N-extension not implemented?
    if not mode_s
      then
      csr.mideleg     := (others => '0');
      csr.medeleg     := (others => '0');
    end if;

    -- No Sscofpmf?
    if not ext_sscofpmf then
      csr.mip(IRQ_LCOF)     := '0';
      csr.mie(IRQ_LCOF)     := '0';
      csr.mideleg(IRQ_LCOF) := '0';
    end if;

    -- No floating point?
    if not ext_f then
      csr.vsstatus.fs := "00";
    end if;

    -- No Sstc extension?
    if not ext_sstc then
      csr.stimecmp  := (others => '0');
      csr.vstimecmp := (others => '0');
    end if;

    -- No Zicfilp extension?
    if not ext_zicfilp then
      csr.elp             := '0';
      csr.vsstatus.spelp  := '0';
      csr.mnstatus.mnpelp := '0';
      csr.dcsr.pelp       := '0';
      csr.mseccfg.mlpe    := '0';
      csr.menvcfg.lpe     := '0';
      csr.henvcfg.lpe     := '0';
      csr.senvcfg.lpe     := '0';
    end if;

    -- PMP not implemented?
    if pmp_entries = 0 then
      csr.mseccfg.rlb  := '0';
      csr.mseccfg.mml  := '0';
      csr.mseccfg.mmwp := '0';
    end if;

    -- Clear unused PMP entries
    if pmp_entries < PMPENTRIES then
      csr.pmpcfg(pmp_entries to PMPENTRIES - 1)      := (others => (others => '0'));
      csr.pmpaddr(pmp_entries to PMPENTRIES - 1)     := (others => pmpaddrzero);
      csr.pmp_precalc(pmp_entries to PMPENTRIES - 1) := (others => pmp_precalc_none);
    end if;
    -- Clear unused PMA entries
    if pma_entries < PMAENTRIES then
      csr.pma_addr(pma_entries to PMAENTRIES - 1)     := (others => (others => '0'));
      csr.pma_data(pma_entries to PMAENTRIES - 1)     := (others => (others => '0'));
      csr.pma_precalc(pma_entries to PMAENTRIES - 1)  := (others => pmp_precalc_none);
    end if;
    if pma_masked /= 0 then
      csr.pma_addr(0 to PMAENTRIES - 1)               := (others => (others => '0'));
      csr.pma_precalc(0 to PMAENTRIES - 1)            := (others => pmp_precalc_none);
    end if;

    -- No extended PMP?
    if not ext_smepmp then
      csr.mseccfg.mml   := '0';
      csr.mseccfg.mmwp  := '0';
        csr.mseccfg.rlb := '0';
    end if;

    -- No Smrnmi?
    if not ext_smrnmi then
      csr.mnscratch := (others => '0');
      csr.mnepc     := (others => '0');
      csr.mncause   := cause_res;
      csr.mnstatus  := csr_mnstatus_rst;
    end if;

    -- Clear non-existing performance counters
    -- Should not be needed, but makes things clearer.
    for i in 0 to 2 loop
      csr.hpmcounter(i)    := (others => '0');
      csr.hpmevent(i)      := hpmevent_none;
    end loop;

    -- Clear unimplemented performance counters
    for i in perf_cnts + 3 to csr.hpmcounter'high loop
      csr.hpmcounter(i)    := (others => '0');
      csr.hpmevent(i)      := hpmevent_none;
      csr.mcountinhibit(i) := '0';
      csr.mcounteren(i)    := '0';
      csr.hcounteren(i)    := '0';
      csr.scounteren(i)    := '0';
    end loop;

    -- Clear unimplemented MSB:s of performance counters
    for i in csr.hpmcounter'range loop
      csr.hpmcounter(i)(csr.hpmcounter(0)'high downto perf_bits) := (others => '0');
    end loop;

    -- No MMU, no values writeable to address translation CSRs
    if mmuen = 0 then
      csr.satp  := atp_none;
      csr.vsatp := atp_none;
      csr.hgatp := atp_none;
    end if;


  end;
  

  -- Generate data address misaligned flag
  function data_addr_misaligned(addr : std_logic_vector;
                                size : word2) return boolean is
    -- Non-constant
    variable naligned : boolean := false;
  begin
    -- Generate not aligned flag.
    case size is
      when SZHALF =>
        if addr(0) /= '0' then
          naligned := true;
        end if;
      when SZWORD =>
        if addr(1 downto 0) /= "00" then
          naligned := true;
        end if;
      when SZDBL =>
        if addr(2 downto 0) /= "000" then
          naligned := true;
        end if;
      when others => -- byte
    end case;

    return naligned;
  end;

  -- Functional unit select
  function fusel_gen(active : extension_type;
                     inst   : word;
                     cfi_en : cfi_t := cfi_both
                    ) return fuseltype is
    variable ext_noelv   : boolean      := is_enabled(active, x_noelv);
    variable ext_a       : boolean      := is_enabled(active, x_a);
    variable ext_f       : boolean      := is_enabled(active, x_f);
    variable ext_h       : boolean      := is_enabled(active, x_h);
    variable ext_zbc     : boolean      := is_enabled(active, x_zbc);
    variable ext_zbkc    : boolean      := is_enabled(active, x_zbkc);
    variable ext_zimop   : boolean      := is_enabled(active, x_zimop);
    variable ext_zicfiss : boolean      := is_enabled(active, x_zicfiss);
    variable ext_zicfilp : boolean      := is_enabled(active, x_zicfilp);
    variable op          : opcode_type  := opcode(inst);
    variable rd          : reg_t        := rd(inst);
    variable rfa1        : reg_t        := rs1(inst);
    variable rfa2        : reg_t        := rs2(inst);
    variable funct3      : funct3_type  := funct3(inst);
    variable funct5      : funct5_type  := funct5(inst);
    variable funct7      : funct7_type  := funct7(inst);
    variable funct12     : funct12_type := funct12(inst);
    -- Non-constant
    variable fusel       : fuseltype    := UNKNOWN;
  begin
    case op is
      when LUI | OP_IMM | OP_IMM_32 =>
        fusel     := ALU;
      when AUIPC =>
        fusel     := ALU;
        if is_lpad(active, cfi_en, inst) then
          fusel   := ALU or CFI;
        end if;
      when OP_AMO =>
        if ext_a then
          if    funct5 = R_LR then
            fusel := (AMO or LD);
          elsif funct5 = R_SC then
            -- The fusel code for SC gets both LD and SD set!
            -- The reason is that SC returns a value from cctrl, even though
            -- it did not actually read that value from memory.
            -- Note that dcache_gen() ensures that SC is only passed as a write to cctrl.
            fusel := (AMO or LD or ST);
          else
            fusel := (AMO or LD or ST);
            if ext_zicfiss and funct5 = R_SSAMOSWAP then
              fusel := (AMO or LD or ST or CFI);
            end if;
          end if;
        end if;
      when OP_REG | OP_32 =>
        if funct7 = F7_MUL then
          fusel   := MUL;
        else
          fusel   := ALU;
        end if;
        -- R_CLMULR is not actually valid for ext_zbkc, but that does not matter here.
        if (ext_zbc or ext_zbkc) and op = OP_REG and funct7 = F7_MINMAXCLMUL and
           (funct3 = R_CLMUL or funct3 = R_CLMULH or funct3 = R_CLMULR) then
          fusel := ALU or ALU_SPECIAL;
        end if;
      when OP_FP =>
        if ext_f then
          if funct5 = R_FCMP or funct5 = R_FMV_X_W or funct5 = R_FCVT_W_S then
            fusel := FPU;
          end if;
        end if;
      when OP_STORE | OP_STORE_FP =>
        fusel     := ST;
      when OP_LOAD  | OP_LOAD_FP =>
        fusel     := LD;
      when OP_JAL =>
        fusel     := JAL;
      when OP_JALR =>
        fusel     := JALR;
        if ext_zicfilp and cfi_en.lp then
          if rfa1 /= "00001" and rfa1 /= "00101" and rfa1 /= "00111" then
            fusel := JALR or CFI;
          end if;
        end if;
      when OP_BRANCH =>
        fusel     := BRANCH;
      when OP_SYSTEM =>
        if (ext_h or ext_zimop) and funct3 = "100" then
          case funct7 is
            when F7_HLVB | F7_HLVH | F7_HLVW | F7_HLVD =>
              if ext_h then
                fusel := LD;
              end if;
            when F7_HSVB | F7_HSVH | F7_HSVW | F7_HSVD =>
              if ext_h then
                fusel := ST;
              end if;
            when F7_MOPR_0  | F7_MOPR_4  | F7_MOPR_8  | F7_MOPR_12 |
                 F7_MOPR_16 | F7_MOPR_20 | F7_MOPR_24 | F7_MOPR_28 =>
              if ext_zimop then
                fusel := ALU;
                if is_sspopchk(active, cfi_en, inst) then
                  fusel := LD or CFI;  -- ALU?
                elsif is_ssrdp(active, cfi_en, inst) then
                  fusel := CFI;
                end if;
              end if;
            when F7_MOPRR_0 | F7_MOPRR_1 | F7_MOPRR_2 | F7_MOPRR_3 |
                 F7_MOPRR_4 | F7_MOPRR_5 | F7_MOPRR_6 | F7_MOPRR_7  =>
              if ext_zimop then
                fusel   := ALU;
                if is_sspush(active, cfi_en, inst) then
                  fusel := ST or CFI;
                end if;
              end if;
            when others =>
              -- Nothing else is possible!
              null;
          end case;
        elsif funct3 /= "000" then
          fusel   := ALU;
        end if;
      when OP_CUSTOM0 =>
        if is_diag(active, inst) then
          if is_diag_store(inst) then
            fusel := (DIAG or ST);
          else
            fusel := (DIAG or LD);
          end if;
        elsif is_custom_alu(active, inst) then
          fusel   := ALU;
        end if;
      when others => null;
    end case;

    return fusel;
  end;

  -- CSRALU record generation
  -- Selects the type of operation and the control bits for that operation.
  function csralu_gen(inst : word) return word2 is
    variable op     : opcode_type := opcode(inst);
    variable funct3 : funct3_type := funct3(inst);
    -- Non-constant
    variable ctrl   : word2       := CSR_BYPASS;
  begin
    -- Assuming the ALU is needed (based on the decoded fusel)
    case op is
      when OP_SYSTEM =>
        case funct3 is
          when I_CSRRS | I_CSRRSI => ctrl := CSR_SET;
          when I_CSRRC | I_CSRRCI => ctrl := CSR_CLEAR;
          when others             => null;             -- I_CSRRW | I_CSRRWI
        end case;
      when others                 => null;
    end case;

    return ctrl;
  end;

  -- CSR operation
  function csralu_op(op1  : wordx;
                     op2  : wordx;
                     ctrl : word2) return wordx is
    -- Non-constant
    variable res : wordx;
  begin
    case ctrl is
      when CSR_SET   => res := op2 or      op1;   -- OR
      when CSR_CLEAR => res := op2 and not op1;   -- ANDN
      when others    => res := op1;               -- BYPASS1
    end case;

    return res;
  end;

  -- Address generation for Load/Store unit.
  procedure addr_gen(active    : in  extension_type;
                     inst_in   : in  word;
                     fusel_in  : in  fuseltype;
                     valid_in  : in  std_ulogic;
                     op1_in    : in  wordx;
                     op2_in    : in  wordx;
                     ssp       : in  wordx;
                     address   : out wordx;
                     xc_out    : out std_ulogic;
                     cause_out : out cause_type;
                     tval_out  : out wordx) is
    variable ext_a       : boolean     := is_enabled(active, x_a);
    variable ext_h       : boolean     := is_enabled(active, x_h);
    variable ext_zicbom  : boolean     := is_enabled(active, x_zicbom);
    variable ext_zicfiss : boolean     := is_enabled(active, x_zicfiss);
    variable funct3      : funct3_type := funct3(inst_in);
    variable rfa1        : reg_t       := rs1(inst_in);
    variable size        : word2       := funct3(1 downto 0);
    -- Non-constant
    variable xc     : std_ulogic  := '0';
    variable cause  : cause_type  := cause_none;
    variable op1    : wordx       := op1_in;
    variable op2    : wordx       := op2_in;
    variable add    : wordx1;
  begin
    -- SSPUSH / SSPOP
    if ext_zicfiss and v_fusel_eq(fusel_in, CFI) then
      op2     := (others => '0');
      -- SSPUSH/SSPPOPCHK use SSP, unlike SSAMOSWAP (op2 cleared below as well)
      -- They also used fixed size.
      if not v_fusel_eq(fusel_in, AMO) then
        size  := cond(XLEN = 64, "11", "10");
        op1   := ssp;
        if v_fusel_eq(fusel_in, ST) then
          op2 := s2vec(-8, op2);
        end if;
      end if;
    end if;

    if (ext_a and v_fusel_eq(fusel_in, AMO)) or
       (ext_h and
        (is_hlsv(inst_in) or is_hfence_vvma(active, inst_in) or is_hfence_gvma(active, inst_in))) or
       is_sfence_vma(active, inst_in) or
       v_fusel_eq(fusel_in, DIAG) or
       (ext_zicbom and is_cbo(inst_in)) then
      op2 := (others => '0');
    end if;

    add  := std_logic_vector(signed('0' & op1) + signed(get_hi(op2) & op2));

    if ext_h and is_hlsv(inst_in) then
      size := inst_in(27 downto 26);
    end if;

    -- Do not check for sfence.vma here, since it does not actually access anything.
    if v_fusel_eq(fusel_in, LD or ST or AMO) and data_addr_misaligned(add, size) then
      xc        := '1';
      -- Normally, address misaligned access is higher priority than
      -- access fault, but this reversal for AMO is allowed (see below).
      cause     := XC_INST_LOAD_ADDR_MISALIGNED;
      if v_fusel_eq(fusel_in, ST) then
        cause   := XC_INST_STORE_ADDR_MISALIGNED;
      end if;
      -- Make misaligned atomics throw access faults so that no emulation
      -- is attempted (allowed according to the RISC-V standard.)
      if ext_a and v_fusel_eq(fusel_in, AMO) then
        cause   := XC_INST_STORE_ACCESS_FAULT;
        if inst_in(28) = '1' and inst_in(27) = '0' then     -- LR?
          cause := XC_INST_LOAD_ACCESS_FAULT;
        end if;
      end if;
    end if;

    address   := add(address'range);
    xc_out    := xc and valid_in;
    cause_out := cause;
    tval_out  := add(tval_out'range);
  end;

  -- Load aligner for 64-bit word

  function ld_align64(data   : word64;
                      size   : word2;
                      laddr  : word3;
                      signed : std_ulogic) return word64 is
    -- Non-constant
    variable rdata : word64    := data;
    variable high  : std_logic := data(63);
  begin
    if size = SZWORD or size = SZHALF or size = SZBYTE then
      if laddr(2) = '1' then
        rdata(31 downto 0) := rdata(63 downto 32);
      else
        high               := rdata(31);
      end if;
    end if;

    if  size = SZHALF or size = SZBYTE then
      if laddr(1) = '1' then
        rdata(15 downto 0) := rdata(31 downto 16);
      else
        high               := rdata(15);
      end if;
    end if;

    if size = SZBYTE then
      if laddr(0) = '1' then
        rdata(7 downto 0) := rdata(15 downto 8);
      else
        high              := rdata(7);
      end if;
    end if;

    high := high and signed;

    if size = SZWORD or size = SZHALF or size = SZBYTE then
      rdata(63 downto 32) := (others => high);
    end if;
    if size = SZHALF or size = SZBYTE then
      rdata(31 downto 16) := (others => high);
    end if;
    if size = SZBYTE then
      rdata(15 downto  8) := (others => high);
    end if;

    return rdata;
  end;

  -- Return xc_v in lsb and xc in msb
  function stimecmp_xc(csr_file : csr_reg_type;
                       h_en     : boolean;
                       is_rv64  : boolean;
                       csra     : csratype;
                       v_mode   : boolean) return xc_type is
    variable is_s_csr     : boolean := csra = CSR_STIMECMP  or csra = CSR_STIMECMPH ;
    variable is_high_half : boolean := csra = CSR_STIMECMPH or csra = CSR_VSTIMECMPH;
    -- Non-constant
    variable ret  : xc_type := XC_NONE;
  begin
    if not(csra = CSR_STIMECMP or csra = CSR_STIMECMPH or csra = CSR_VSTIMECMP or csra = CSR_VSTIMECMPH) then
      return XC_NONE;
    end if;

    assert (not(v_mode and not h_en)) report "Illegal input value" severity failure;

    -- Always illegal on rv64
    if is_high_half and is_rv64 then
      return XC_ILLEGAL;
    end if;

    -- Always illegal if virtualized when misa.h is 0
    -- Maybe a redundant check, csr_file.v should not be able to become 1 if h_en = 0
    if not h_en and csr_file.v = '1' and is_s_csr then
      assert false report "This should be unreachable" severity failure;
      return XC_ILLEGAL;
    end if;

    -- VS csr is never available when misa.h isn't set independent of the privilege mode.
    if not is_s_csr and not h_en then
      return XC_ILLEGAL;
    end if;

    -- We don't need to check for if we are virtualized or not, that is done by the address range check.
    if csr_file.prv /= PRIV_LVL_M then
      -- mcounteren.tm = 0 raises illegal insn if prv /= prv_m
      -- menvcfg.stce  = 0 raises illegal insn if prv /= prv_m
      if csr_file.mcounteren(1) = '0' or csr_file.menvcfg.stce = '0' then
        return XC_ILLEGAL;
      end if;
    end if;

    -- No need to check M mode since v_mode is always zero if in M mode
    -- Raise virtual if mcounteren is set but not hcounteren.
    -- Raise virtual if menvcfg is set but not henvcfg
    if (csr_file.mcounteren(1) = '1' and csr_file.hcounteren(1) = '0') or
       (csr_file.menvcfg.stce  = '1' and csr_file.henvcfg.stce  = '0') then
      -- xc_v := v_mode;
      -- In S or M mode we shouldn't raise an exception no matter henvcfg/hcounterern
      -- In VS/VU we should raise an exception and in that case v_mode will be set.
      -- xc   := v_mode;
      return xc_type'(xc => v_mode, xc_v => v_mode);
    end if;

    if csr_file.prv = PRIV_LVL_U then
      -- Only raise virtual if the mcounteren and menvcfg check didn't raise an illegal xc.
      return xc_type'(xc => true, xc_v => v_mode);
    end if;


    -- Always rise virtual when virtualized and hvictl.vti is set
    if csr_file.v = '1' and csr_file.hvictl.vti = '1' then
      return XC_VIRT;
    end if;

    -- VS CSRs are always illegal when virtualized
    if csr_file.v = '1' and not is_s_csr then
      return XC_VIRT;
    end if;

    return ret;
  end function;

  function ssaia_indirect_xc(csr_file   : csr_reg_type;
                             sel        : select_t;
                             active     : extension_type;
                             imsic      : boolean) return xc_type is
    variable ext_ssaia  : boolean := is_enabled(active, x_ssaia);
    variable is_rv64    : boolean := is_enabled(active, x_rv64);
    variable h_en       : boolean := csr_file.misa(h_ctrl) = '1';
    variable v_mode     : boolean := h_en and csr_file.v = '1';
    variable vu_mode    : boolean := v_mode and csr_file.prv = PRIV_LVL_U;
  begin
    assert (is_imsic(sel) or is_aia_iprio(sel));
    if ext_ssaia then -- This check is probably not needed, since imsic implies ssaia?
      if sel.sel(0) = '1' and is_rv64 then
        -- for 64-bits architecture accesing IPRIO or IMSIC odd indirect registers
        -- produce an exception
        return XC_ILLEGAL;
      end if;
      if v_mode then
        if is_aia_iprio(sel) then
          -- IPRIO is inaccessible in V mode but can be virtualized
          return XC_VIRT;
        else --is_imsic(sel)=ture
          if not imsic or
            not vgein_legal(u2i(csr_file.hstatus.vgein)) then
            return XC_VIRT;
          end if;
        end if;
      else -- Not V mode
        if not imsic or
        (csr_file.mvien(IRQ_S_EXTERNAL) = '1' and csr_file.prv = PRIV_LVL_S) then
          return xc_type'(xc => true, xc_v => vu_mode);
        end if;
      end if;
    else -- Ssaia not implemented
      return XC_ILLEGAL;
    end if;
    return XC_NONE;
  end function;

  -- Function assumes that genernal csr address, stateen and smcsrind checks are done elsewhere.
  function smcdeleg_indirect_xc(csr_file      : csr_reg_type;
                                ext_smcdeleg  : boolean;
                                ext_sscofpmf  : boolean;
                                ext_zicntr    : boolean;
                                ext_zihpm     : boolean;
                                ext_smcntrpmf : boolean;
                                is_rv64       : boolean;
                                csra          : csratype;
                                v_mode        : boolean) return xc_type is
    constant reserved_select    : integer := 16#41#;
    -- HS
    variable siselect           : integer := u2i(csr_file.siselect.sel);
    variable siselect_in_range  : boolean := is_smcdeleg(csr_file.siselect);
    variable s_cnt_sel          : integer := siselect  -  CSRIND_SMCDELEG_LOW;
    -- VS
    variable vsiselect_in_range : boolean := is_smcdeleg(csr_file.vsiselect);
    -- Non-constant
  begin
    assert is_sireg(csra) or is_vsireg(csra);
    if ext_smcdeleg then
      -- Sireg*
      if is_sireg(csra) then
        -- While the privilege mode is M or S
        if not v_mode then
          -- NOTE: U-mode gets here too but, worst case an illegal is thrown which is what we wanted anyway
          -- Furthermore, PRV_U does not need to be checked explicitly since that will be done by the csr address check later.

          -- ... and siselect holds a value in the range 0x40-0x5F, illegal
          -- instruction exceptions are raised for the following cases:
          if siselect_in_range then
            assert siselect_in_range;
            -- * attempts to access any sireg* when menvcfg.CDE = 0;
            -- Any sireg* is implicit here!
            if csr_file.menvcfg.cde = '0' then
              return XC_ILLEGAL;
            end if;

            -- * attempts to access sireg3 or sireg6;
            if csra = CSR_SIREG3 or csra = CSR_SIREG6 then
              return XC_ILLEGAL;
            end if;

            -- * attempts to access sireg4 or sireg5 when XLEN = 64;
            if (csra = CSR_SIREG4 or csra = CSR_SIREG5) and is_rv64 then
              return XC_ILLEGAL;
            end if;

            -- * attempts to access sireg* when siselect = 0x41, or when the counter selected by siselect is not
            -- delegated to S-mode (the corresponding bit in mcounteren = 0)
            if siselect = reserved_select or csr_file.mcounteren(s_cnt_sel) = '0' then
              return XC_ILLEGAL;
            end if;

            -- For each siselect and sireg* combination defined in Table 20 (Indirect HPM State mappings),
            -- the table further indicates the extensions upon which the underlying counter state depends.
            -- If any extension upon which the underlying state depends is not implemented,
            -- an attempt from M or S mode to access the given state through sireg* raises an illegal instruction exception
            if siselect = 16#40# or siselect = 16#42# then
              -- Zicntr needed by sireg*
              if not ext_zicntr then
                return XC_ILLEGAL;
              end if;
              if (csra = CSR_SIREG2 or csra = CSR_SIREG5) and not ext_smcntrpmf then
                return XC_ILLEGAL;
              end if;
            -- elsif siselect = 16#41# already handled by reserved_select
            -- NOTE: Upper bound already checked by siselect_in_range
            elsif siselect >= 16#43# then
              -- Zihpm needed by sireg*
              if not ext_zihpm then
                return XC_ILLEGAL;
              end if;
              if csra = CSR_SIREG5 and not ext_sscofpmf then
                return XC_ILLEGAL;
              end if;
            else
              assert false report "This should not happen" severity failure;
            end if;

          end if;
        else -- V mode
          -- If the hypervisor (H) extension is also implemented, then as specified by extension Smcsrind/Sscsrind,
          -- a virtual instruction exception is raised for attempts from VS-mode or VU-mode to directly access
          -- vsiselect or vsireg*, or attempts from VU-mode to access siselect or sireg*.
          -- NOTE: Handled by csrind_reg_xc (nvsupport.vhd)

          -- Furthermore, while vsiselect holds a value in the range 0x40-0x5F
          -- * An attempt from VS-mode to access any sireg* (really vsireg*) raises an illegal instruction
          -- exception if menvcfg.CDE = 0, or a virtual instruction exception if menvcfg.CDE = 1
          if csr_file.prv = PRIV_LVL_S then
            assert vsiselect_in_range;
            -- VS mode always traps
            return xc_type'(xc => true, xc_v => csr_file.menvcfg.cde = '1');
          end if;
        end if;

      else -- VSIREG* (caller and assert makes sure this means VSIREG*)
      -- Furthermore, while vsiselect holds a value in the range 0x40-0x5F:
        assert vsiselect_in_range;
        -- * An attempt to access any vsireg* from M or S mode raises an illegal instruction exception.
        if not v_mode and csr_file.prv /= PRIV_LVL_U then
          return XC_ILLEGAL;
        end if;

      end if;

    else -- Extension not implemented throw exception if (v)siselct points to a range reserved by smcdeleg.
      assert siselect_in_range or vsiselect_in_range;
      return XC_ILLEGAL;
    end if;

    return XC_NONE;
  end function;

  function smcdeleg_indirect_read(csr_file : csr_reg_type; csra : csratype) return wordx is
    variable siselect  : integer := u2i(csr_file.siselect.sel);
    variable s_cnt_sel : integer := siselect  -  CSRIND_SMCDELEG_LOW;
    -- Non-constant
    -- Specifically, event selector bit 62 (MINH) is read-only 0 when accessed through sireg*.
    variable hpme_msk  : hpmevent_type;
  begin

    assert siselect >= CSRIND_SMCDELEG_LOW and siselect <= CSRIND_SMCDELEG_HIGH
    report "Called in wrong context!" severity failure;

    case csra is
      when CSR_SIREG =>
        if siselect = 16#40# then
          return csr_file.mcycle(wordx'range);
        elsif siselect = 16#42# then
          return csr_file.minstret(wordx'range);
        elsif siselect >= 16#43# then
          return csr_file.hpmcounter(s_cnt_sel)(wordx'range);
        end if;
      when CSR_SIREG4 => -- High-half only 32-bits
        if siselect = 16#40# then
          return to0x(hi_h(csr_file.mcycle));
        elsif siselect = 16#42# then
          return to0x(hi_h(csr_file.minstret));
        elsif siselect >= 16#43# then
          return to0x(hi_h(csr_file.hpmcounter(s_cnt_sel)));
        end if;
      when CSR_SIREG2 =>
        if siselect = 16#40# then
          -- return (csr_file.mcyclecfg and min_mask)(wordx'range);
          return zerox;
        elsif siselect = 16#42# then
          -- return (csr_file.minstretcfg and min_mask)(wordx'range);
          return zerox;
        elsif siselect >= 16#43# then
          hpme_msk      := csr_file.hpmevent(s_cnt_sel);
          hpme_msk.minh := '0';
          return to_hpmevent(hpme_msk);
          -- Don't allow minh to be written
        end if;
      when CSR_SIREG5 => -- High-half only 32-bits
        if siselect = 16#40# then
          -- return to0x(hi_h(csr_file.mcyclecfg and min_mask));
          return zerox;
        elsif siselect = 16#42# then
          -- return to0x(hi_h(csr_file.minstretcfg and min_mask));
          return zerox;
        elsif siselect >= 16#43# then
          hpme_msk      := csr_file.hpmevent(s_cnt_sel);
          hpme_msk.minh := '0';
          return to_hpmeventh(hpme_msk);
        end if;
      when others => return zerox;
    end case;
    return zerox;
  end function;

  procedure smcdeleg_indirect_write(csra         : in csratype;
                                    wcsr_in      : in wordx;
                                    csr_file     : inout csr_reg_type;
                                    upd_mcycle   : inout std_logic;
                                    upd_minstret : inout std_logic;
                                    upd_counter  : inout std_logic_vector) is
    subtype high_range is natural range 63 downto 32;
    subtype low_range  is natural range 31 downto 0;
    variable siselect  : integer := u2i(csr_file.siselect.sel);
    variable s_cnt_sel : integer := siselect - CSRIND_SMCDELEG_LOW;
    -- Non-constant
    -- Specifically, event selector bit 62 (MINH) is read-only 0 when accessed through sireg*.
    variable hpme_msk  : hpmevent_type;
  begin
    assert siselect >= CSRIND_SMCDELEG_LOW and siselect <= CSRIND_SMCDELEG_HIGH
    report "Called in wrong context!" severity failure;

    case csra is
      when CSR_SIREG =>
        if siselect = 16#40# then
          csr_file.mcycle(wordx'range)                := wcsr_in;
          upd_mcycle                                  := '1';
        elsif siselect = 16#42# then
          csr_file.minstret(wordx'range)              := wcsr_in;
          upd_minstret                                := '1';
        elsif siselect >= 16#43# then
          csr_file.hpmcounter(s_cnt_sel)(wordx'range) := wcsr_in;
          upd_counter(s_cnt_sel)                      := '1';
        end if;
      when CSR_SIREG4 => -- High-half only 32-bits
        if siselect = 16#40# then
          csr_file.mcycle(high_range)                := wcsr_in(low_range);
          upd_mcycle                                  := '1';
        elsif siselect = 16#42# then
          csr_file.minstret(high_range)              := wcsr_in(low_range);
          upd_minstret                                := '1';
        elsif siselect >= 16#43# then
          csr_file.hpmcounter(s_cnt_sel)(high_range) := wcsr_in(low_range);
          upd_counter(s_cnt_sel)                      := '1';
        end if;
      when CSR_SIREG2 =>
        if siselect = 16#40# then
          -- csr_file.mcyclecfg(high_range)  := wcsr_in and min_mask;
        elsif siselect = 16#42# then
          -- csr_file.minstrecfg(high_range) := wcsr_in and min_mask;
        elsif siselect >= 16#43# then
          -- Don't allow minh to be written
          hpme_msk      := to_hpmevent(wcsr_in, csr_file.hpmevent(s_cnt_sel));
          hpme_msk.minh := csr_file.hpmevent(s_cnt_sel).minh;
          csr_file.hpmevent(s_cnt_sel) := hpme_msk;
        end if;
      when CSR_SIREG5 => -- High-half only 32-bits
        if siselect = 16#40# then
          -- csr_file.mcyclecfg   := wcsr_in and min_mask;
        elsif siselect = 16#42# then
          -- csr_file.minstretcfg := wcsr_in and min_mask));
        elsif siselect >= 16#43# then
          -- Don't allow minh to be written
          hpme_msk      := to_hpmeventh(wcsr_in, csr_file.hpmevent(s_cnt_sel));
          hpme_msk.minh := csr_file.hpmevent(s_cnt_sel).minh;
          csr_file.hpmevent(s_cnt_sel) := hpme_msk;
        end if;
      when others =>
    end case;
  end procedure;


  -- Exception Check
  -- Exception check unit located in Decode stage.
  -- Searches for illegal instructions, breakpoints and environmental calls.
  procedure exception_check(active    : in  extension_type;
                            menvcfg   : in  csr_menvcfg_type;
                            henvcfg   : in  csr_henvcfg_type;
                            senvcfg   : in  csr_senvcfg_type;
                            fpu_en    : in  boolean;
                            fpu_ok    : in  boolean;
                            alu_ok    : in  boolean;
                            tval_ill0 : in  boolean;
                            diag_s    : in  boolean;
                            inst_in   : in  word;
                            cinst_in  : in  word16;
                            comp      : in  std_ulogic;
                            pc_in     : in  std_logic_vector;  -- pctype
                            comp_ill  : in  std_ulogic;
                            misa_in   : in  wordx;
                            prv_in    : in  priv_lvl_type;
                            v_in      : in  std_ulogic;
                            tsr_in    : in  std_ulogic;
                            tw_in     : in  std_ulogic;
                            tvm_in    : in  std_ulogic;
                            vtsr_in   : in  std_ulogic;
                            vtw_in    : in  std_ulogic;
                            vtvm_in   : in  std_ulogic;
                            hu        : in  std_ulogic;
                            xc_out    : out std_ulogic;
                            cause_out : out cause_type;
                            tval_out  : out wordx) is
    variable is_rv64     : boolean       := is_enabled(active, x_rv64);
    variable is_rv32     : boolean       := not is_rv64;
    variable mode_s      : boolean       := is_enabled(active, x_mode_s);
    variable ext_noelv   : boolean       := is_enabled(active, x_noelv);
    variable ext_a       : boolean       := is_enabled(active, x_a);
    variable ext_m       : boolean       := is_enabled(active, x_m);
    variable ext_smrnmi  : boolean       := is_enabled(active, x_smrnmi);
    variable ext_zimop   : boolean       := is_enabled(active, x_zimop);
    variable ext_zicbom  : boolean       := is_enabled(active, x_zicbom);
    variable ext_zicboz  : boolean       := is_enabled(active, x_zicboz);
    variable ext_zicfiss : boolean       := is_enabled(active, x_zicfiss);
    variable ext_svinval : boolean       := is_enabled(active, x_svinval);
    variable h_en        : boolean       := misa_in(h_ctrl) = '1';
    variable x_en        : boolean       := misa_in(x_ctrl) = '1';
    variable rfa1        : reg_t         := rs1(inst_in);
    variable rfa2        : reg_t         := rs2(inst_in);
    variable rd          : reg_t         := rd(inst_in);
    variable opcode      : opcode_type   := opcode(inst_in);
    variable funct3      : funct3_type   := funct3(inst_in);
    variable funct7      : funct7_type   := funct7(inst_in);
    variable funct12     : funct12_type  := funct12(inst_in);
    variable funct5      : funct5_type   := funct5(inst_in);
    variable diag_legal  : word16        := "0011001011001111";
    -- Non-constant
    variable xc_v        : std_ulogic    := '0'; -- Virtual instruction exception
    variable hv_op       : std_ulogic    := '0';
    variable hv_valid    : std_ulogic    := '0';
    variable zimop_op    : std_ulogic    := '0';
    variable illegal     : std_ulogic    := '0';
    variable xc          : std_ulogic;
    variable prv         : priv_lvl_type := prv_in;
    variable ecall       : std_ulogic    := '0';
    variable ebreak      : std_ulogic    := '0';
    variable cause       : cause_type    := cause_none;
    variable tval        : wordx;
    variable diag_inst   : word4;
    variable xc_tmp      : xc_type := XC_NONE;
  begin
    case opcode is
      when LUI | OP_JAL =>
        -- LUI with rd = x0 are standard HINTs.
        null;

      when AUIPC =>
        -- AUIPC with rd = x0 are standard HINTs.
        -- Except that with CFI they are LPAD instructions.
        null;

      when OP_JALR =>
        case funct3 is
          when I_JALR => null;
          when others => illegal := '1';
        end case;

      when OP_BRANCH =>
        case funct3 is
          when B_BEQ | B_BNE  | B_BLT |
               B_BGE | B_BLTU | B_BGEU => null;
          when others                  => illegal := '1';
        end case;

      when OP_LOAD =>
        case funct3 is
          when I_LB  | I_LH  | I_LW  |
               I_LBU | I_LHU | I_LWU | I_LD => null;
          when others                       => illegal := '1';
        end case;
        if is_rv32 and (funct3 = I_LD or funct3 = I_LWU) then
          illegal := '1';
        end if;

      when OP_STORE =>
        case funct3 is
          when S_SB | S_SH | S_SW | S_SD => null;
          when others                    => illegal := '1';
        end case;
        if is_rv32 and funct3 = S_SD then
          illegal := '1';
        end if;

      when OP_IMM | OP_IMM_32 =>
        illegal := not to_bit(alu_ok);

      when OP_REG =>
        if funct7 = F7_MUL then
          if ext_m then
            -- No need to check funct3 here!
            -- R_MUL / R_MULH / R_MULHSU / R_MULHU and
            -- R_DIV / R_DIVU / R_REM / R_REMU are all OK.
          else
            illegal := '1';
          end if;
        else
          illegal := not to_bit(alu_ok);
        end if;

      when OP_32 =>
        if funct7 = F7_MUL then
          if ext_m and is_rv64 then
            case funct3 is
              when R_MULW | R_DIVW | R_DIVUW | R_REMW | R_REMUW => null;
              when others => illegal := '1';
            end case;
          else
            illegal := '1';
          end if;
        else
          illegal := not to_bit(alu_ok);
        end if;

      when OP_FENCE =>
        case funct3 is
          when I_FENCE =>
              --   28   24   20    15  12     7
              -- __fm pred succ __rs1 000 ___rd 0001111
              -- rd  = x0, rs1 /= x0, fm = 0 and (pred = 0 or succ = 0) are standard HINTs.
              -- rd /= x0, rs1  = x0, fm = 0 and (pred = 0 or succ = 0) are standard HINTs.
              -- rd  = x0, rs1  = x0, fm = 0, pred  = 0, succ /= 0 are standard HINTs.
              -- rd  = x0, rs1  = x0, fm = 0, pred /= W, succ  = 0 are standard HINTs.
              -- rd  = x0, rs1  = x0, fm = 0, pred  = W, succ  = 0 is standard HINT (PAUSE).

          when I_FENCE_I =>

          when I_CBO =>
            -- RD is zero for all cbo instructions.
            if u2i(rd) = 0 then
              if    ext_zicbom and (u2i(funct12) = 1 or u2i(funct12) = 2) then -- cbo.clean/flush
                xc_tmp := require_envcfg(mode_s, prv_in, v_in, menvcfg.cbcfe, henvcfg.cbcfe, senvcfg.cbcfe);
              elsif ext_zicbom and u2i(funct12) = 0 then -- cbo.inval
                xc_tmp := require_envcfg(mode_s, prv_in, v_in, menvcfg.cbie(0), henvcfg.cbie(0), senvcfg.cbie(0));
              elsif ext_zicboz and u2i(funct12) = 4 then -- cbo.zero
                xc_tmp := require_envcfg(mode_s, prv_in, v_in, menvcfg.cbze, henvcfg.cbze, senvcfg.cbze);
              else
                illegal := '1';
              end if;
              if xc_tmp = XC_ILLEGAL then
                illegal := '1';
              elsif xc_tmp = XC_VIRT then
                illegal := '1';
                xc_v    := '1';
              end if;
            else
              illegal := '1';
            end if;

          when others =>
            illegal := '1';
        end case;

      when OP_SYSTEM =>
        case funct3 is
          when "000" =>
            if rd /= "00000" then
              illegal   := '1';
            else
              case funct7 is
                when F7_URET => -- ECALL, EBREAK, URET (not supported)
                  if rfa1 = "00000" then
                    case rfa2 is
                      when "00000" => ecall   := '1'; -- ECALL
                      when "00001" => ebreak  := '1'; -- EBREAK
                      when others  => illegal := '1';
                    end case;
                  else
                    illegal := '1';
                  end if;

                when F7_SRET => -- SRET, WFI
                  if rfa1 = "00000" then
                    case rfa2 is
                      when "00010" => -- SRET
                        if not mode_s then
                          illegal := '1';
                        end if;
                        -- The TSR (Trap SRET) bit supports intercepting the supervisor exception
                        -- return instruction, SRET. When TSR=1, attempts to execute SRET while
                        -- executing in S-mode will raise an illegal instruction exception.
                        -- When TSR=0, this operation is permitted in S-mode.
                        -- TSR is hard-wired to 0 when S-mode is not supported.
                        if ((not h_en) or v_in = '0') and
                           (prv_in = PRIV_LVL_U or (prv_in = PRIV_LVL_S and tsr_in = '1')) then
                          illegal := '1';
                        end if;
                        -- In VS-mode, attempts to execute SRET when hstatus.VTSR=1, or
                        -- in VU-mode, attempts to execute supervisor instruction SRET,
                        -- will raise a virtual instruction trap.
                        if (h_en and v_in = '1') and ((prv_in = PRIV_LVL_S and vtsr_in = '1') or
                                                      prv_in = PRIV_LVL_U) then
                          illegal := '1';
                          xc_v := '1';
                        end if;

                      when "00101" => -- WFI
                        -- The TW (Timeout Wait) bit supports intercepting the WFI instruction.
                        -- When TW=0, the WFI instruction is permitted in S-mode.
                        -- When TW=1, if WFI is executed in S-mode, and it does not complete
                        -- within an implementation-specific, bounded time limit, the
                        -- WFI instruction causes an illegal instruction trap. The time limit
                        -- may always be 0, in which case WFI always causes an illegal instruction
                        -- trap in S-mode when TW=1. TW is hard-wired to 0 when
                        -- S-mode is not supported.
                        -- When S-mode is implemented, then executing WFI in U-mode causes an
                        -- illegal instruction exception

                        -- In VS-mode, attempts to execute WFI when hstatus.VTW=1 and mstatus.TW=0, or
                        -- in VU-mode, attempts to execute WFI when mstatus.TW=0, will raise a virtual
                        -- instruction trap.

                        if ((not h_en) or v_in = '0') and
                           (prv_in = PRIV_LVL_U or (prv_in = PRIV_LVL_S and tw_in = '1')) then
                          illegal := '1';    -- timeout = 0
                        elsif (h_en and v_in = '1') then
                          if tw_in = '1' then
                            illegal := '1';  -- timeout = 0
                          elsif (prv_in = PRIV_LVL_S and vtw_in = '1') or
                                (prv_in = PRIV_LVL_U) then
                            illegal := '1';  -- timeout = 0
                            xc_v := '1';
                          end if;
                        end if;

                      when others =>
                        illegal := '1';
                    end case;
                  else
                    illegal := '1';
                  end if;

                when F7_MRET =>
                  if rfa1 = "00000" and rfa2 = "00010" then
                    if prv_in = PRIV_LVL_S or prv_in = PRIV_LVL_U then
                      illegal := '1';
                    end if;
                  else
                    illegal   := '1';
                  end if;

                when F7_MNRET =>
                  if rfa1 = "00000" and rfa2 = "00010" and ext_smrnmi then
                    if prv_in = PRIV_LVL_S or prv_in = PRIV_LVL_U then
                      illegal := '1';
                    end if;
                  else
                    illegal   := '1';
                  end if;

                when F7_SFENCE_VMA | F7_SINVAL_VMA =>
                  -- The TVM (Trap Virtual Memory) bit supports intercepting supervisor
                  -- virtual-memory management operations. When TVM=1, attempts to read
                  -- or write the satp CSR, or execute the SFENCE.VMA instruction while
                  -- executing in S-mode, will raise an illegal instruction exception.
                  -- When TVM=0, these operations are permitted in S-mode.
                  -- TVM is hard-wired to 0 when S-mode is not supported.
                  illegal := to_bit(not mode_s);

                  if ((not h_en) or v_in = '0') and prv_in = PRIV_LVL_S and tvm_in = '1' then
                    illegal := '1';
                  end if;
                  -- In VS-mode, attempts to execute an SFENCE instruction when hstatus.VTVM=1, or
                  -- in VU-mode, attempts to execute an SFENCE instruction, will raise a virtual
                  -- instruction trap.
                  if (h_en and v_in = '1') and ((prv_in = PRIV_LVL_S and vtvm_in = '1') or
                                                 prv_in = PRIV_LVL_U) then
                    illegal := '1';
                    xc_v    := '1';
                  end if;

                  if prv_in = PRIV_LVL_U then
                    illegal := '1';
                  end if;

                  if not ext_svinval and funct7 = F7_SINVAL_VMA then
                    illegal := '1';
                    xc_v    := '0';
                  end if;

                when F7_SFENCE_INVAL =>
                  -- According to the standard, these never need to trap on TVM/VTVM.
                  -- Enough to check for svinval here since svinval can't exist without mode_s.
                  if ext_svinval then
                    if rfa1 /= "00000" or (rfa2 /= "00000" and rfa2 /= "00001") then
                      illegal := '1';
                    end if;

                    if prv_in = PRIV_LVL_U then
                      illegal := '1';
                    end if;
                    xc_v := v_in;
                  else
                    illegal   := '1';
                  end if;

                when F7_HFENCE_VVMA | F7_HINVAL_VVMA =>
                  if h_en then
                    if v_in = '1' then
                      illegal := '1';
                      xc_v    := '1';
                    end if;
                  else
                    illegal   := '1';
                  end if;

                  if prv_in = PRIV_LVL_U then
                    illegal := '1';
                  end if;

                  if not ext_svinval and funct7 = F7_HINVAL_VVMA then
                    illegal   := '1';
                    xc_v      := '0';
                  end if;

                when F7_HFENCE_GVMA | F7_HINVAL_GVMA =>
                  if h_en then
                    if v_in = '0' then
                      if (prv_in = PRIV_LVL_S and tvm_in = '1') or prv_in = PRIV_LVL_U then
                        illegal := '1';
                      end if;
                    else
                      illegal   := '1';
                      xc_v      := '1';
                    end if;
                  else
                    illegal     := '1';
                  end if;

                  if prv_in = PRIV_LVL_U then
                    illegal := '1';
                  end if;

                  if not ext_svinval and funct7 = F7_HINVAL_GVMA then
                    illegal     := '1';
                    xc_v        := '0';
                  end if;

                when others =>
                  illegal := '1';
              end case;
            end if;

          when "100" =>
            case funct7 is
              when F7_HLVB =>
                hv_op := '1';
                if rfa2 = "00000" or rfa2 = "00001" then
                  hv_valid := '1';
                end if;

              when F7_HLVH =>
                hv_op := '1';
                if rfa2 = "00000" or rfa2 = "00001" or rfa2 = "00011" then
                  hv_valid := '1';
                end if;

              when F7_HLVW =>
                hv_op := '1';
                if rfa2 = "00000" or rfa2 = "00001" or rfa2 = "00011" then
                  hv_valid := '1';
                end if;

              when F7_HLVD =>
                hv_op := '1';
                if rfa2 = "00000" then
                  hv_valid := '1';
                end if;

              when F7_HSVB | F7_HSVH | F7_HSVW | F7_HSVD =>
                hv_op := '1';
                if rd = "00000" then
                  hv_valid := '1';
                end if;

              when F7_MOPR_0  | F7_MOPR_4  | F7_MOPR_8  | F7_MOPR_12 |
                   F7_MOPR_16 | F7_MOPR_20 | F7_MOPR_24 | F7_MOPR_28  =>
                -- MOPR is really 1-00--0 111--
                if rfa2(4 downto 2) = "111" then
                  zimop_op := '1';
                else
                  illegal := '1';
                end if;

              when F7_MOPRR_0 | F7_MOPRR_1 | F7_MOPRR_2 | F7_MOPRR_3 |
                   F7_MOPRR_4 | F7_MOPRR_5 | F7_MOPRR_6 | F7_MOPRR_7  =>
                zimop_op := '1';

              when others =>
                illegal := '1';
            end case;
            if h_en and hv_op = '1' then
              if hv_valid = '1' then
                if v_in = '0' then
                  if prv_in = PRIV_LVL_U and hu = '0' then
                    illegal := '1';
                  end if;
                else
                  illegal := '1';
                  xc_v := '1';
                end if;
              else
                illegal := '1';
              end if;
            elsif ext_zimop and zimop_op = '1' then
              -- OK!
            else
              illegal := '1';
            end if;

          when I_CSRRS | I_CSRRC | I_CSRRSI | I_CSRRCI =>
          when others =>
            -- CSR accesses always OK
        end case;

      when OP_AMO =>
        if ext_a then
          if funct3 = R_WORD or funct3 = R_DOUBLE then
            case funct5 is
              when R_LR =>
                if not all_0(rfa2) then
                  illegal := '1';
                end if;
              when R_SC     | R_AMOSWAP | R_AMOADD |
                   R_AMOXOR | R_AMOAND | R_AMOOR   |
                   R_AMOMIN | R_AMOMAX | R_AMOMINU | R_AMOMAXU => null;
              when R_SSAMOSWAP =>
                xc_tmp := require_envcfg(mode_s, prv_in, v_in, menvcfg.sse, henvcfg.sse, senvcfg.sse);
                if not ext_zicfiss or xc_tmp = XC_ILLEGAL then
                  illegal := '1';
                elsif xc_tmp = XC_VIRT then
                  illegal := '1';
                  xc_v    := '1';
                end if;
              when others =>
                illegal := '1';
            end case;
          else
            illegal := '1';
          end if;
        else
          illegal   := '1';
        end if;
        if is_rv32 and funct3 = R_DOUBLE then
          illegal := '1';
        end if;

      when OP_LOAD_FP | OP_STORE_FP |
           OP_FMADD   | OP_FMSUB    | OP_FNMSUB | OP_FNMADD |
           OP_FP =>
        illegal := not to_bit(fpu_en and fpu_ok);

      when OP_CUSTOM0 =>
        case funct7 is
          when F7_BASE => -- Custom diagnostic instructions
            -- rv32: support 32-bit access
            -- rv64: support 32 and 64-bit access
            if (is_rv32 and funct3(1 downto 0) /= "10") or
               (is_rv64 and (funct3(1 downto 0) /= "10" and funct3(1 downto 0) /= "11")) then
              illegal := '1';
            end if;
            if not ext_noelv or not x_en then
              illegal := '1';
            end if;
            if get_hi(funct3) = '0' then
              diag_inst := inst_in(23 downto 20);  -- Diagnostic load (rs2)
              if inst_in(24) = '1' then
                illegal := '1';
              end if;
            else
              diag_inst := inst_in(10 downto 7);   --   or store      (rd)
              if inst_in(11) = '1' then
                illegal := '1';
              end if;
            end if;
            -- Check legality of specific diagnostic possibilities
            if diag_legal(u2i(diag_inst)) = '0' then
              illegal := '1';
            end if;
            -- All diagnostic instructions have zeroed high bits
            if not all_0(inst_in(31 downto 25)) then
              illegal := '1';
            end if;
            -- Possibly allow diagnostic load/store pmp/xtnd from S mode.
            if prv_in = PRIV_LVL_U or
               (prv_in = PRIV_LVL_S and not (diag_s and (diag_inst = x"c" or diag_inst = x"d"))) then
              illegal := '1';
            end if;
          when F7_BASE_RV64 => -- Custom ALU instructions
            illegal := not to_bit(alu_ok and x_en);
          when others =>
            illegal := '1';
        end case;

      when others =>
        illegal := '1';
    end case; -- opcode

    -- All the possible faults here (ILLEGAL/VIRTUAL/EBREAK/ECALL)
    -- have the same priority (and only one is possible, anyway).

    -- Exception generation
    xc        := '0';
    tval      := to0x(inst_in);

    if comp_ill = '1' or (illegal = '1' and comp = '1') then
      -- Illegal compressed instruction
      tval    := to0x(cinst_in);
      illegal := '1';
    end if;

    if tval_ill0 then
      tval    := zerox;
    end if;

    if illegal = '1' then
      xc      := '1';
      cause   := XC_INST_ILLEGAL_INST;
    end if;

    if xc_v = '1' then
      cause   := XC_INST_VIRTUAL_INST;
    end if;

    if ebreak = '1' then
      xc      := '1';
      tval    := pc2xlen(pc_in);
      cause   := XC_INST_BREAKPOINT;
    end if;

    if ecall = '1' then
      xc      := '1';
      tval    := (others => '0');
      case prv is
        when PRIV_LVL_M => cause := XC_INST_ENV_CALL_MMODE;
        when PRIV_LVL_S => cause := XC_INST_ENV_CALL_SMODE;
        when PRIV_LVL_U => cause := XC_INST_ENV_CALL_UMODE;
        when others => null;
      end case;
      -- H-ext: Environment call from VS-mode
      if v_in = '1' and prv = PRIV_LVL_S then
        cause := XC_INST_ENV_CALL_VSMODE;
      end if;
    end if;

    cause_out := cause;
    xc_out    := xc;
    tval_out  := tval;
  end;

  -- Fetch pmpcfg data
  function pmpcfg(pmp_entries : integer range pmpcfg_vec_type'range;
                  cfg : pmpcfg_vec_type; n : natural;
                  start : integer; bits : integer
                  ) return std_logic_vector is
    -- Non-constant
    variable data : word8 := (others => '0');
  begin
    if n < pmp_entries then
      data := cfg(n);
    end if;

    return get(data, start, bits);
  end;

  function pmpcfg(pmp_entries : integer range pmpcfg_vec_type'range;
                  cfg : pmpcfg_vec_type; n : natural; bit : integer
                  ) return std_logic is
    variable data : word8 := pmpcfg(pmp_entries, cfg, n, 0, 8);
  begin
    return data(bit);
  end;

  function pmpcfg(cfg : pmpcfg_vec_type; first : integer; last : integer) return wordx is
    -- Non-constant
    variable res : wordx := zerox;
  begin
    for i in first to last loop
      res((i - first) * 8 + 7 downto (i - first) * 8) := cfg(i);
    end loop;

    return res;
  end;


  -- Interrupt code priority

  -- This table is defined by the AIA standard.
  -- AIA says that the following have also been proposed:
  -- 23 Bus or system error
  -- 45 Per-core high-power or over-temperature event
  -- 17 Debug/trace interrupt
  -- Priority for custom interrupts have to be inserted (and documented) manually!
  -- The 16-23 and 32-47 ranges have been interleaved in a way that makes 0-31
  -- an adquate subset. Note, however, that RAS interrupts are allocated higher up.
  constant cause_prio : cause_arr(0 to 34) := (
    to_cause(47, true),                     to_cause(23, true),  -- Current plan, according to AIA
    to_cause(46, true), to_cause(45, true), to_cause(22, true),  -- Current plan, according to AIA
    to_cause(44, true),                                          -- Current plan, according to AIA
    CAUSE_IRQ_RAS_HIGH_PRIO,
                                            to_cause(21, true),  -- Current plan, according to AIA
    to_cause(42, true), to_cause(41, true), to_cause(20, true),  -- Current plan, according to AIA
    to_cause(40, true),                                          -- Current plan, according to AIA
    CAUSE_IRQ_M_EXTERNAL,  CAUSE_IRQ_M_SOFTWARE,  CAUSE_IRQ_M_TIMER,
    CAUSE_IRQ_S_EXTERNAL,  CAUSE_IRQ_S_SOFTWARE,  CAUSE_IRQ_S_TIMER,
    CAUSE_IRQ_SG_EXTERNAL,
    CAUSE_IRQ_VS_EXTERNAL, CAUSE_IRQ_VS_SOFTWARE, CAUSE_IRQ_VS_TIMER,
    CAUSE_IRQ_LCOF,
    to_cause(39, true),                     to_cause(19, true),  -- Current plan, according to AIA
    to_cause(38, true), to_cause(37, true), to_cause(18, true),  -- Current plan, according to AIA
    to_cause(36, true),                                          -- Current plan, according to AIA
    CAUSE_IRQ_RAS_LOW_PRIO,
                                            to_cause(17, true),  -- Current plan, according to AIA
    to_cause(34, true), to_cause(33, true), to_cause(16, true),  -- Current plan, according to AIA
    to_cause(32, true)                                           -- Current plan, according to AIA
  );

  -- According to the standard
  constant cause_prio_m : cause_arr(0 to 7) := (
    CAUSE_IRQ_M_EXTERNAL,  CAUSE_IRQ_M_SOFTWARE,  CAUSE_IRQ_M_TIMER,
    CAUSE_IRQ_S_EXTERNAL,  CAUSE_IRQ_S_SOFTWARE,  CAUSE_IRQ_S_TIMER,
    CAUSE_IRQ_LCOF,
    CAUSE_IRQ_UNUSED
  );
  -- According to the standard, except that it does not say anything about IRQ_LCOF.
  -- It seems reasonable to have it before IRQ_SG_EXTERNAL, but as can be see in
  -- cause_prio above, that is perhaps not correct.
  constant cause_prio_s : cause_arr(0 to 7) := (
    CAUSE_IRQ_S_EXTERNAL,  CAUSE_IRQ_S_SOFTWARE,  CAUSE_IRQ_S_TIMER,
    CAUSE_IRQ_SG_EXTERNAL,
    CAUSE_IRQ_VS_EXTERNAL, CAUSE_IRQ_VS_SOFTWARE, CAUSE_IRQ_VS_TIMER,
    CAUSE_IRQ_LCOF
  );
  -- According to the standard
  constant cause_prio_v : cause_arr(0 to 7) := (
    CAUSE_IRQ_VS_EXTERNAL, CAUSE_IRQ_VS_SOFTWARE, CAUSE_IRQ_VS_TIMER,
    CAUSE_IRQ_LCOF,
    CAUSE_IRQ_UNUSED, CAUSE_IRQ_UNUSED, CAUSE_IRQ_UNUSED, CAUSE_IRQ_UNUSED
  );

  -- Initializes a vector where the index represents the interrupt cause
  -- and its value the default priority.
  function set_cause2prio(length : integer) return int_cause_arr is
    -- Non-constant
    variable reset_val : int_cause_type := int_cause_type'high;
    variable vec : int_cause_arr(0 to length - 1) := (others => reset_val);
  begin
    for i in vec'range loop
      if i < cause_prio'length then
        vec(cause2int(cause_prio(i))) := i;
      end if;
    end loop;

    return vec;
  end;

  constant int_cause2prio : int_cause_arr(0 to 63) := set_cause2prio(64);


  -- Create full-size value from (V)S/MISELECT
  function selector2wordx(v : select_t) return wordx is
    -- Non-constant
    variable ret : wordx := zerox;
  begin
    ret(ret'high)    := v.custom;
    ret(v.sel'range) := std_logic_vector(v.sel);

    return ret;
  end;

  -- Create (V)S/MISELECT selector from full-size value
  function wordx2selector(v : wordx) return select_t is
    -- Non-constant
    variable ret : select_t;
  begin
    ret.custom := get_hi(v);
    ret.sel    := get_lo(v, ret.sel'length);

    return ret;
  end;

  function is_custom(v : select_t) return boolean is
  begin
    return v.custom = '1';
  end;

  function is_imsic(v : select_t) return boolean is
    variable sel : integer := u2i(v.sel);
  begin
    return not is_custom(v) and sel >= CSRIND_IMSIC_LOW and sel <= CSRIND_IMSIC_HIGH;
  end;

  function is_smcdeleg(v : select_t) return boolean is
    variable sel : integer := u2i(v.sel);
  begin
    return not is_custom(v) and sel >= CSRIND_SMCDELEG_LOW and sel <= CSRIND_SMCDELEG_HIGH;
  end;

  function is_aia_iprio(v : select_t) return boolean is
    variable sel : integer := u2i(v.sel);
  begin
    return not is_custom(v) and sel >= CSRIND_SMAIA_IPRIO_LOW and sel <= CSRIND_SMAIA_IPRIO_HIGH;
  end;


  function vgein_legal(vgein : integer) return boolean is
  begin
    return not (vgein = 0 or vgein > GEILEN);
  end function;

  -- Determines when the accessed address of the interrupt file is illegal and an exception must be raised
  -- Assumes sel.custom is '0'.
  function intFile_addrExcp(sel : select_t; imsic : integer; is_rv64 : boolean) return std_logic is
  begin
    -- Raise illegal instruction exception when:
    -- * XLEN=64 and trying to access IMSIC odd registers
    -- * XLEN=64 and trying to access major interrupt priorities odd registers
    -- * IMSIC is not implemented and trying to access IMSIC registers
    if (is_rv64 and sel.sel(0) = '1')  or    -- XLEN = 64 and access odd register
       (imsic = 0 and                        -- IMSIC not implemented and access IMSIC regisers
        u2i(sel.sel(7 downto 4)) > 6) then
      return '1';
    else
      return '0';
    end if;
  end;

  function to_floating(fpulen : integer; set : integer) return integer is
    -- Non-constant
    variable ret : integer := 0;
  begin
    -- FPU length implies lower ones too.
    if fpulen >= set then
      ret := 1;
    end if;

    return ret;
  end;




  -- These two only occurs together with mtval2/htval!
  function tinst_vs_pt_read return word is
  begin
    if XLEN = 64 then
      return x"00003000";
    end if;

    return x"00002000";
  end;

  function tinst_vs_pt_write return word is
  begin
    if XLEN = 64 then
      return x"00003020";
    end if;

    return x"00002020";
  end;

  -- Return mask for mie
  function medeleg_mask(h_en : boolean) return wordx is
    -- Non-constant
    variable mask    : wordx := CSR_MEDELEG_MASK;
  begin
    if h_en then
      mask(10) := '1';
      mask(20) := '1';
      mask(21) := '1';
      mask(22) := '1';
      mask(23) := '1';
    end if;

    return mask;
  end;

  -- Return masked mideleg value
  function to_mideleg(
    wcsr         : wordx;
    mode_s       : boolean;
    h_en         : boolean;
    ext_sscofpmf : boolean) return wordx is
    -- Non-constant
    variable mideleg : wordx := zerox;
    variable mask    : wordx := zerox;
  begin
    if mode_s then
      if ext_sscofpmf then
        mask(IRQ_LCOF) := '1';
      end if;
      mask := mask or CSR_MIDELEG_MASK;
    end if;

    mideleg := wcsr and mask;

    -- VS-level interrupts are always delegeted to HS-mode
    if h_en then
      mideleg := mideleg or CSR_HIE_MASK;
    end if;

    return mideleg;
  end;

  -- Return mask for mip
  function mip_mask(mode_s : boolean; h_en : boolean;
                    ext_sscofpmf : boolean;
                    menvcfg_stce : std_ulogic) return wordx is
    -- Non-constant
    variable mask : wordx := CSR_MIP_MASK;
  begin
    if ext_sscofpmf then
      mask(IRQ_LCOF) := '1';
    end if;
    if mode_s then
      mask := mask or CSR_SIP_MASK;
    end if;
    if h_en then
      mask := mask or CSR_HIP_MASK;
    end if;

    -- When Sstc extension is enabled STIP is read-only
    if menvcfg_stce = '1' then
      mask(5) := '0';
    end if;

    return mask;
  end;

  -- Return mask for mie
  function mie_mask(mode_s : boolean; h_en : boolean;
                    ext_sscofpmf : boolean) return wordx is
    -- Non-constant
    variable mask : wordx := CSR_MIE_MASK;
  begin
    if ext_sscofpmf then
      mask(IRQ_LCOF) := '1';
    end if;
    if mode_s then
      mask := mask or CSR_SIE_MASK;
    end if;
    if h_en then
      mask := mask or CSR_HIE_MASK;
    end if;

    return mask;
  end;

  -- Return mask for sip and sie
  function sip_sie_mask(ext_sscofpmf : boolean) return wordx is
    -- Non-constant
    variable mask : wordx := CSR_SIP_MASK;
  begin
    assert CSR_SIP_MASK = CSR_SIE_MASK report "Bad mask assumption" severity failure;
    if ext_sscofpmf then
      mask(IRQ_LCOF) := '1';
    end if;
    return mask;
  end;

  -- Return mask for hideleg
  function hideleg_mask(ext_shlcofideleg : integer) return wordx is
    -- Non-constant
    variable mask : wordx := CSR_HIDELEG_MASK;
  begin
    if ext_shlcofideleg = 1 then
      mask(IRQ_LCOF) := '1';
    end if;
    return mask;
  end;


  -- Return mask for etrigger (tdata2)
  function etrigger_mask(h_en : boolean) return wordx is
    -- Non-constant
    variable mask : wordx := CSR_ETRIGGER_MASK;
  begin
    if h_en then
      mask := mask or CSR_H_ETRIGGER_MASK;
    end if;

    return mask;
  end;


  -- Return hstatus as a XLEN bit data from the record type
  function to_hstatus(status : csr_hstatus_type) return wordx is
    -- Non-constant
    variable hstatus : word64 := zerow64;
  begin
    hstatus(33 downto 32)     := status.vsxl;
    hstatus(22 downto 20)     := status.vtsr & status.vtw & status.vtvm;
    hstatus(17 downto 12)     := status.vgein;
    hstatus( 9 downto  6)     := status.hu & status.spvp & status.spv & status.gva;
    hstatus(           5)     := status.vsbe;

    return hstatus(wordx'range);
  end;

  -- Return hstatus as a record type from an XLEN bit data
  function to_hstatus(wdata : wordx) return csr_hstatus_type is
    -- Non-constant
    variable hstatus : csr_hstatus_type;
  begin
    hstatus.vsxl  := "10";
    hstatus.vtsr  := wdata(22);
    hstatus.vtw   := wdata(21);
    hstatus.vtvm  := wdata(20);
    hstatus.vgein := wdata(17 downto 12);
    --hstatus.vgein := (others => '0');
    hstatus.hu    := wdata(9);
    hstatus.spvp  := wdata(8);
    hstatus.spv   := wdata(7);
    hstatus.gva   := wdata(6);
    --hstatus.vsbe  := wdata(5);
    hstatus.vsbe  := '0';

    return hstatus;
  end;

  -- Return vsstatus as a XLEN bit data from the record type
  function to_vsstatus(status      : csr_status_type;
                       ssdbltrp_en : std_ulogic;
                       bcfi_en     : std_ulogic;
                       fcfi_en     : std_ulogic
                       ) return wordx is
    -- Non-constant
    variable vsstatus : word64 := zerow64;
  begin
    vsstatus(XLEN-1)         := (status.fs(1) and status.fs(0)) or (status.xs(1) and status.xs(0));
    if XLEN = 64 then
      vsstatus(33 downto 32) := status.uxl;
    end if;
    if fcfi_en = '1' then
      vsstatus(23)           := status.spelp;
    end if;
    if ssdbltrp_en = '1' then
      vsstatus(24)             := status.sdt;
    end if;
    vsstatus(19 downto 18)   := status.mxr & status.sum;
    vsstatus(16 downto 13)   := "00" & status.fs;
    vsstatus(           8)   := status.spp;
    vsstatus(6 downto   5)   := '0' & status.spie;
    vsstatus(           1)   := status.sie;

    return vsstatus(wordx'range);
  end;

  -- Return vsstatus as a record type from an XLEN bit data
  function to_vsstatus(wdata       : wordx;
                       vsstatus_in : csr_status_type;
                       ssdbltrp_en : std_ulogic;
                       bcfi_en     : std_ulogic;
                       fcfi_en     : std_ulogic
                      ) return csr_status_type is
    -- Non-constant
    variable vsstatus : csr_status_type := vsstatus_in;
  begin

    vsstatus.uxl    := "10";
    if fcfi_en = '1' then
      vsstatus.spelp  := wdata(23);
    else
      vsstatus.spelp  := '0';
    end if;
    if ssdbltrp_en = '1' then
      vsstatus.sdt    := wdata(24);
    end if;
    vsstatus.mxr    := wdata(19);
    vsstatus.sum    := wdata(18);
    vsstatus.xs     := "00";
    vsstatus.fs     := wdata(14 downto 13);
    vsstatus.spp    := wdata(8);
    vsstatus.ube    := '0';
    vsstatus.spie   := wdata(5);
    vsstatus.sie    := wdata(1);


    -- When the SDT bit is set to 1 by an explicit CSR write,
    -- the SIE (Supervisor Interrupt Enable) bit is cleared to 0.
    --if ext_ssdbltrp then
    if ssdbltrp_en = '1' then
      if wdata(24) = '1' then
        vsstatus.sie := '0';
      end if;
    end if;
    return vsstatus;
  end;

  -- Return mstatus as an XLEN bit data from the record type
  function to_mstatus(status : csr_status_type) return wordx is
    -- Non-constant
    variable mstatus : word64 := zerow64;
  begin
    -- List of Hardwired Fields
    -- * SXL    -> 10 (The SXL field of mstatus determines XLEN for HS-mode)
    -- * UXL    -> 10 (The UXL field of the HS-level sstatus determines XLEN for both VS-mode and U-mode)
    -- * XS     -> 00 (User Extensions Missing)
    -- * MBE    -> 0
    -- * SBE    -> 0
    -- * UBE    -> 0

    mstatus(XLEN-1)         := (status.fs(1) and status.fs(0)) or (status.xs(1) and status.xs(0));
    if XLEN = 64 then
      mstatus(42)           := status.mdt;
      mstatus(39 downto 38) := status.mpv & status.gva;
      mstatus(35 downto 32) := status.sxl & status.uxl;
    end if;
    mstatus(41)             := status.mpelp;
    mstatus(23)             := status.spelp;
    mstatus(24)             := status.sdt;
    mstatus(22 downto 20)   := status.tsr & status.tw & status.tvm;
    mstatus(19 downto 17)   := status.mxr & status.sum & status.mprv;
    mstatus(16 downto 11)   := "00" & status.fs & status.mpp;
    mstatus(8 downto 7)     := status.spp & status.mpie;
    mstatus(5 downto 3)     := status.spie & status.upie  & status.mie;
    mstatus(1 downto 0)     := status.sie & status.uie;

    return mstatus(wordx'range);
  end;

  -- Return mstatus as a record type from an XLEN bit data
  function to_mstatus(wdata        : wordx;
                      mstatus_in   : csr_status_type;
                      smdbltrp_en  : std_ulogic;
                      ssdbltrp_en  : std_ulogic) return csr_status_type is
    -- Non-constant
    variable mstatus : csr_status_type := mstatus_in;
  begin

    if XLEN = 64 then
      mstatus.mdt   := wdata(42 * (XLEN / 64));
      mstatus.mpv  := wdata(39 * (XLEN / 64));
      mstatus.gva  := wdata(38 * (XLEN / 64));
    end if;
    mstatus.mbe    := '0';
    mstatus.sbe    := '0';
    mstatus.sxl    := "10";
    mstatus.uxl    := "10";
    mstatus.mpelp  := wdata(41 * (XLEN / 64));
    mstatus.spelp  := wdata(23);
    if ssdbltrp_en = '1' then
      mstatus.sdt    := wdata(24);
    end if;
    mstatus.tsr    := wdata(22);
    mstatus.tw     := wdata(21);
    mstatus.tvm    := wdata(20);
    mstatus.mxr    := wdata(19);
    mstatus.sum    := wdata(18);
    mstatus.mprv   := wdata(17);
    mstatus.xs     := "00";
    mstatus.fs     := wdata(14 downto 13);
    mstatus.mpp    := wdata(12 downto 11);
    mstatus.spp    := wdata(8);
    mstatus.mpie   := wdata(7);
    mstatus.ube    := '0';
    mstatus.spie   := wdata(5);
    mstatus.upie   := wdata(4);
    mstatus.mie    := wdata(3);
    mstatus.sie    := wdata(1);
    mstatus.uie    := wdata(0);

    -- When the SDT bit is set to 1 by an explicit CSR write,
    -- the SIE (Supervisor Interrupt Enable) bit is cleared to 0.
    if ssdbltrp_en = '1' then
      if wdata(24) = '1' then
        mstatus.sie := '0';
      end if;
    end if;
    -- When the MDT bit is set to 1 by an explicit CSR write,
    -- the MIE (Machine Interrupt Enable) bit is cleared to 0.
    if smdbltrp_en = '1' then
      if (XLEN = 64 and wdata(42 * (XLEN / 64)) = '1') or
         (XLEN = 32 and mstatus_in.mdt = '1') then
        mstatus.mie := '0';
      end if;
    end if;

    return mstatus;
  end;

  -- Return mstatush as an XLEN bit data from the record type
  function to_mstatush(status : csr_status_type) return wordx is
    -- Non-constant
    variable mstatus : word64 := zerow64;
  begin
    mstatus(10)         := status.mdt;
    mstatus(9)          := status.mpelp;
    mstatus(7 downto 6) := status.mpv & status.gva;

    return mstatus(wordx'range);
  end;

  -- Return mstatush as a record type from an XLEN bit data
  function to_mstatush(wdata       : wordx;
                       mstatus_in  : csr_status_type;
                       h_en        : boolean;
                       smdbltrp_en : std_ulogic) return csr_status_type is
    -- Non-constant
    variable mstatus : csr_status_type := mstatus_in;
  begin

    if smdbltrp_en = '1' then
      mstatus.mdt := wdata(10);
    end if;

    mstatus.mpelp := wdata(9);

    if h_en then
      mstatus.mpv := wdata(7);
      mstatus.gva := wdata(6);
    end if;

    -- When the MDT bit is set to 1 by an explicit CSR write,
    -- the MIE (Machine Interrupt Enable) bit is cleared to 0.
    if smdbltrp_en = '1' then
      if wdata(10) = '1' then
        mstatus.mie := '0';
      end if;
    end if;

    return mstatus;
  end;

  -- Return sstatus as an XLEN bit data from the record type
  function to_sstatus(status  : csr_status_type;
                      bcfi_en : std_ulogic;
                      fcfi_en : std_ulogic;
                      dte     : std_ulogic
                     ) return wordx is
    -- Non-constant
    variable sstatus : word64 := zerow64;
  begin
    sstatus(XLEN-1)         := (status.fs(1) and status.fs(0)) or (status.xs(1) and status.xs(0));
    if XLEN = 64 then
      sstatus(33 downto 32) := status.uxl;
    end if;
    sstatus(24)             := status.sdt and dte;
    if fcfi_en = '1' then
      sstatus(23)           := status.spelp;
    end if;
    sstatus(19 downto 18)   := status.mxr & status.sum;
    sstatus(16 downto 13)   := "00" & status.fs;
    sstatus(8)              := status.spp;
    sstatus(5 downto 4)     := status.spie & status.upie;
    sstatus(1 downto 0)     := status.sie & status.uie;

    return sstatus(wordx'range);
  end;

  -- Return sstatus as a record type from an XLEN bit data
  function to_sstatus(wdata       : wordx;
                      mstatus     : csr_status_type;
                      ssdbltrp_en : std_ulogic;
                      bcfi_en     : std_ulogic;
                      fcfi_en     : std_ulogic
                     ) return csr_status_type is
    -- Non-constant
    variable sstatus : csr_status_type;
  begin

    -- Keep the values for the mstatus fields
    sstatus         := mstatus;

    sstatus.uxl     := "10";
    if ssdbltrp_en = '1' then
      sstatus.sdt     := wdata(24);
    end if;
    if fcfi_en = '1' then
      sstatus.spelp := wdata(23);
    end if;
    sstatus.mxr     := wdata(19);
    sstatus.sum     := wdata(18);
    sstatus.xs      := "00";
    sstatus.fs      := wdata(14 downto 13);
    sstatus.spp     := wdata(8);
    sstatus.spie    := wdata(5);
    sstatus.upie    := wdata(4);
    sstatus.sie     := wdata(1);
    sstatus.uie     := wdata(0);

    -- When the SDT bit is set to 1 by an explicit CSR write,
    -- the SIE (Supervisor Interrupt Enable) bit is cleared to 0.
    if ssdbltrp_en = '1' then
      if wdata(24) = '1' then
        sstatus.sie := '0';
      end if;
    end if;

    return sstatus;
  end;

  -- Return ustatus as an XLEN bit data from the record type
  function to_ustatus(status : csr_status_type) return wordx is
    -- Non-constant
    variable ustatus : wordx;
  begin
    ustatus := (others => '0');

    ustatus(4)            := status.upie;
    ustatus(0)            := status.uie;

    return ustatus;
  end;

  -- Return ustatus as a record type from an XLEN bit data
  function to_ustatus(wdata   : wordx;
                      mstatus : csr_status_type) return csr_status_type is
    -- Non-constant
    variable ustatus : csr_status_type;
  begin

    -- Keep the values for the mstatus fields
    ustatus      := mstatus;

    ustatus.upie := wdata(4);
    ustatus.uie  := wdata(0);

    return ustatus;
  end;

  function to_mnstatus(mnstatus : csr_mnstatus_type) return wordx is
    variable xmnstatus : wordx := zerox;
  begin
    xmnstatus(12 downto 11) := mnstatus.mnpp;
    xmnstatus(9)            := mnstatus.mnpelp;
    xmnstatus(7)            := mnstatus.mnpv;
    xmnstatus(3)            := mnstatus.nmie;

    return xmnstatus;
  end;

  function to_mnstatus(wdata    : wordx;
                       mnstatus : csr_mnstatus_type;
                       active   : extension_type;
                       misa     : wordx) return csr_mnstatus_type is
    variable h_en      : boolean   := misa(h_ctrl) = '1';
    variable mode_u    : boolean   := is_enabled(active, x_mode_u);
    variable mode_s    : boolean   := is_enabled(active, x_mode_s);
    variable mnpp_in   : word2     := wdata(12 downto 11);
    -- Non-constant
    variable xmnstatus : csr_mnstatus_type;
  begin
    xmnstatus.mnpp   := mnpp_in;
    xmnstatus.mnpelp := wdata(9);
    xmnstatus.mnpv   := wdata(7);
    xmnstatus.nmie   := mnstatus.nmie or wdata(3);

    if not h_en then
      xmnstatus.mnpv  := '0';
    end if;

    -- Unsupported privilege mode - default to user-mode.
    if mnpp_in = "10" or (not mode_s and mnpp_in = "01") or (not mode_u and mnpp_in = "00") then
      if mode_u then
        xmnstatus.mnpp  := "00";
      else
        xmnstatus.mnpp  := "11";
      end if;
    end if;

    return xmnstatus;
  end;

  -- Convert XLEN bit data into hvictl csr type
  function to_hvictl(wdata : wordx) return csr_hvictl_type is
    variable xhvictl : csr_hvictl_type;
  begin
    xhvictl.vti    := wdata(30);
    -- AIA RC2 changed so that .iid shall support any number (of its length).
    xhvictl.iid    := u2i(get_lo(wdata(27 downto 16), CAUSELEN));
    xhvictl.dpr    := wdata(9);
    xhvictl.ipriom := wdata(8);
    xhvictl.iprio  := wdata(7 downto 0);

    return xhvictl;
  end;

  -- Return hvictl as an XLEN bit data from the record type
  function to_hvictl(hvictl : csr_hvictl_type) return wordx is
    variable xhvictl : wordx;
  begin
    xhvictl := (others => '0');
    xhvictl(30)           := hvictl.vti;
    xhvictl(27 downto 16) := u2vec(hvictl.iid, 12);
    xhvictl(8)            := hvictl.ipriom;
    xhvictl(7 downto 0)   := hvictl.iprio;

    return xhvictl;
  end function;

  -- Return mvien mask
  function mvien_mask(ext_sscofpmf  : integer; 
                      ext_smcdeleg  : integer) return wordx is
    variable mask : wordx := CSR_MVIEN_MASK;
  begin
    if ext_sscofpmf /= 0 and ext_smcdeleg /= 0 then
      mask(IRQ_LCOF) := '1';
    end if;
    return mask;
  end;

  function hvien_mask(ext_sscofpmf  : integer; 
                      ext_smcdeleg  : integer) return wordx is
    variable mask : wordx := (others => '0');
  begin
    if ext_sscofpmf /= 0 and ext_smcdeleg /= 0 then
      mask(IRQ_LCOF) := '1';
    end if;
    return mask;
  end;

  function to_mvip(mip : wordx; mvip : wordx;
                   mvien : wordx; ext_sstc : integer;
                   menvcfg_stce : std_ulogic) return wordx is
    variable xmvip : wordx := zerox;
  begin
    -- When bit 1 of mvien is zero, bit 1 of mvip is an alias of the
    -- same bit (SSIP) of mip. But when bit 1 of mvien is one, bit 1
    -- of mvip is a separate writable bit independent of mip.SSIP.
    if mvien(IRQ_S_SOFTWARE) = '1' then
      xmvip(IRQ_S_SOFTWARE) := mvip(IRQ_S_SOFTWARE);
    else
      xmvip(IRQ_S_SOFTWARE) := mip(IRQ_S_SOFTWARE);
    end if;
    -- Bit 5 of mvip is an alias of the same bit (STIP) in mip when
    -- that bit is writable in mip. When STIP is not writable in
    -- mip(such as when menvcfg.STCE = 1), bit 5 of mvip is read-only zero.
    if ext_sstc /= 0 and menvcfg_stce = '1' then
      xmvip(IRQ_S_TIMER) := '0';
    else
      xmvip(IRQ_S_TIMER) := mip(IRQ_S_TIMER);
    end if;
    -- When bit 9 of mvien is zero, bit 9 of mvip is an alias of the
    -- software-writable bit 9 of mip (SEIP). But when bit 9 of mvien
    -- is one, bit 9 of mvip is a writable bit independent of mip.SEIP.
    if mvien(IRQ_S_EXTERNAL) = '1' then
      xmvip(IRQ_S_EXTERNAL) := mvip(IRQ_S_EXTERNAL);
    else
      xmvip(IRQ_S_EXTERNAL) := mip(IRQ_S_EXTERNAL);
    end if;

    -- So far only LCOF interrupt is defined in interrupts from 13 to 63. To add new interrupt
    -- inside this range, mvien_mask has to be modified
    xmvip(XLEN-1 downto 13) := mvip(XLEN-1 downto 13);
    return xmvip;
  end;

  function "and" (L : csr_mstateen0_type; R : csr_mstateen0_type) return csr_mstateen0_type is
  begin
    -- Do this type of return to be able to detect if a type has changed and not the overload
    return csr_mstateen0_type'(
      stateen  => L.stateen and R.stateen,
      envcfg   => L.envcfg  and R.envcfg,
      iselect  => L.iselect and R.iselect,
      aia      => L.aia     and R.aia,
      imsic    => L.imsic   and R.imsic,
      ctx      => L.ctx     and R.ctx,
      p1p13    => L.p1p13   and R.p1p13,
      p1p14    => L.p1p14   and R.p1p14,
      ctr      => L.ctr     and R.ctr,
      jvt      => L.jvt     and R.jvt,
      fcsr     => L.fcsr    and R.fcsr,
      c        => L.c       and R.c
    );
  end function;

  function "and" (L : csr_hstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type is
  begin
    return csr_hstateen0_type'(
      stateen  => L.stateen and R.stateen,
      envcfg   => L.envcfg  and R.envcfg,
      iselect  => L.iselect and R.iselect,
      aia      => L.aia     and R.aia,
      imsic    => L.imsic   and R.imsic,
      ctx      => L.ctx     and R.ctx,
      ctr      => L.ctr     and R.ctr,
      jvt      => L.jvt     and R.jvt,
      fcsr     => L.fcsr    and R.fcsr,
      c        => L.c       and R.c
    );
  end function;

  function "and" (L : csr_hstateen0_type; R : csr_mstateen0_type) return csr_hstateen0_type is
  begin
    return csr_hstateen0_type'(
      stateen  => L.stateen and R.stateen,
      envcfg   => L.envcfg  and R.envcfg,
      iselect  => L.iselect and R.iselect,
      aia      => L.aia     and R.aia,
      imsic    => L.imsic   and R.imsic,
      ctx      => L.ctx     and R.ctx,
      ctr      => L.ctr     and R.ctr,
      jvt      => L.jvt     and R.jvt,
      fcsr     => L.fcsr    and R.fcsr,
      c        => L.c       and R.c
    );
  end function;

  function "and" (L : csr_mstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type is
  begin
    return R and L;
  end function;

  function "and" (L : csr_sstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type is
  begin
    return csr_sstateen0_type'(
      jvt  => L.jvt  and R.jvt,
      fcsr => L.fcsr and R.fcsr,
      c    => L.c    and R.c
    );
  end function;

  function "and" (L : csr_sstateen0_type; R : csr_hstateen0_type) return csr_sstateen0_type is
  begin
    return csr_sstateen0_type'(
      jvt  => L.jvt  and R.jvt,
      fcsr => L.fcsr and R.fcsr,
      c    => L.c    and R.c
    );
  end function;

  function "and" (L : csr_hstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type is
  begin
    return R and L;
  end function;


  function "not" (I : csr_mstateen0_type) return csr_mstateen0_type is
  begin
    return csr_mstateen0_type'(
      stateen  => not I.stateen,
      envcfg   => not I.envcfg,
      iselect  => not I.iselect,
      aia      => not I.aia,
      imsic    => not I.imsic,
      ctx      => not I.ctx,
      p1p13    => not I.p1p13,
      p1p14    => not I.p1p14,
      ctr      => not I.ctr,
      jvt      => not I.jvt,
      fcsr     => not I.fcsr,
      c        => not I.c
    );
  end function;

  function "not" (I : csr_hstateen0_type) return csr_hstateen0_type is
  begin
    return csr_hstateen0_type'(
      stateen  => not I.stateen,
      envcfg   => not I.envcfg,
      iselect  => not I.iselect,
      aia      => not I.aia,
      imsic    => not I.imsic,
      ctx      => not I.ctx,
      ctr      => not I.ctr,
      jvt      => not I.jvt,
      fcsr     => not I.fcsr,
      c        => not I.c
    );
  end function;

  function "or"  (L : csr_mstateen0_type; R : csr_mstateen0_type) return csr_mstateen0_type is
    begin
      return csr_mstateen0_type'(
        stateen  => L.stateen or R.stateen,
        envcfg   => L.envcfg  or R.envcfg,
        iselect  => L.iselect or R.iselect,
        aia      => L.aia     or R.aia,
        imsic    => L.imsic   or R.imsic,
        ctx      => L.ctx     or R.ctx,
        p1p13    => L.p1p13   or R.p1p13,
        p1p14    => L.p1p14   or R.p1p14,
        ctr      => L.ctr     or R.ctr,
        jvt      => L.jvt     or R.jvt,
        fcsr     => L.fcsr    or R.fcsr,
        c        => L.c       or R.c
      );
  end function;

  function "or"  (L : csr_hstateen0_type; R : csr_hstateen0_type) return csr_hstateen0_type is
    begin
      return csr_hstateen0_type'(
        stateen => L.stateen or R.stateen,
        envcfg  => L.envcfg  or R.envcfg,
        iselect => L.iselect or R.iselect,
        aia     => L.aia     or R.aia,
        imsic   => L.imsic   or R.imsic,
        ctx     => L.ctx     or R.ctx,
        ctr     => L.ctr     or R.ctr,
        jvt     => L.jvt     or R.jvt,
        fcsr    => L.fcsr    or R.fcsr,
        c       => L.c       or R.c
      );
  end function;

  function "or"  (L : csr_sstateen0_type; R : csr_sstateen0_type) return csr_sstateen0_type is
    begin
    return csr_sstateen0_type'(
      jvt  => L.jvt  or R.jvt,
      fcsr => L.fcsr or R.fcsr,
      c    => L.c    or R.c
    );
  end function;

  -- For every bit in an mstateen CSR that is zero (whether read-only zero or set to zero), the same bit
  -- appears as READ-ONLY zero in the matching hstateen and sstateen CSRs.
  function stateen_wpri_write(wcsr_in   : wordx;
                              prev      : csr_hstateen0_type;
                              mask      : csr_mstateen0_type;
                              high_half : boolean) return csr_hstateen0_type is
  begin
    if high_half then
      return (prev and not mask) or (to_hstateen0h(wcsr_in, prev) and mask);
    else
      return (prev and not mask) or (to_hstateen0(wcsr_in, prev) and mask);
    end if;
  end function;

  function stateen_wpri_write(wcsr_in   : wordx;
                              prev      : csr_sstateen0_type;
                              mask      : csr_hstateen0_type;
                              high_half : boolean) return csr_sstateen0_type is
  begin
    assert not high_half report "Function assumes that no high_half exists for sstateen0";
    return (prev and not mask) or (to_sstateen0(wcsr_in) and mask);
  end function;

  function stateen_wpri_write(wcsr_in   : std_logic;
                              prev      : std_logic;
                              mask      : std_logic) return std_logic is
  begin
    return (prev and not mask) or (wcsr_in and mask);
  end function;

  -- function mstateen0_mask(mstateen0 : csr_mstateen0_type; mask : csr_mstateen0_type) return csr_mstateen0_type is
  --   variable xmstateen0 : csr_mstateen0_type;
  -- begin
  --   xmstateen0.stateen  := mstateen0.stateen  and mask.stateen;
  --   xmstateen0.envcfg   := mstateen0.envcfg   and mask.envcfg;
  --   xmstateen0.iselect  := mstateen0.iselect  and mask.iselect;
  --   xmstateen0.aia      := mstateen0.aia      and mask.aia;
  --   xmstateen0.imsic    := mstateen0.imsic    and mask.imsic;
  --   xmstateen0.ctx      := mstateen0.ctx      and mask.ctx;
  --   xmstateen0.p1p13    := mstateen0.p1p13    and mask.p1p13;
  --   xmstateen0.p1p14    := mstateen0.p1p14    and mask.p1p14;
  --   xmstateen0.ctr      := mstateen0.ctr      and mask.ctr;
  --   xmstateen0.jvt      := mstateen0.jvt      and mask.jvt;
  --   xmstateen0.fcsr     := mstateen0.fcsr     and mask.fcsr;
  --   xmstateen0.c        := mstateen0.c        and mask.c;
  --
  --   return xmstateen0;
  -- end;
  --
  -- -- hstateen0 needs its own function since p1p13/p1p14 is not present in hstateen0
  -- function hstateen0_mask(hstateen0 : csr_hstateen0_type; mask : csr_mstateen0_type) return csr_hstateen0_type is
  --   variable xmstateen0 : csr_hstateen0_type;
  -- begin
  --   xmstateen0.stateen  := hstateen0.stateen  and mask.stateen;
  --   xmstateen0.envcfg   := hstateen0.envcfg   and mask.envcfg;
  --   xmstateen0.iselect  := hstateen0.iselect  and mask.iselect;
  --   xmstateen0.aia      := hstateen0.aia      and mask.aia;
  --   xmstateen0.imsic    := hstateen0.imsic    and mask.imsic;
  --   xmstateen0.ctx      := hstateen0.ctx      and mask.ctx;
  --   xmstateen0.ctr      := hstateen0.ctr      and mask.ctr;
  --   xmstateen0.jvt      := hstateen0.jvt      and mask.jvt;
  --   xmstateen0.fcsr     := hstateen0.fcsr     and mask.fcsr;
  --   xmstateen0.c        := hstateen0.c        and mask.c;
  --
  --   return xmstateen0;
  -- end;
  --
  --
  -- function sstateen0_mask(sstateen0 : csr_sstateen0_type;
  --                         mask_m    : csr_mstateen0_type;
  --                         mask_h    : csr_hstateen0_type) return csr_sstateen0_type is
  --   variable xsstateen0 : csr_sstateen0_type := csr_sstateen0_rst;
  -- begin
  --     xsstateen0.c := sstateen0.c and mask_m.c and mask_h.c;
  --   return xsstateen0;
  -- end;
  --
  function gen_mstateen0_mask(active : extension_type) return csr_mstateen0_type is
    variable imsic    : boolean := is_enabled(active, x_imsic);
    variable ssaia    : boolean := is_enabled(active, x_ssaia);
    variable smaia    : boolean := is_enabled(active, x_smaia);
    variable smcsrind : boolean := is_enabled(active, x_smcsrind);
    variable sdtrig   : boolean := is_enabled(active, x_sdtrig);
  begin
    assert not(smaia and not smcsrind);
    assert not(imsic and not smcsrind);
    return csr_mstateen0_type'(
      stateen  => '1',
      envcfg   => '1',
      iselect  => to_bit(smcsrind),
      aia      => to_bit(ssaia) or to_bit(smaia),
      imsic    => to_bit(imsic),
      ctx      => to_bit(sdtrig),
      p1p13    => '1',
      c        => '1',
      -- Not implemented
      p1p14    => '0',
      ctr      => '0',
      jvt      => '0',
      fcsr     => '0'
      );

  end;

  -- Return mstateen0 as an XLEN bit data from the record type
  function to_mstateen0(mstateen0 : csr_mstateen0_type) return wordx is
    -- Non-constant
    variable xmstateen0 : word64 := zerow64;
  begin
    xmstateen0(63) := mstateen0.stateen;
    xmstateen0(62) := mstateen0.envcfg;
    xmstateen0(60) := mstateen0.iselect;
    xmstateen0(59) := mstateen0.aia;
    xmstateen0(58) := mstateen0.imsic;
    xmstateen0(57) := mstateen0.ctx;
    xmstateen0(56) := mstateen0.p1p13;
    xmstateen0(55) := mstateen0.p1p14;
    xmstateen0(54) := mstateen0.ctr;
    xmstateen0(2)  := mstateen0.jvt;
    xmstateen0(1)  := mstateen0.fcsr;
    xmstateen0(0)  := mstateen0.c;

    return xmstateen0(wordx'range);
  end;

  -- Return hstateen0 as an XLEN bit data from the record type
  function to_hstateen0(hstateen0 : csr_hstateen0_type) return wordx is
    -- Non-constant
    variable xmstateen0 : word64 := zerow64;
  begin
    xmstateen0(63) := hstateen0.stateen;
    xmstateen0(62) := hstateen0.envcfg;
    xmstateen0(60) := hstateen0.iselect;
    xmstateen0(59) := hstateen0.aia;
    xmstateen0(58) := hstateen0.imsic;
    xmstateen0(57) := hstateen0.ctx;
    xmstateen0(54) := hstateen0.ctr;
    xmstateen0(2)  := hstateen0.jvt;
    xmstateen0(1)  := hstateen0.fcsr;
    xmstateen0(0)  := hstateen0.c;
    return xmstateen0(wordx'range);
  end;

  -- Return sstateen0 as an XLEN bit data from the record type
  function to_sstateen0(sstateen0 : csr_sstateen0_type) return wordx is
    -- Non-constant
    variable xmstateen0 : word64 := zerow64;
    -- Check that type hasn't changed without this function being updated.
    constant dummy : csr_sstateen0_type := ('0','0','0');
  begin
    xmstateen0(0)  := sstateen0.c;
    xmstateen0(1)  := sstateen0.fcsr;
    xmstateen0(2)  := sstateen0.jvt;
    return xmstateen0(wordx'range);
  end;

  function to_sstateen0(sstateen0 : wordx) return csr_sstateen0_type is
  begin
    return csr_sstateen0_type'(
      c    => sstateen0(0),
      fcsr => sstateen0(1),
      jvt  => sstateen0(2)
    );
  end function;

  -- Return mstateen0 as a record type from an XLEN bit data
  function to_mstateen0(wdata  : wordx;
                        mstateen0 : csr_mstateen0_type) return csr_mstateen0_type is
    -- Non-constant
    variable xmstateen0 : csr_mstateen0_type := mstateen0;
    -- Check that type hasn't changed without this function being updated.
    constant dummy : csr_mstateen0_type := ('0','0','0','0','0','0','0','0','0','0','0', '0');
  begin
    if XLEN = 64 then
      xmstateen0.stateen := wdata(63 * (XLEN / 64));
      xmstateen0.envcfg  := wdata(62 * (XLEN / 64));
      xmstateen0.iselect := wdata(60 * (XLEN / 64));
      xmstateen0.aia     := wdata(59 * (XLEN / 64));
      xmstateen0.imsic   := wdata(58 * (XLEN / 64));
      xmstateen0.ctx     := wdata(57 * (XLEN / 64));
      xmstateen0.p1p13   := wdata(56 * (XLEN / 64));
      xmstateen0.p1p14   := wdata(55 * (XLEN / 64));
      xmstateen0.ctr     := wdata(54 * (XLEN / 64));
    end if;
      xmstateen0.jvt     := wdata(2);
      xmstateen0.fcsr    := wdata(1);
      xmstateen0.c       := wdata(0);

    return xmstateen0;
  end;

  -- Return hstateen0 as a record type from an XLEN bit data
  function to_hstateen0(wdata  : wordx;
                        hstateen0 : csr_hstateen0_type) return csr_hstateen0_type is
    -- Non-constant
    variable xmstateen0 : csr_hstateen0_type := hstateen0;
    -- Check that type hasn't changed without this function being updated.
    constant dummy : csr_hstateen0_type := ('0','0','0','0','0','0','0','0','0', '0');
  begin
    if XLEN = 64 then
      xmstateen0.stateen := wdata(63 * (XLEN / 64));
      xmstateen0.envcfg  := wdata(62 * (XLEN / 64));
      xmstateen0.iselect := wdata(60 * (XLEN / 64));
      xmstateen0.aia     := wdata(59 * (XLEN / 64));
      xmstateen0.imsic   := wdata(58 * (XLEN / 64));
      xmstateen0.ctx     := wdata(57 * (XLEN / 64));
      xmstateen0.ctr     := wdata(54 * (XLEN / 64));
    end if;
      xmstateen0.jvt     := wdata(2) ;
      xmstateen0.fcsr    := wdata(1) ;
      xmstateen0.c       := wdata(0) ;
    return xmstateen0;
  end;

  -- Return hstateen0h as an XLEN bit data from the record type
  function to_mstateen0h(mstateen0 : csr_mstateen0_type) return wordx is
    -- Non-constant
    variable xmstateen0h : word64 := zerow64;
  begin
    xmstateen0h(31) := mstateen0.stateen;
    xmstateen0h(30) := mstateen0.envcfg;
    xmstateen0h(28) := mstateen0.iselect;
    xmstateen0h(27) := mstateen0.aia;
    xmstateen0h(26) := mstateen0.imsic;
    xmstateen0h(25) := mstateen0.ctx;
    xmstateen0h(24) := mstateen0.p1p13;
    xmstateen0h(23) := mstateen0.p1p14;
    xmstateen0h(22) := mstateen0.ctr;

    return xmstateen0h(wordx'range);
  end;

  -- Return hstateen0h as an XLEN bit data from the record type
  function to_hstateen0h(hstateen0 : csr_hstateen0_type) return wordx is
    -- Non-constant
    variable xmstateen0h : word64 := zerow64;
  begin
    xmstateen0h(31) := hstateen0.stateen;
    xmstateen0h(30) := hstateen0.envcfg;
    xmstateen0h(28) := hstateen0.iselect;
    xmstateen0h(27) := hstateen0.aia;
    xmstateen0h(26) := hstateen0.imsic;
    xmstateen0h(25) := hstateen0.ctx;
    xmstateen0h(22) := hstateen0.ctr;

    return xmstateen0h(wordx'range);
  end;

  -- Return mstateen0h/hstateen0h as a record type from an XLEN bit data
  function to_mstateen0h(wdata     : wordx;
                         mstateen0 : csr_mstateen0_type) return csr_mstateen0_type is
    -- Non-constant
    variable xmstateen0 : csr_mstateen0_type := mstateen0;
  begin
    xmstateen0.stateen := wdata(31);
    xmstateen0.envcfg  := wdata(30);
    xmstateen0.iselect := wdata(28);
    xmstateen0.aia     := wdata(27);
    xmstateen0.imsic   := wdata(26);
    xmstateen0.ctx     := wdata(25);
    xmstateen0.p1p13   := wdata(24);
    xmstateen0.p1p14   := wdata(23);
    xmstateen0.ctr     := wdata(22);

    return xmstateen0;
  end;

  -- Return mstateen0h/hstateen0h as a record type from an XLEN bit data
  function to_hstateen0h(wdata     : wordx;
                         hstateen0 : csr_hstateen0_type) return csr_hstateen0_type is
    -- Non-constant
    variable xmstateen0 : csr_hstateen0_type := hstateen0;
  begin
    xmstateen0.stateen := wdata(31);
    xmstateen0.envcfg  := wdata(30);
    xmstateen0.iselect := wdata(28);
    xmstateen0.aia     := wdata(27);
    xmstateen0.imsic   := wdata(26);
    xmstateen0.ctx     := wdata(25);
    xmstateen0.ctr     := wdata(22);

    return xmstateen0;
  end;

  -- Return the proper number of hcontext bits depending on the XLEN
  function to_mhcontext(wdata : wordx; h_en : boolean) return csr_mhcontext_type is
    variable xhcontext : csr_mhcontext_type := (others => '0');
  begin
    if XLEN = 64 then
      if h_en then
        xhcontext := wdata(13 downto 0);
      else
        xhcontext(12 downto 0) := wdata(12 downto 0);
      end if;
    else
      if h_en then
        xhcontext(6 downto 0) := wdata(6 downto 0);
      else
        xhcontext(5 downto 0) := wdata(5 downto 0);
      end if;
    end if;
    return xhcontext;
  end;

  -- Return the proper number of scontext bits depending on the XLEN
  function to_scontext(wdata : wordx) return csr_scontext_type is
    variable xscontext : csr_scontext_type := (others => '0');
    constant X64       : integer := b2i(XLEN = 64);
  begin
    if XLEN = 64 then
      xscontext(xscontext'left*X64 downto 0) := wdata(33*X64 downto 0);
    else
      xscontext(15 downto 0) := wdata(15 downto 0);
    end if;
    return xscontext;
  end;

  function envcfg_mask(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return csr_envcfg_type is
  begin
    return csr_envcfg_type'(
      stce   => envcfg.stce   and mask.stce,
      pbmte  => envcfg.pbmte  and mask.pbmte,
      dte    => envcfg.dte    and mask.dte,
      cbze   => envcfg.cbze   and mask.cbze,
      cbcfe  => envcfg.cbcfe  and mask.cbcfe,
      cbie   => envcfg.cbie   and (mask.cbie'range => orv(mask.cbie)),
      fiom   => envcfg.fiom   and mask.fiom,
      adue   => envcfg.adue   and mask.adue,
      sse    => envcfg.sse    and mask.sse,
      lpe    => envcfg.lpe    and mask.lpe,
      cde    => envcfg.cde    and mask.cde
    );

  end;

  function "and"(L : csr_envcfg_type; R : csr_envcfg_type) return csr_envcfg_type is
  begin
    return csr_envcfg_type'(
      stce   => L.stce   and R.stce,
      pbmte  => L.pbmte  and R.pbmte,
      dte    => L.dte    and R.dte,
      cbze   => L.cbze   and R.cbze,
      cbcfe  => L.cbcfe  and R.cbcfe,
      cbie   => L.cbie   and R.cbie,
      fiom   => L.fiom   and R.fiom,
      adue   => L.adue   and R.adue,
      sse    => L.sse    and R.sse,
      lpe    => L.lpe    and R.lpe,
      cde    => L.cde    and R.cde
    );

  end;

  -- Return envcfg as an XLEN bit data from the record type
  function to_envcfg(envcfg : csr_envcfg_type) return wordx is
    -- Non-constant
    variable xenvcfg : word64 := zerow64;
  begin
    xenvcfg(63)         := envcfg.stce;
    xenvcfg(62)         := envcfg.pbmte;
    xenvcfg(61)         := envcfg.adue;
    xenvcfg(60)         := envcfg.cde;
    xenvcfg(59)         := envcfg.dte;
    xenvcfg(7)          := envcfg.cbze;
    xenvcfg(6)          := envcfg.cbcfe;
    xenvcfg(5 downto 4) := envcfg.cbie;
    xenvcfg(3)          := envcfg.sse;
    xenvcfg(2)          := envcfg.lpe;
    xenvcfg(0)          := envcfg.fiom;

    return xenvcfg(wordx'range);
  end;

  -- Return envcfg as an XLEN bit data from the record type
  function to_envcfg(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return wordx is
    -- Non-constant
    variable xenvcfg : csr_envcfg_type := envcfg_mask(envcfg, mask);
  begin
    return to_envcfg(xenvcfg);
  end;

  -- Return envcfg as a record type from an XLEN bit data
  function to_envcfg(wdata  : wordx;
                     envcfg : csr_envcfg_type;
                     mask   : csr_envcfg_type) return csr_envcfg_type is
    -- Non-constant
    variable xenvcfg : csr_envcfg_type := envcfg;
  begin
    if XLEN = 64 then
      xenvcfg.stce   := wdata(63 * (XLEN / 64)) and mask.stce;
      xenvcfg.pbmte  := wdata(62 * (XLEN / 64)) and mask.pbmte;
      xenvcfg.adue   := wdata(61 * (XLEN / 64)) and mask.adue;
      xenvcfg.cde    := wdata(60 * (XLEN / 64)) and mask.cde;
      xenvcfg.dte    := wdata(59 * (XLEN / 64)) and mask.dte;
    end if;
    xenvcfg.cbze    := wdata(7) and mask.cbze;
    xenvcfg.cbcfe   := wdata(6) and mask.cbcfe;
    -- "10 - reserved" ignore write
    if wdata(5 downto 4) /= "10" then
      xenvcfg.cbie  := wdata(5 downto 4) and mask.cbie;
    else
      xenvcfg.cbie  := "00";
    end if;
    xenvcfg.sse     := wdata(3) and mask.sse;
    -- LPE should _not_ be masked by higher mode settings!
    -- If the ZICFILP extension is disabled then IU will pull envcfg.lpe low
    xenvcfg.lpe     := wdata(2);
    xenvcfg.fiom    := wdata(0) and mask.fiom;

    return xenvcfg;
  end;

  -- Return envcfgh as an XLEN bit data from the record type
  function to_envcfgh(envcfg : csr_envcfg_type) return wordx is
    -- Non-constant
    variable xenvcfgh : word64 := zerow64;
  begin
    xenvcfgh(31 downto 29) := envcfg.stce & envcfg.pbmte & '0';
    xenvcfgh(27)           := envcfg.dte;

    return xenvcfgh(wordx'range);
  end;

  -- Return envcfgh as an XLEN bit data from the record type
  function to_envcfgh(envcfg : csr_envcfg_type; mask : csr_envcfg_type) return wordx is
    -- Non-constant
    variable xenvcfg : csr_envcfg_type := envcfg_mask(envcfg, mask);
  begin
    return to_envcfgh(xenvcfg);
  end;

  -- Return envcfgh as a record type from an XLEN bit data
  function to_envcfgh(wdata   : wordx;
                      envcfg  : csr_envcfg_type;
                      mask    : csr_envcfg_type) return csr_envcfg_type is
    -- Non-constant
    variable xenvcfg : csr_envcfg_type := envcfg;
  begin
    xenvcfg.stce   := wdata(31) and mask.stce;
    xenvcfg.pbmte  := wdata(30) and mask.pbmte;
    xenvcfg.adue   := wdata(29) and mask.adue;
    xenvcfg.cde    := wdata(28) and mask.cde;
    xenvcfg.dte    := wdata(27) and mask.dte;

    return xenvcfg;
  end;

  function gen_envcfg_const_mmask(active : extension_type) return csr_menvcfg_const_type is
    variable sstc     : boolean := is_enabled(active, x_sstc);
    variable pbmte    : boolean := false; --is_enabled(active, x_svpbmt);
    variable dte      : boolean := is_enabled(active, x_ssdbltrp);
    variable zicboz   : boolean := is_enabled(active, x_zicboz);
    variable zicbom   : boolean := is_enabled(active, x_zicbom);
    variable fiom     : boolean := is_enabled(active, x_mode_s);
    variable svadu    : boolean := is_enabled(active, x_svadu);
    variable zicfiss  : boolean := is_enabled(active, x_zicfiss);
    variable zicfilp  : boolean := is_enabled(active, x_zicfilp);
    variable smcdeleg : boolean := is_enabled(active, x_smcdeleg);

  begin
    return csr_menvcfg_type'(
      stce   => to_bit(sstc),
      pbmte  => to_bit(pbmte),
      dte    => to_bit(dte),
      cbze   => to_bit(zicboz),
      cbcfe  => to_bit(zicbom),
      adue   => to_bit(svadu),
      cde    => to_bit(smcdeleg),
      cbie   => (others => to_bit(zicbom)),
      fiom   => to_bit(fiom),
      sse    => to_bit(zicfiss),
      lpe    => to_bit(zicfilp)
    );

  end;

  -- Takes constant M mode mask with enabled extensions
  function gen_envcfg_const_hmask(menvcfg_mask : csr_menvcfg_const_type) return csr_henvcfg_const_type is
    variable xenvcfg : csr_envcfg_type := csr_envcfg_rst;
  begin
    -- Only cde is different
    xenvcfg.stce   := menvcfg_mask.stce;
    xenvcfg.pbmte  := menvcfg_mask.pbmte;
    xenvcfg.dte    := menvcfg_mask.dte;
    xenvcfg.cbze   := menvcfg_mask.cbze;
    xenvcfg.cbcfe  := menvcfg_mask.cbcfe;
    xenvcfg.adue   := menvcfg_mask.adue;
    xenvcfg.cbie   := menvcfg_mask.cbie;
    xenvcfg.fiom   := menvcfg_mask.fiom;
    xenvcfg.sse    := menvcfg_mask.sse;
    xenvcfg.lpe    := menvcfg_mask.lpe;

    return xenvcfg;
  end;

  -- Takes constant M mode mask with enabled extensions
  function gen_envcfg_const_smask(menvcfg_mask : csr_menvcfg_const_type) return csr_senvcfg_const_type is
    variable xenvcfg : csr_envcfg_type := csr_envcfg_rst;
  begin
    xenvcfg.cbze  := menvcfg_mask.cbze;
    xenvcfg.cbcfe := menvcfg_mask.cbcfe;
    xenvcfg.cbie  := menvcfg_mask.cbie;
    xenvcfg.sse   := menvcfg_mask.sse;
    xenvcfg.lpe   := menvcfg_mask.lpe;
    xenvcfg.fiom  := menvcfg_mask.fiom;

    return xenvcfg;
  end;

  function calc_henvcfg_write_val(wcsr_in       : wordx;
                                 active_henvcfg : csr_henvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                 return csr_henvcfg_type is
    variable menvcfg  : csr_menvcfg_type := csr_file.menvcfg and active_henvcfg;
    variable wdata    : csr_henvcfg_type := to_envcfg(wcsr_in, csr_file.henvcfg, active_henvcfg);
    -- Some fields might be read-only zero, keep old value as a start.
    variable ret      : csr_henvcfg_type := csr_file.henvcfg;
  begin
    -- For implementations with the hypervisor extension, henvcfg.PBMTE is read-only zero if
    -- menvcfg.PBMTE is zero. This also applies to stce, dte, sse, adue

    -- Allow the writes if not read-only zero from the level above.
    if menvcfg.pbmte = '1' then
      ret.pbmte := wdata.pbmte;
    end if;
    if menvcfg.stce = '1' then
      ret.stce := wdata.stce;
    end if;
    if menvcfg.adue = '1' then
      ret.adue := wdata.adue;
    end if;
    if menvcfg.dte = '1' then
      ret.dte := wdata.dte;
    end if;
    if menvcfg.sse = '1' then
      ret.sse := wdata.sse;
    end if;

    -- These can be written independent of what menvcfg thinks
    ret.cbze   := wdata.cbze;
    ret.cbcfe  := wdata.cbcfe;
    ret.cbie   := wdata.cbie;
    ret.fiom   := wdata.fiom;
    ret.lpe    := wdata.lpe;

    return ret;
  end function;

  function calc_henvcfg_read_val(active_henvcfg : csr_henvcfg_const_type;
                                csr_file        : csr_reg_type)
                                return csr_henvcfg_type is
    variable menvcfg  : csr_menvcfg_type := csr_file.menvcfg and active_henvcfg;
    variable ret      : csr_henvcfg_type := csr_file.henvcfg;

  begin
    -- Allow the read if not read-only zero from the level above.
    if menvcfg.pbmte = '0' then
      ret.pbmte := '0';
    end if;
    if menvcfg.stce = '0' then
      ret.stce := '0';
    end if;
    if menvcfg.adue = '0' then
      ret.adue := '0';
    end if;
    if menvcfg.dte = '0' then
      ret.dte := '0';
    end if;
    if menvcfg.sse = '0' then
      ret.sse := '0';
    end if;
    return ret;

  end function;

  function calc_senvcfg_write_val(wcsr_in       : wordx;
                                 active_henvcfg : csr_henvcfg_const_type;
                                 active_senvcfg : csr_senvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                 return csr_senvcfg_type is
    variable menvcfg  : csr_menvcfg_type := csr_file.menvcfg and active_senvcfg;
    variable henvcfg  : csr_henvcfg_type := calc_henvcfg_read_val(active_henvcfg, csr_file);
    variable wdata    : csr_senvcfg_type := to_envcfg(wcsr_in, csr_file.senvcfg, active_senvcfg);
    -- Some fields might be read-only zero, keep old value as a start.
    variable ret      : csr_senvcfg_type := csr_file.senvcfg;
    variable envcfg   : csr_envcfg_type;
  begin
    if csr_file.v = '1' then
      envcfg := henvcfg;
    else
      envcfg := menvcfg;
    end if;

    -- When menvcfg.SSE is 0, the henvcfg.SSE and senvcfg.SSE fields are read-only zero.
    -- Allow the writes if not read-only zero from the level above.
    if envcfg.sse = '1' then
      ret.sse := wdata.sse;
    end if;

    -- These can be written independent of what m/henvcfg thinks
    ret.cbze   := wdata.cbze;
    ret.cbcfe  := wdata.cbcfe;
    ret.cbie   := wdata.cbie;
    ret.lpe    := wdata.lpe;
    ret.fiom   := wdata.fiom;

    return ret;
  end function;

  function calc_senvcfg_read_val(active_henvcfg : csr_henvcfg_const_type;
                                 active_senvcfg : csr_senvcfg_const_type;
                                 csr_file       : csr_reg_type)
                                return csr_senvcfg_type is
    variable menvcfg  : csr_menvcfg_type := csr_file.menvcfg and active_senvcfg;
    variable henvcfg  : csr_henvcfg_type := calc_henvcfg_read_val(active_henvcfg, csr_file);
    variable ret      : csr_senvcfg_type := csr_file.senvcfg;
    variable envcfg   : csr_envcfg_type;

  begin
    if csr_file.v = '1' then
      envcfg := henvcfg;
    else
      envcfg := menvcfg;
    end if;

    if envcfg.sse = '0' then
      ret.sse := '0';
    end if;
    return ret;

  end function;

  function to_mseccfg(seccfg : csr_seccfg_type) return word64 is
    -- Non-constant
    variable xseccfg : word64 := zerow64;
  begin
    xseccfg(0)            := seccfg.mml;
    xseccfg(1)            := seccfg.mmwp;
    xseccfg(2)            := seccfg.rlb;
    xseccfg(10)           := seccfg.mlpe;

    return xseccfg;
  end;

  function to_mseccfg(data   : wordx;
                      seccfg : csr_seccfg_type) return csr_seccfg_type is
    -- Non-constant
    variable xseccfg : csr_seccfg_type := seccfg;
  begin
    xseccfg.mml   := data(0);
    xseccfg.mmwp  := data(1);
    xseccfg.rlb   := data(2);
    xseccfg.mlpe  := data(10);

    return xseccfg;
  end;

  function to_mseccfgh(data   : wordx;
                       seccfg : csr_seccfg_type) return csr_seccfg_type is
  begin
    return seccfg;
  end;


  function to_capabilityh(fpuconf : word2; cconfig : word64) return word is
    variable data : word := zerow;
  begin
    data               := cconfig(cconfig'high downto cconfig'length/2);
    data(13 downto 12) := fpuconf;

    return data;
  end;

  function to_capability(fpuconf : word2; cconfig : word64) return wordx is
    variable data : word64 := zerow64;
  begin
    data := cconfig;
    if XLEN = 64 then
      data(data'high downto data'length / 2) := to_capabilityh(fpuconf, cconfig);
    end if;

    return data(wordx'range);
  end;

  -- Return hpmevent as a record type from an XLEN bit data
  function to_hpmevent(wdata : wordx; hpmevent_in : hpmevent_type) return hpmevent_type is
    -- Non-constant
    variable hpmevent : hpmevent_type := hpmevent_in;
  begin
    if XLEN = 64 then
      hpmevent.overflow := wdata(XLEN - 1);  -- 63
      hpmevent.minh     := wdata(XLEN - 2);  -- 62
      hpmevent.sinh     := wdata(XLEN - 3);  -- 61
      hpmevent.uinh     := wdata(XLEN - 4);  -- 60
      hpmevent.vsinh    := wdata(XLEN - 5);  -- 59
      hpmevent.vuinh    := wdata(XLEN - 6);  -- 58
      hpmevent.class    := wdata(XLEN - 8 downto XLEN - 7 - log2(MHPEVENT_C));  -- 56 downto 57 -...
      hpmevent.events   := wdata(hpmevent.events'range);
    end if;

    return hpmevent;
  end;

  -- Return hpmeventh as a record type from an XLEN bit data
  function to_hpmeventh(wdata : wordx; hpmevent_in : hpmevent_type) return hpmevent_type is
    -- Non-constant
    variable hpmevent : hpmevent_type := hpmevent_in;
  begin
    hpmevent.overflow := wdata(63 - 32);
    hpmevent.minh     := wdata(62 - 32);
    hpmevent.sinh     := wdata(61 - 32);
    hpmevent.uinh     := wdata(60 - 32);
    hpmevent.vsinh    := wdata(59 - 32);
    hpmevent.vuinh    := wdata(58 - 32);
    --todo

    return hpmevent;
  end;

  -- Return hpmevent as an XLEN bit data from the record type
  function to_hpmevent(hpmevent : hpmevent_type) return wordx is
    -- Non-constant
    variable rdata : word64 := zerow64;
  begin
    rdata(63) := hpmevent.overflow;
    rdata(62) := hpmevent.minh;
    rdata(61) := hpmevent.sinh;
    rdata(60) := hpmevent.uinh;
    rdata(59) := hpmevent.vsinh;
    rdata(58) := hpmevent.vuinh;
    rdata(56 downto 57 - log2(MHPEVENT_C)) := hpmevent.class;
    rdata(hpmevent.events'range)           := hpmevent.events;

    return rdata(wordx'range);
  end;

  -- Return hpmeventh as an XLEN bit data from the record type
  function to_hpmeventh(hpmevent : hpmevent_type) return wordx is
    -- Non-constant
    variable rdata : word64 := zerow64;
  begin
    rdata(63 - 32) := hpmevent.overflow;
    rdata(62 - 32) := hpmevent.minh;
    rdata(61 - 32) := hpmevent.sinh;
    rdata(60 - 32) := hpmevent.uinh;
    rdata(59 - 32) := hpmevent.vsinh;
    rdata(58 - 32) := hpmevent.vuinh;
    --todo

    return rdata(wordx'range);
  end;

  function hpmevent(event : integer) return hpmevent_type is
  begin
    return to_hpmevent(u2vec(event, XLEN), hpmevent_none);
  end;

  function to_scountinhibit(mcountinhibit_in : word; mcounteren : word; wcsr : wordx) return word is
    variable mcountinhibit : word;
  begin
    mcountinhibit    := (mcountinhibit_in and not mcounteren) or (wcsr(mcounteren'range) and mcounteren);
    mcountinhibit(1) := '0';
    return mcountinhibit;
  end function;


  -- OR reduce a std_logic_vector
  function or_reduce(input : std_logic_vector) return std_logic is
    variable output : std_logic;
  begin
    output := not all_0(input);

    return output;
  end;

  -- Returns an event signal for an hpmcounter.
  -- IF THE COUNTER SUPPORTS MASKING, the N upper bits of hpmevent are
  -- used to define the event class, the remaining bits are used as a
  -- mask that selects (1) or ignores (0) the events within a given class.
  -- The output event is an or reduction of any of the selected events.
  -- IF THE COUNTER DOESN'T SUPPORT MASKING, it returns NO_EVENT if the mask has
  -- more than one bit active.

  -- hpmevent: hpmevent register for our target counter
  -- evt: Vector of input events
  -- cnt: Index of the target counter (EG: 3 -> mphcounter3)
  function filter_hpmevent(hpmevent : hpmevent_type; evt : evt_type; cnt : integer) return std_logic is
    variable class  : integer     := u2i(hpmevent.class);
    variable mask   : events_type := hpmevent.events;
    variable filter : std_logic   := MHPCOUNT_FIL(cnt);  -- Check if target counter has filter events enabled
    -- Non-constant
    variable rdata  : std_logic := '1';
  begin
    if filter = '1' then
      rdata := or_reduce((evt(class) and mask));
    else
      -- Check if mask is a power of 2 and not 0
       if (single_1(mask)) then
         rdata := evt(class)(u2i(mask));
       else
         rdata := '0';
       end if;
    end if;

    return rdata;
  end;

  -- Incoming pmpaddr has at least two zeros at the top.
  function pmp_precalc(pmpaddr    : pmpaddr_type;
                       pmpaddr_m1 : pmpaddr_type;
                       valid      : boolean;
                       a          : pmpcfg_access_type;
                       no_tor     : integer;
                       g          : integer;
                       msb        : integer := 31
                      ) return pmp_precalc_type is
    -- Non-constant
    variable precalc : pmp_precalc_type := pmp_precalc_none;
    variable mask    : std_logic_vector(precalc.low'length - 1 + 2 downto 0);
    variable low     : pmpaddr_type;
    variable high    : pmpaddr_type;
  begin
    -- At startup there may be X's.
-- pragma translate_off
    assert is_x(pmpaddr) or get_hi(pmpaddr, 2) = "00"
      report "Bad pmpaddr for precalc"
      severity failure;
-- pragma translate_on

    -- Concatenate PMP type for mask creation. It contains a zero for
    -- TOR/NA4 and thus the used mask will then equal the input.
    -- For NAPOT it is 11, and thus the addition will propagate up to
    -- the marker zero. Which will be set and everything below cleared.
    -- and thus will work in the mask calculation.
    -- Note that pmpaddr_type is "downto 2" since bottom two address bits are implicit "00".
    mask                     := pmpaddr & a;
    -- Make sure g aligns the mask properly. Low bits should not matter!
    mask(g downto 2)         := (others => '1');
    mask                     := uadd(mask,  1);
    -- Keep the bits above the marker zero.
    low                      := pmpaddr and mask(mask'high downto 2);
    if no_tor = 1 then
      -- No actual TOR support, so provide mask (high bits set) instead.
      high                   := not (pmpaddr xor mask(mask'high downto 2));
      -- Make sure g clears the mask properly. Low bits should not matter!
      high(g downto 2)       := (others => '0');
    else
      if a = PMP_TOR then
        low                  := pmpaddr_m1;
        low(g + 1 downto 2)  := (others => '0');
        high                 := pmpaddr;
        high(g + 1 downto 2) := (others => '0');
      else
        -- "Fill in" the zero marker to get the high address.
        high                 := pmpaddr or mask(mask'high downto 2);
        -- Compensate so that we can use the same comparator.
        high                 := uadd(high, 1);
        -- Set max address plus 1 if bits of high set above our msb.
        if not all_0(high(high'high downto msb + 1)) then
          high               := (others => '0');
          high(msb + 1)      := '1';
        end if;
      end if;
    end if;


    precalc.valid := to_bit(valid);
    precalc.low   := low;
    precalc.high  := high;

    return precalc;
  end;

  procedure pmp_precalc(pmpaddr     : in  pmpaddr_vec_type;
                        pmpcfg_in   : in  pmpcfg_vec_type;
                        precalc     : out pmp_precalc_vec;
                        pmp_entries : in  integer;
                        pmp_no_tor  : in  integer;
                        pmp_g       : in  integer;
                        msb         : in  integer := 31
                       ) is
    -- Non-constant
    variable a          : pmpcfg_access_type;
    variable pmpaddr_m1 : pmpaddr_type;
  begin
    for i in 0 to pmp_entries - 1 loop
      a := pmpcfg(pmp_entries, pmpcfg_in, i, 3, 2);

      -- Bottom address for PMP_TOR.
      pmpaddr_m1   := pmpaddrzero;
      if i /= 0 then
        pmpaddr_m1 := pmpaddr(i - 1);
      end if;

      precalc(i) := pmp_precalc(pmpaddr(i), pmpaddr_m1,
                                not (a = PMP_OFF or (pmp_no_tor = 1 and a = PMP_TOR)),
                                a,
                                pmp_no_tor, pmp_g, msb);
    end loop;
  end;

  function smepmp_fail(smepmp    : integer;
                       mml       : std_logic;
                       prv       : priv_lvl_type;
                       access_in : pmpcfg_access_type;
                       l         : std_logic;
                       r         : std_logic;
                       w         : std_logic;
                       x         : std_logic) return std_logic is
    variable rwo : std_ulogic  :=     r and w and not x;
    variable rwx : std_ulogic  :=     r and w and     x;
    variable owo : std_ulogic  := not r and w and not x;
    variable owx : std_ulogic  := not r and w and     x;
    -- Non-constant
    variable fail : std_ulogic := '0';
  begin
    if smepmp = 0 or mml = '0' then
      -- Only fail if not machine mode access, or for locked entries.
      if prv /= PRIV_LVL_M or l = '1' then
        if access_in = PMP_ACCESS_X then
          fail := not x;
        elsif access_in = PMP_ACCESS_R then
          fail := not r;
        elsif access_in = PMP_ACCESS_W then
          fail := not w;
        else  -- Unknown access - cannot happen!
          fail := '1';
        end if;
      end if;
    else
      -- Somewhat more complicated for Smepmp.
      if l = '0' then
        if prv /= PRIV_LVL_M then
          if access_in = PMP_ACCESS_X then
            fail := not x or owx;
          elsif access_in = PMP_ACCESS_R then
            fail := not (r or owo or owx);
          elsif access_in = PMP_ACCESS_W then
            fail := not (rwo or rwx or owx);
          else  -- Unknown access - cannot happen!
            fail := '1';
          end if;
        else
          if access_in = PMP_ACCESS_X then
            fail := '1';
          elsif access_in = PMP_ACCESS_R then
            fail := not (owo or owx);
          elsif access_in = PMP_ACCESS_W then
            fail := not (owo or owx);
          else  -- Unknown access - cannot happen!
            fail := '1';
          end if;
        end if;
      else
        if prv /= PRIV_LVL_M then
          if access_in = PMP_ACCESS_X then
            fail := not (owo or owx);
          elsif access_in = PMP_ACCESS_R then
            fail := not rwx;
          elsif access_in = PMP_ACCESS_W then
            fail := '1';
          else  -- Unknown access - cannot happen!
            fail := '1';
          end if;
        else
          if access_in = PMP_ACCESS_X then
            fail := not ((not w and x) or owo or owx);
          elsif access_in = PMP_ACCESS_R then
            fail := not (r or owx);
          elsif access_in = PMP_ACCESS_W then
            fail := not rwo;
          else  -- Unknown access - cannot happen!
            fail := '1';
          end if;
        end if;
      end if;
    end if;

    return fail;
  end;

  function smepmp_ok_r(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx_in : word3) return boolean is
    variable r   : std_ulogic  := rwx_in(2);
    variable w   : std_ulogic  := rwx_in(1);
    variable x   : std_ulogic  := rwx_in(0);
    variable rwx : std_ulogic  :=     r and w and     x;
    variable owo : std_ulogic  := not r and w and not x;
    variable owx : std_ulogic  := not r and w and     x;
    -- Non-constant
    variable fail : std_ulogic := '0';
  begin
    if none = '1' then
      fail := mmwp or to_bit(prv /= PRIV_LVL_M);
    elsif smepmp = 0 or mml = '0' then
      -- Only fail if not machine mode access, or for locked entries.
      if none = '1' then
        fail := to_bit(prv /= PRIV_LVL_M);
      elsif prv /= PRIV_LVL_M or l = '1' then
        fail := not r;
      end if;
    else
      -- Somewhat more complicated for Smepmp.
      if l = '0' then
        if prv /= PRIV_LVL_M then
          fail := not (r or owo or owx);
        else
          fail := not (owo or owx);
        end if;
      else
        if prv /= PRIV_LVL_M then
          fail := not rwx;
        else
          fail := not (r or owx);
        end if;
      end if;
    end if;

    return fail = '0';
  end;

  function smepmp_ok_w(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx_in : word3) return boolean is
    variable r   : std_ulogic  := rwx_in(2);
    variable w   : std_ulogic  := rwx_in(1);
    variable x   : std_ulogic  := rwx_in(0);
    variable rwo : std_ulogic  :=     r and w and not x;
    variable rwx : std_ulogic  :=     r and w and     x;
    variable owo : std_ulogic  := not r and w and not x;
    variable owx : std_ulogic  := not r and w and     x;
    -- Non-constant
    variable fail : std_ulogic := '0';
  begin
    if none = '1' then
      fail := mmwp or to_bit(prv /= PRIV_LVL_M);
    elsif smepmp = 0 or mml = '0' then
      -- Only fail if not machine mode access, or for locked entries.
      if prv /= PRIV_LVL_M or l = '1' then
        fail := not w;
      end if;
    else
      -- Somewhat more complicated for Smepmp.
      if l = '0' then
        if prv /= PRIV_LVL_M then
          fail := not (rwo or rwx or owx);
        else
          fail := not (owo or owx);
        end if;
      else
        if prv /= PRIV_LVL_M then
          fail := '1';
        else
          fail := not rwo;
        end if;
      end if;
    end if;

    return fail = '0';
  end;

  function smepmp_ok_x(smepmp : integer;
                       mmwp   : std_logic;
                       mml    : std_logic;
                       prv    : priv_lvl_type;
                       none   : std_logic;
                       l      : std_logic;
                       rwx    : word3) return boolean is
    variable r   : std_ulogic  := rwx(2);
    variable w   : std_ulogic  := rwx(1);
    variable x   : std_ulogic  := rwx(0);
    variable owo : std_ulogic  := not r and w and not x;
    variable owx : std_ulogic  := not r and w and     x;
    -- Non-constant
    variable fail : std_ulogic := '0';
  begin
    if smepmp = 0 or mml = '0' then
      -- Only fail if not machine mode access, or for locked entries.
      if none = '1' then
        fail := mmwp or to_bit(prv /= PRIV_LVL_M);
      elsif prv /= PRIV_LVL_M or l = '1' then
        fail := not x;
      end if;
    else
      -- Somewhat more complicated for Smepmp.
      if none = '1' then
        fail   := '1';
      elsif l = '0' then
        if prv /= PRIV_LVL_M then
          fail := not x or owx;
        else
          fail := '1';
        end if;
      else
        if prv /= PRIV_LVL_M then
          fail := not (owo or owx);
        else
          fail := not ((not w and x) or owo or owx);
        end if;
      end if;
    end if;

    return fail = '0';
  end;

  function smepmp_rwx(pmpcfg  : pmpcfg_vec_type;
                      mmwp    : std_logic;
                      mml     : std_logic;
                      prv     : priv_lvl_type;
                      hit     : std_logic_vector;
                      entries : integer := 16;
                      smepmp  : integer := 0
                     ) return word3 is
    variable none : boolean                     := all_0(hit);
    -- Lowest numbered hit is defined as the highest priority PMP.
    variable prio : std_logic_vector(hit'range) := hit and std_logic_vector(-signed(hit));
    -- Non-constant
    variable r_a : std_logic_vector(entries - 1 downto 0);
    variable w_a : std_logic_vector(entries - 1 downto 0);
    variable x_a : std_logic_vector(entries - 1 downto 0);
    variable r   : std_logic;
    variable w   : std_logic;
    variable x   : std_logic;
    variable rwx : word3;
  begin
    for n in r_a'range loop
      rwx    := pmpcfg(n)(0) & pmpcfg(n)(1) & pmpcfg(n)(2);
      r_a(n) := to_bit(smepmp_ok_r(smepmp, '0', mml, prv, '0', pmpcfg(n)(7), rwx));
      w_a(n) := to_bit(smepmp_ok_w(smepmp, '0', mml, prv, '0', pmpcfg(n)(7), rwx));
      x_a(n) := to_bit(smepmp_ok_x(smepmp, '0', mml, prv, '0', pmpcfg(n)(7), rwx));
    end loop;
    r := not all_0(r_a and prio);
    w := not all_0(w_a and prio);
    x := not all_0(x_a and prio);

    -- No hit means failure in non-machine mode, if there are implemented entries.
    -- Also failure in machine mode if "Machine Mode Whitelist Policy".
    -- With "Machine Mode Lockdown", executing code is always a failure with no hit.
    if none and entries /= 0 then
      if prv /= PRIV_LVL_M then
        r   := '0';
        w   := '0';
        x   := '0';
      elsif smepmp = 1 then
        r := not mmwp;
        w := not mmwp;
        x := not mmwp and not mml;
      end if;
    end if;

    rwx := r & w & x;
    return rwx;
  end;


  -- Note that this does not support pmp_g = 0!
  function pmp_match(precalc : pmp_precalc_vec;
                     addr    : std_logic_vector;
                     entries : integer := 16;
                     no_tor  : integer := 1;
                     pmp_g   : integer range 1 to 32 := 1;
                     msb     : integer := 31
                    ) return std_logic_vector is

    subtype  pmp_vec_type      is std_logic_vector(entries - 1 downto 0);
    type     pmpcfg_access_vec is array (0 to entries - 1) of pmpcfg_access_type;
    -- Non-constant
    variable enable : pmp_vec_type := (others => '1');
    variable hit    : pmp_vec_type := (others => '0');

    function check(precalc : in pmp_precalc_type;
                   addr    : std_logic_vector;
                   no_tor  : integer := 1;
                   pmp_g   : integer range 1 to 32 := 1;
                   msb     : integer := 31
                  ) return boolean is
      variable lowhi_msb : integer := msb - 55 + precalc.low'high;
      variable align     : integer := pmp_g - 1;
    begin
      if no_tor = 1 then
        -- With no TOR, mask is in pmphigh.
        if (('0' & addr(msb downto 3 + align)) and precalc.high(lowhi_msb downto 3 + align)) =
           precalc.low(lowhi_msb downto 3 + align) then
          return true;
        end if;
      else
        -- This deals with the requirement to fail on reverse and null ranges,
        -- since it is then impossible to be >= low and < high.
        if unsigned('0' & addr(msb downto 3 + align)) >= unsigned(precalc.low(lowhi_msb downto 3 + align)) and
           unsigned('0' & addr(msb downto 3 + align)) < unsigned(precalc.high(lowhi_msb downto 3 + align)) then
          return true;
        end if;
      end if;

      return false;
    end;


  begin
    for i in 0 to entries - 1 loop
      if check(precalc(i), addr, no_tor, pmp_g, msb) then
      --if check(precalc(i)) then
        hit(i) := precalc(i).valid;
      end if;
    end loop;


    return hit;
  end;


  function to_pma(v_in : std_logic_vector) return pma_t is
    variable v : std_logic_vector(v_in'length - 1 downto 0) := v_in;
    -- Non-constant
    variable pma : pma_t;
  begin
    pma := (
      valid => v(0),
      r     => v(1),
      w     => v(2),
      x     => v(3),
      pt_r  => v(4),
      pt_w  => v(5),
      cache => v(6),
      burst => v(7),
      idem  => v(8),
      amo   => v(9),
      lrsc  => v(10),
      busw  => v(11)
    );

    return pma;
  end;

  function from_pma(pma : pma_t) return std_logic_vector is
    -- Non-constant
    variable v : word64 := (others => '0');
  begin
    v(0)  := pma.valid;
    v(1)  := pma.r;
    v(2)  := pma.w;
    v(3)  := pma.x;
    v(4)  := pma.pt_r;
    v(5)  := pma.pt_w;
    v(6)  := pma.cache;
    v(7)  := pma.burst;
    v(8)  := pma.idem;
    v(9)  := pma.amo;
    v(10) := pma.lrsc;
    v(11) := pma.busw;

    return v(PMA_SIZE - 1 downto 0);
  end;

  -- Ensure PMA configuration is consistent and useful.
  function pma_sanitize(data : word64; is_rv64 : boolean) return word64 is
    -- Non-constant
    variable pma : pma_t := to_pma(data);
  begin

    -- Fetching instructions from non-idempotent memory is a bad idea.
    if pma.idem = '0' then
      pma.x := '0';
    end if;

    -- NOEL-V is incapable of fetching code without burst.
    if pma.burst = '0' then
      pma.x := '0';
    end if;

    -- Cannot have atomics without R/W.
    if pma.r = '0' or pma.w = '0' then
      pma.amo  := '0';
      pma.lrsc := '0';
    end if;

    -- It makes no sense to _only_ support R/W of PT.
    if pma.r = '0' then
      pma.pt_r := '0';
    end if;
    if pma.w = '0' then
      pma.pt_w := '0';
    end if;

    -- It makes no sense to support write of non-readable PT.
    if pma.pt_r = '0' then
      pma.pt_w := '0';
    end if;

    -- It makes no sense to support PT in non-idempotent memory.
    if pma.idem = '0' then
      pma.pt_r := '0';
      pma.pt_w := '0';
    end if;

    -- Writable PT requires atomic support
    if pma.amo = '0' then
      pma.pt_w := '0';
    end if;

    -- Caching non-idempotent memory seems like a bad idea.
    if pma.idem = '0' then
      pma.cache := '0';
    end if;

    -- Currently RV64 PT cannot be accessed in non-wide memory.
    if is_rv64 and pma.busw = '0' then
      pma.pt_r := '0';
      pma.pt_w := '0';
    end if;


    -- If it is invalid...
    if pma.valid = '0' then
      pma := pma_unused;
    end if;

    return uext(from_pma(pma), 64);
  end;

  function pma_valid(pma : pma_t) return boolean is
  begin
    return pma.valid = '1';
  end;

  function pma_r(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.r = '1';
  end;

  function pma_w(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.w = '1';
  end;

  function pma_x(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.x = '1';
  end;

  function pma_pt_r(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.pt_r = '1';
  end;

  function pma_pt_w(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.pt_w = '1';
  end;

  function pma_cache(pma : pma_t) return std_logic is
  begin
    return to_bit(pma_valid(pma) and pma.cache = '1');
  end;

  function pma_burst(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.burst = '1';
  end;

  function pma_idem(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.idem = '1';
  end;

  function pma_amo(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.amo = '1';
  end;

  function pma_lrsc(pma : pma_t) return boolean is
  begin
    return pma_valid(pma) and pma.lrsc = '1';
  end;

  function pma_busw(pma : pma_t) return std_logic is
  begin
    return to_bit(pma_valid(pma) and pma.busw = '1');
  end;

  function pma_rwx(pma : pma_t) return word3 is
    variable valid : word3 := (others => pma.valid);
    variable rwx   : word3 := (pma.r & pma.w & pma.x) and valid;
  begin
    return rwx;
  end;

  function tost_pma_vrwx(pma : pma_t) return string is
  begin
    return tost_bits(pma.valid & pma.r & pma.w & pma.x);
  end;

  -- Update existing PMA information according to PBMT
  -- Note that if the system normally separates memory ordering between
  -- main memory and I/O, changing the type via PBMT actually means that
  -- _both_ orderings must be observed for FENCE, .aq and .rl.
  -- NC  - Non-cachable, idempotent, weakly-ordered, main memory
  function pma_pbmt_nc(pma_in : pma_t) return pma_t is
    -- Non-constant
    variable pma : pma_t := pma_in;
  begin
    pma.cache := '0';
    pma.idem  := '1';


    return pma;
  end;

  -- IO  - Non-cachable, non-idempotent, strongly-ordered, I/O
  function pma_pbmt_io(pma_in : pma_t) return pma_t is
    -- Non-constant
    variable pma : pma_t := pma_in;
  begin
    pma.cache := '0';
    pma.idem  := '0';

    -- Sanitize PMA
    pma.pt_r  := '0';     --   Non-idempotent PT seems like a bad idea.
    pma.pt_w  := '0';

    return pma;
  end;

  function pma_precalc(addr_arr    : word64_arr;
                       pma_entries : integer range 0 to 16;
                       physaddr    : integer) return pmp_precalc_vec is
    -- pma_g > 1  hit is really hit<2 ** (pma_g + 2)>
    variable pma_g      : integer                              := 10;  -- 4 kByte (minimum page size)
    variable pma_normal : word64_arr(0 to addr_arr'length - 1) := addr_arr;
    variable entries    : integer                              := minimum(pma_entries, addr_arr'length);
    -- Non-constant
    variable precalc : pmp_precalc_vec(0 to PMAENTRIES - 1)    := (others => pmp_precalc_none);
    variable addr    : pmpaddr_type;
    variable addr_m1 : pmpaddr_type;
  begin
    for i in 0 to entries - 1 loop
      addr       := pma_normal(i)(addr'range);

      -- Bottom address for TOR.
      addr_m1    := pmpaddrzero;
      if i /= 0 then
        addr_m1  := pma_normal(i - 1)(addr_m1'range);
      end if;

      precalc(i) := pmp_precalc(addr, addr_m1, not all_0(addr),
                                cond(get_hi(pma_normal(i)) = '1', PMP_TOR, PMP_NAPOT),
                                0, pma_g, physaddr - 1);
    end loop;

    return precalc;
  end;

  -- Decodes a mask for an address where (31 downto 32 - index_width) specify which element to look at.
  -- Currently fixed index_width = 4.
  function decode_mask(addr : word32; mask : std_logic_vector) return std_logic is
    variable index_width : integer                                    := 4;
    variable index       : std_logic_vector(index_width - 1 downto 0) := get(addr, 32 - index_width, index_width);
  begin
    return mask(u2i(index));
  end;

  -- Checks for same mask value in a 1G page range around the index for an address where (31 downto 32 - index_width).
  -- Currently fixed index_width = 4 -> 256M per mask entry -> 4 entries in range (Sv39).
  -- Assumes that bits (address_high downto 32) are checked elsewhere.
  function is_same_mask(addr : word32; mask : std_logic_vector) return std_logic is
    variable index_width : integer                                    := 4;
    variable index       : std_logic_vector(index_width - 1 downto 0) := get(addr, addr'high + 1 - index_width, index_width);
    variable part        : std_logic_vector(4 - 1 downto 0)           := (others => '0'); --get(mask, (u2i(index) / 4) * 4, 4);
  begin
    -- DC workaround
    for i in 0 to 2**index_width-1 loop
      if u2i(index) = i then
        part := get(mask, (i / 4) * 4, 4);
      end if;
    end loop;
    return to_bit(all_0(part) or all_1(part));  -- Check that all 4 parts of a 1G page contain the same PMA data!
  end;

  -- Figure out PMA for an address (forced to 32 bits) using top nybble (31 downto 28).
  -- Everything above that is RAM!
  -- Note that wide bus (busw) and cacheability (cached) are separate.
  --  memory special
  --    0       0     unallocated
  --    0       1     I/O
  --    1       0     RAM
  --    1       1     ROM
  -- Reports not fit when 1G areas need to be split.
  procedure pma_masks(data    : in  word64_arr;
                      addr_in : in  std_logic_vector;
                      valid   : in  std_logic;
                      pma_out : out pma_t;
                      fit_out : out std_logic_vector;
                      msb     : in  integer := 31) is
    variable addr    : word32  := fit0ext(addr_in, 32);
    variable memory  : boolean := decode_mask(addr, data(0)) = '1';
    variable special : boolean := decode_mask(addr, data(1)) = '1';
    -- Non-constant
    variable pma  : pma_t := pma_unused;
    variable fit  : std_logic_vector(fit_out'range);
  begin
    pma.valid   := valid;
    pma.r       := '1';
    pma.cache   := decode_mask(addr, data(2));
    pma.busw    := decode_mask(addr, data(3));
    if (addr_in'high > 31 and not all_0(addr_in(addr_in'high downto 32))) or
       (memory and not special) then            -- RAM
      pma.w     := '1';
      pma.x     := '1';
      pma.pt_r  := '1';
      pma.pt_w  := '1';
      pma.burst := '1';
      pma.idem  := '1';
      pma.amo   := '1';
      pma.lrsc  := '1';
    elsif memory then                           -- ROM
      pma.x     := '1';
      pma.burst := '1';
      pma.idem  := '1';
    elsif special then                          -- I/O
      pma.w     := '1';
      pma.amo   := '1';
    else
      pma       := pma_unused;
    end if;

    fit := (fit'range => is_same_mask(addr, data(0)) and is_same_mask(addr, data(1)) and
                         is_same_mask(addr, data(2)) and is_same_mask(addr, data(3)));
--    fit := (others => '0');

--    if not all_1(fit) then
--      report "Does not fit " & tost(addr(31 downto 28));
--    end if;

    pma_out := pma;
    fit_out := fit;
  end;

  -- Note that this does not support pmp_g = 0!
  -- Note that no_tor must be the same as for pma_mmuu (ie 0) if that is in use,
  -- which is currently the case!
  procedure pma_unit(precalc : in  pmp_precalc_vec;
                     addr    : in  std_logic_vector;
                     valid   : in  std_ulogic;
                     hit_out : out std_logic_vector;
                     entries : in  integer := 16;
                     no_tor  : in  integer := 0;
                     msb     : in  integer := 31
                    ) is
    -- pma_g > 1  hit is really hit<2 ** (pma_g + 2)>
    variable pma_g       : integer            := 10;  -- 4 kByte (minimum page size)
    subtype  pma_vec_type      is std_logic_vector(entries - 1 downto 0);
    variable zero_entry  : pma_vec_type       := (others => '0');
    variable lowhi_msb   : integer            := msb - 55 + precalc(0).low'high;
    -- Non-constant
    variable enable      : pma_vec_type       := (others => '1');
    variable hit         : pma_vec_type       := (others => '0');
    variable align       : integer            := pma_g - 1;
  begin

    -- Two address-matching modes are supported: naturally aligned
    -- power-of-2 regions (NAPOT); and the top boundary of an arbitrary range (TOR).

    -- Resolve address in pmpaddr CSRs registers and provide memory region boundaries.

    for i in hit'range loop

      enable(i) := precalc(i).valid;

      if no_tor = 1 then
        -- With no TOR, mask is in pmphigh.
        if (('0' & addr(msb downto 3 + align)) and precalc(i).high(lowhi_msb downto 3 + align)) =
           precalc(i).low(lowhi_msb downto 3 + align) then
          hit(i) := enable(i);
        end if;
      else
        -- This deals with the requirement to fail on reverse and null ranges,
        -- since it is then impossible to be >= low and < high.
        if unsigned('0' & addr(msb downto 3 + align)) >= unsigned(precalc(i).low(lowhi_msb downto 3 + align)) and
           unsigned('0' & addr(msb downto 3 + align)) < unsigned(precalc(i).high(lowhi_msb downto 3 + align)) then
          hit(i)  := enable(i);
        end if;
      end if;


    end loop;

    hit_out            := (hit_out'range => '0');
    hit_out(hit'range) := hit;

  end;

  -- Ensure that only PTE sized masks are used
  function limit_mask(addr_mask_in : std_logic_vector; high : integer := 0) return std_logic_vector is
    -- Non-constant
    variable addr_mask : word64 := (others => '1');
    variable new_mask  : word64 := (others => '1');
  begin
    addr_mask(addr_mask_in'range) := addr_mask_in;
    new_mask(11 downto 0)   := (others => '0');
--    return addr_mask_in;
    -- It is only allowed to have an uninterrupted set of zeros at the bottom.
    if not all_1(addr_mask(38 downto 30)) then
      new_mask(38 downto 12) := (others => '0');
    end if;
    if not all_1(addr_mask(29 downto 21)) then
      new_mask(29 downto 12) := (others => '0');
    end if;
    if not all_1(addr_mask(20 downto 12)) then
      new_mask(20 downto 12) := (others => '0');
    end if;


    return new_mask(addr_mask_in'range);
  end;

  -- Specialized for MMU use.
  -- Alignment fixed to 4 kByte.
  procedure pmp_mmuu(precalc_low  : in  std_logic_vector;
                     precalc_high : in  std_logic_vector;
                     addr_low     : in  std_logic_vector;
                     addr_mask_in : in  std_logic_vector;
                     hit          : out std_logic;
                     fit          : out std_logic
                    ) is
    variable addr_mask : std_logic_vector(addr_mask_in'range);  -- := limit_mask(addr_mask_in, addr_mask_in'high);
  begin
    addr_mask := addr_mask_in;
    hit := '0';
    fit := '0';
      -- MMU block vs PMP block
      --   MMU block low >= PMP block low
      if unsigned(addr_low) >= unsigned(precalc_low) then
        -- and MMU block low <= PMP block high
        -- This deals with the requirement to fail on reverse and null ranges,
        -- since it is then impossible to be >= low and < high.
        if unsigned('0' & addr_low) < unsigned(precalc_high) then
          -- MMU block starts inside PMP block, so hit!
          hit := '1';
        end if;
        -- and MMU block high <= PMP block high
        if unsigned('0' & (addr_low or not addr_mask)) < unsigned(precalc_high) then
          -- MMU block lies entirely within PMP block, so fit!
          fit := '1';
        end if;
      else  -- MMU block low < PMP block low
        --     and MMU block high >= PMP block low
        if unsigned(addr_low or not addr_mask) >= unsigned(precalc_low) then
          -- MMU block overlaps at least low part of PMP block, so hit!
          hit := '1';
        end if;
      end if;
  end;

  -- Specialized for MMU use.
  -- Alignment fixed to 4 kByte.
  procedure pmp_mmuu(precalc    : in  pmp_precalc_vec;
                     pmpcfg_in  : in  pmpcfg_vec_type;
                     mml        : in  std_ulogic;
                     addr_low   : in  std_logic_vector;
                     addr_mask  : in  std_logic_vector;
                     valid      : in  std_ulogic;
                     hit_out    : out std_logic_vector;
                     fit_out    : out std_logic_vector;
                     l_out      : out std_logic_vector;
                     r_out      : out std_logic_vector;
                     w_out      : out std_logic_vector;
                     x_out      : out std_logic_vector;
                     msb        : in  integer := 31;
                     smepmp     : in  integer := 0
                    ) is
    -- pmp_g > 1  hit is really hit<2 ** (pmp_g + 2)>
    variable pmp_g       : integer            := 10;  -- 4 kByte (minimum page size)
    variable align       : integer            := pmp_g - 1;
    -- Non-constant
    subtype  pmp_vec_type      is std_logic_vector(precalc'length - 1 downto 0);
    type     pmpcfg_access_vec is array (precalc'range) of pmpcfg_access_type;
    variable lowhi_msb   : integer            := msb - 55 + precalc(precalc'low).low'high;
    -- Non-constant
    variable cfg         : word8;
    variable l           : pmp_vec_type;
    variable a           : pmpcfg_access_vec;
    variable x           : pmp_vec_type;
    variable w           : pmp_vec_type;
    variable r           : pmp_vec_type;
    variable rwo         : pmp_vec_type;
    variable rwx         : pmp_vec_type;
    variable owo         : pmp_vec_type;
    variable owx         : pmp_vec_type;
    variable enable      : pmp_vec_type       := (others => '1');
    variable hit         : pmp_vec_type       := (others => '0');
    variable fit         : pmp_vec_type       := (others => '0');
    variable hit_prio    : pmp_vec_type;
  begin

    -- The A field in a PMP entry's configuration register encodes
    -- the address-matching mode of the associated PMP address register.
    -- When A=0, this PMP entry is disabled and matches no addresses.
    -- Two other address-matching modes are supported: naturally aligned
    -- power-of-2 regions (NAPOT); and the top boundary of an arbitrary range (TOR).

    -- Resolve address in pmpaddr CSRs registers and provide memory region
    -- boundaries.

    for i in precalc'range loop

      -- Generate larwx signals.
      cfg  := pmpcfg_in(i);
      l(i) := cfg(7);
      a(i) := cfg(4 downto 3);
      x(i) := cfg(2);
      w(i) := cfg(1);
      r(i) := cfg(0);
      rwo(i) :=     r(i) and w(i) and not x(i);
      rwx(i) :=     r(i) and w(i) and     x(i);
      owo(i) := not r(i) and w(i) and not x(i);
      owx(i) := not r(i) and w(i) and     x(i);

      -- Somewhat more complicated for Smepmp.
      if smepmp = 1 and mml = '1' then
        if l(i) = '0' then
          x(i) := x(i) and not owx(i);
          r(i) := r(i) or owo(i) or owx(i);
          w(i) := rwo(i) or rwx(i) or owx(i);
        else
          x(i) := owo(i) or owx(i);
          r(i) := rwx(i);
          w(i) := '0';
        end if;
      end if;


      enable(i) := precalc(i).valid;

      pmp_mmuu(precalc(i).low(lowhi_msb downto 3 + align), precalc(i).high(lowhi_msb downto 3 + align),
               addr_low(msb downto 3 + align), addr_mask(msb downto 3 + align),
               hit(i), fit(i));


    end loop;

    hit := hit and enable;

    hit_out            := (hit_out'range => '0');
    hit_out(hit'range) := hit;
    fit_out            := (fit_out'range => '0');
    fit_out(fit'range) := fit;
    l_out              := (l_out'range   => '0');
    l_out(l'range)     := l;
    r_out              := (r_out'range   => '0');
    r_out(r'range)     := r;
    w_out              := (w_out'range   => '0');
    w_out(w'range)     := w;
    x_out              := (x_out'range   => '0');
    x_out(x'range)     := x;

  end;

  -- Specialized for MMU use.
  -- Alignment fixed to 4 kByte.
  procedure pma_mmuu(precalc      : in  pmp_precalc_vec;
                     addr_low     : in  std_logic_vector;
                     addr_mask_in : in  std_logic_vector;
                     valid        : in  std_ulogic;
                     hit_out      : out std_logic_vector;
                     fit_out      : out std_logic_vector;
                     msb          : in  integer := 31
                    ) is
    -- pma_g > 1  hit is really hit<2 ** (pma_g + 2)>
    variable pma_g       : integer            := 10;  -- 4 kByte (minimum page size)
    variable align       : integer            := pma_g - 1;
    variable addr_mask   : std_logic_vector(addr_mask_in'range); -- := limit_mask(addr_mask_in);
    -- Non-constant
    subtype  pma_vec_type      is std_logic_vector(hit_out'length - 1 downto 0);
    variable lowhi_msb   : integer            := msb - 55 + precalc(precalc'low).low'high;
    -- Non-constant
    variable enable      : pma_vec_type       := (others => '1');
    variable hit         : pma_vec_type       := (others => '0');
    variable fit         : pma_vec_type       := (others => '0');
  begin
    addr_mask := addr_mask_in;

    -- Two address-matching modes are supported: naturally aligned
    -- power-of-2 regions (NAPOT); and the top boundary of an arbitrary range (TOR).

    -- Resolve address in PMA configuration and provide memory region boundaries.

    for i in hit'range loop

      enable(i) := precalc(i).valid;

      pmp_mmuu(precalc(i).low(lowhi_msb downto 3 + align), precalc(i).high(lowhi_msb downto 3 + align),
               addr_low(msb downto 3 + align), addr_mask(msb downto 3 + align),
               hit(i), fit(i));


    end loop;

    hit := hit and enable;

    hit_out            := (hit_out'range => '0');
    hit_out(hit'range) := hit;
    fit_out            := (fit_out'range => '0');
    fit_out(fit'range) := fit;

  end;

  -- Math operation
  -- ctrl_in(3)   -> size
  -- ctrl_in(2)   -> ADD,LOGIC/MINMAX
  -- ctrl_in(1)   -> MINMAX/MINMAXU
  -- ctrl_in(0)   -> MIN/MAX
  function amo_math_op(
    op1_in  : std_logic_vector;
    op2_in  : std_logic_vector;
    ctrl_in : word4) return std_logic_vector is
    -- Non-constant
    subtype  op_t   is std_logic_vector(op1_in'length downto 0);
    subtype  res_t  is std_logic_vector(op1_in'length - 1 downto 0);
    variable op1     : op_t := ((not ctrl_in(1)) and op1_in(op1_in'left)) & op1_in;
    variable op2     : op_t := ((not ctrl_in(1)) and op2_in(op2_in'left)) & op2_in;
    variable add_res : res_t;
    variable less    : std_ulogic;
    variable pad     : word;
    variable res     : res_t;
  begin
    -- Compute Results
    add_res   := std_logic_vector(signed(op1_in) + signed(op2_in));
    if signed(op1) < signed(op2) then
      less    := '1';
    else
      less    := '0';
    end if;

    if ctrl_in(2) = '0' then
      case ctrl_in(1 downto 0) is
        when "00" =>
          res := add_res;
        when "01" =>
          res := op1_in xor op2_in;
        when "10" =>
          res := op1_in or op2_in;
        when others =>
          res := op1_in and op2_in;
      end case;
    else
      if (less xor ctrl_in(0)) = '1' then
        res   := op1_in;
      else
        res   := op2_in;
      end if;
    end if;

    pad := (others => res(31));
    if ctrl_in(3) = '0' then
      res(res'high downto res'length - pad'length) := pad;
    end if;

    return res;
  end;

  function mmuen_set(mmuen : integer) return integer is
    -- Non-constant
    variable ret : integer := 0;
  begin
    if mmuen > 0 then
      ret := 1;
    end if;

    return ret;
  end;

  -- Jump Unit for JAL and JALR instructions
  procedure jump_unit(active    : in  extension_type;
                      fusel_in  : in  fuseltype;
                      valid_in  : in  std_ulogic;
                      imm_in    : in  wordx;
                      ras_in    : in  nv_ras_out_type;
                      rf1       : in  wordx;
                      flush_in  : in  std_ulogic;
                      jump_out  : out std_ulogic;
                      mem_jump  : out std_ulogic;
                      xc_out    : out std_ulogic;
                      cause_out : out cause_type;
                      tval_out  : out wordx;
                      addr_out  : out std_logic_vector) is  -- pctype
    -- Non-constant
    variable op1         : wordx;
    variable target      : wordx;
    variable jump_xc     : std_ulogic;
    variable memjump_xc  : std_ulogic;
    variable jump        : std_ulogic := '0';
    variable mem_jumpt   : std_ulogic;
    variable tval        : wordx;
  begin
    -- Jump in case of:
    -- * Valid JALR instruction and ras_in.hit = '0' or address mismatch

    -- Operations:
    -- * JALR   -> rs1 + sign_extend(imm)
    target       := std_logic_vector(signed(rf1) + signed(imm_in));

    -- Generate Jump Signal
    if valid_in = '1' and v_fusel_eq(fusel_in, JALR) and flush_in = '0' then
      if ras_in.hit = '0' then
        jump     := '1';
      end if;
    end if;

    mem_jumpt := '0';
    -- Jump RAS mispredictions have to be propagated to the instruction cache
    -- in the memory stage to avoid comparator on the select lines.
    if valid_in = '1' and v_fusel_eq(fusel_in, JALR) and flush_in = '0' then
      if ras_in.hit = '1' and ras_in.rdata /= target(ras_in.rdata'range) then
        mem_jumpt := '1';
      end if;
    end if;

    -- Setting the least-significat bit to zero.
    target(0)    := '0';

    -- Generate Exception Signal due to Address Misaligned.
    jump_xc := '0';
    if jump = '1' and inst_addr_misaligned(active, target) then
      jump_xc    := '1';
    end if;

    -- Decouple jump and memjump_xc to not affect the critical path.
    memjump_xc   := '0';
    if mem_jumpt = '1' and inst_addr_misaligned(active, target) then
      memjump_xc := '1';
    end if;

    xc_out       := jump_xc or memjump_xc;
    cause_out    := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    addr_out     := to_addr(target, addr_out'length);
    tval_out     := target;
    jump_out     := jump and not jump_xc;
    mem_jump     := mem_jumpt and not memjump_xc;
  end;

  -- Resolve Unconditional Jumps
  procedure ujump_resolve(active    : in extension_type;
                          inst_in   : in  word;
                          valid_in  : in  std_ulogic;
                          xc_in     : in  std_ulogic;
                          target_in : in  std_logic_vector;     -- pctype
                          next_in   : in  std_logic_vector;     -- pctype
                          taken_in  : in  std_ulogic;
                          hit_in    : in  std_ulogic;
                          xc_out    : out std_ulogic;
                          cause_out : out cause_type;
                          tval_out  : out wordx;
                          jump_out  : out std_ulogic;
                          addr_out  : out std_logic_vector) is  -- pctype
    subtype pctype is std_logic_vector(target_in'range);
    variable opcode   : opcode_type := opcode(inst_in);
    -- Non-constant
    variable target : pctype        := target_in;
    variable xc     : std_ulogic    := '0';
    variable jump   : std_ulogic    := '0';
    variable mis    : std_ulogic    := '0';
  begin
    -- Jump here in case of:
    --        * taken_in = 0 -> We did not get a hit from prediction
    --        * taken_in = 1 and not JAL -> We get an alias

    -- Generate Misprediction Signal due to wrong instruction.
    if (taken_in and hit_in and valid_in) = '1' and xc_in = '0' then
      if opcode /= OP_JAL and opcode /= OP_BRANCH then
        mis     := '1';
        target  := next_in;
      end if;
    end if;

    -- Generate Jump Signal
    if valid_in = '1' and xc_in = '0' and opcode = OP_JAL and (taken_in and hit_in) = '0' then
      jump      := '1';
    end if;

    -- Generate Exception Signal
    if jump = '1' and inst_addr_misaligned(active, target) then
      xc        := '1';
    end if;

    xc_out      := xc;
    cause_out   := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    tval_out    := pc2xlen(target);
    addr_out    := target;
    jump_out    := (jump or mis) and not xc;
  end;

  -- Resolve Early Branch in Decode Stage.
  procedure branch_resolve(active     : in  extension_type;
                           fusel_in   : in  fuseltype;
                           valid_in   : in  std_ulogic;
                           xc_in      : in  std_ulogic;
                           pc_in      : in  std_logic_vector;     -- pctype
                           comp_in    : in  std_ulogic;
                           taken_in   : in  std_ulogic;
                           hit_in     : in  std_ulogic;
                           imm_in     : in  wordx;
                           valid_out  : out std_ulogic;
                           branch_out : out std_ulogic;
                           taken_out  : out std_ulogic;
                           hit_out    : out std_ulogic;
                           xc_out     : out std_ulogic;
                           cause_out  : out cause_type;
                           next_out   : out std_logic_vector;     -- pctype
                           addr_out   : out std_logic_vector) is  -- pctype
    subtype pctype is std_logic_vector(pc_in'range);
    -- Non-constant
    variable valid    : std_ulogic := '0';
    variable xc       : std_ulogic := '0';
    variable pc       : wordx;
    variable target   : wordx;
    variable nextpc   : pctype;
    variable brancho  : std_ulogic;
  begin
    -- Signal to branch in decode stage in case we got a taken from bht
    -- but the btb does not have the target address where to branch.
    brancho    := taken_in and not hit_in;

    -- Check if branch
    if valid_in = '1' and xc_in = '0' and v_fusel_eq(fusel_in, BRANCH) then
      valid    := '1';
    end if;

    -- Operations:
    -- * BRANCH -> pc + sign_extend(imm)
    pc         := pc2xlen(pc_in);
    target     := std_logic_vector(signed(pc) + signed(imm_in));
    nextpc     := npc_adder(pc_in, comp_in);

    -- Generate Exception Signal
    if valid = '1' and taken_in = '1' and
       inst_addr_misaligned(active, target) then
      xc       := '1';
    end if;

    -- Generate Output
    addr_out   := to_addr(target, addr_out'length);
    next_out   := nextpc;
    valid_out  := valid;
    branch_out := brancho and valid;
    -- Taken signal for later stage of the pipeline
    taken_out  := taken_in and valid;
    xc_out     := xc;
    cause_out  := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    hit_out    := hit_in;
  end;

  procedure branch_misc(active    : in  extension_type;
                        fusel_in  : in  fuseltype;
                        valid_in  : in  std_ulogic;
                        xc_in     : in  std_ulogic;
                        pc_in     : in  std_logic_vector;     -- pctype
                        comp_in   : in  std_ulogic;
                        taken_in  : in  std_ulogic;
                        hit_in    : in  std_ulogic;
                        imm_in    : in  wordx_arr;            -- wordx_pair_type
                        swap      : in  std_logic;
                        branch_lane : in  integer;
                        valid_out : out std_ulogic;
                        taken_out : out std_ulogic;
                        hit_out   : out std_ulogic;
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        next_out  : out std_logic_vector;     -- pctype
                        addr_out  : out std_logic_vector) is  -- pctype
    subtype pctype is std_logic_vector(pc_in'range);
    -- Non-constant
    variable valid     : std_ulogic := '0';
    variable xc        : std_ulogic := '0';
    variable pc        : wordx;
    variable target_l0 : wordx;
    variable target_l1 : wordx;
    variable target    : wordx;
    variable nextpc    : pctype;
  begin
    -- Check if branch
    if valid_in = '1' and xc_in = '0' and v_fusel_eq(fusel_in, BRANCH) then
      valid    := '1';
    end if;

    -- Operations:
    -- * BRANCH -> pc + sign_extend(imm)
    pc         := pc2xlen(pc_in);

    target_l0  := std_logic_vector(signed(pc) + signed(imm_in(0)));
    target_l1  := std_logic_vector(signed(pc) + signed(imm_in(1)));

    if branch_lane = 0 then
      target   := target_l0;
      if swap = '1' then
        target := target_l1;
      end if;
    else
      target   := target_l1;
      if swap = '1' then
        target := target_l0;
      end if;
    end if;

    nextpc := npc_adder(pc_in, comp_in);

    -- Generate Exception Signal
    if valid = '1' and taken_in = '1' and
       inst_addr_misaligned(active, target) then
      xc       := '1';
    end if;

    -- Generate Output
    addr_out   := to_addr(target, addr_out'length);
    next_out   := nextpc;
    valid_out  := valid;
    taken_out  := taken_in and valid;
    xc_out     := xc;
    cause_out  := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    hit_out    := hit_in;
  end;

  -- RAS Update Procedure
  procedure ras_update(speculative_in : in  integer;
                       inst_in        : in  word;
                       fusel_in       : in  fuseltype;
                       valid_in       : in  std_ulogic;
                       xc_in          : in  std_ulogic;
                       rdv_in         : in  std_ulogic;
                       wdata_in       : in  std_logic_vector;  -- pctype
                       rasi_in        : in  nv_ras_in_type;
                       hold_in        : in  std_ulogic;
                       rstate         : in  core_state;
                       ras_out        : out nv_ras_in_type) is
    variable rd       : reg_t          := rd(inst_in);
    variable rs1      : reg_t          := rs1(inst_in);
    -- Non-constant
    variable ras      : nv_ras_in_type := nv_ras_in_none;
  begin
    -- Return-address prediction stacks are a common feature of high-performance instruction-fetch
    -- units, but require accurate detection of instructions used for procedure calls and returns
    -- to be effective. For RISC-V, hints as to the instructions’ usage are encoded implicitly via
    -- the register numbers used. A JAL instruction should push the return address onto a
    -- return-address stack (RAS) only when rd=x1/x5. JALR instructions should push/pop a RAS
    -- as shown in the Table 2.1.

    -- *       *       *          *              *
    -- |   rd  |  rs1  |  rs1=rd  |  RAS Action  |
    -- ------------------------------------------
    -- | !link | !link |     -    |     None     |
    -- | !link |  link |     -    |     Pop      |
    -- |  link | !link |     -    |     Push     |
    -- |  link |  link |     0    |  Pop, Push   |
    -- |  link |  link |     1    |     Push     |

    -- Update RAS on jal and jalr instruction.
    ras.wdata            := pc2xlen(wdata_in);

    if v_fusel_eq(fusel_in, FLOW) and speculative_in = 1 then
      if v_fusel_eq(fusel_in, JAL) then
        -- On JAL instruction we should request a push.
        if rdv_in = '1' and (rd = GPR_RA or rd = GPR_T0) then
          ras.push       := '1';
        end if;
      else -- JALR
        -- Please follow table above.
        case rs1 is
          when GPR_RA | GPR_T0 =>
            if rd = rs1 then
              ras.push   := '1';
            else
              ras.pop    := '1';
              if rdv_in = '1' and (rd = GPR_RA or rd = GPR_T0) then
                ras.push := '1';
              end if;
            end if;
          when others =>
            if rdv_in = '1' and (rd = GPR_RA or rd = GPR_T0) then
              ras.push   := '1';
            end if;
        end case; -- rs1
      end if;
    end if;

    -- Handle the speculative logic for RAS.
    -- In Decode Stage we update the RAS anyway.
    -- Then in Write Back Stage we check if that instruction
    -- is valid and reverse the operation in case it is not.

    if speculative_in = 1 then
      if valid_in = '0' or hold_in = '1' or xc_in = '1' then
        ras.push    := '0';
        ras.pop     := '0';
      end if;
    else
      if valid_in = '0' then
        if rasi_in.push = '1' then
          -- Reverse Push operation by issuing a pop
          ras.pop   := '1';
        elsif rasi_in.pop = '1' then
          -- Reverse Pop operation by issuing a push
          ras.push  := '1';
          ras.wdata := rasi_in.wdata;
        end if;
      end if;
    end if;

    -- For the write back ras update, hold_in encode the flush signal
    -- drived from the wb_fence_i instruction.
    if speculative_in = 0 then
      ras.flush     := hold_in;
    end if;

    if rstate /= run then
      ras.pop  := '0';
      ras.push := '0';
    end if;

    ras_out         := ras;
  end;

  -- RAS Resolve Logic
  procedure ras_resolve(active    : in  extension_type;
                        inst_in   : in  word;
                        fusel_in  : in  fuseltype;
                        valid_in  : in  std_ulogic;
                        xc_in     : in  std_ulogic;
                        rdv_in    : in  std_ulogic;
                        rs1_in    : in  reg_t;
                        ras_in    : in  nv_ras_out_type;
                        ras_out   : out nv_ras_out_type;
                        xc_out    : out std_ulogic;
                        cause_out : out cause_type;
                        tval_out  : out wordx) is
    variable rd       : reg_t           := rd(inst_in);
    variable tval     : wordx           := ras_in.rdata;
    -- Non-constant
    variable ras      : nv_ras_out_type := nv_ras_out_none;
    variable xc       : std_ulogic      := '0';
  begin
    -- Return-address prediction stacks are a common feature of high-performance instruction-fetch
    -- units, but require accurate detection of instructions used for procedure calls and returns
    -- to be effective. For RISC-V, hints as to the instructions’ usage are encoded implicitly via
    -- the register numbers used. A JAL instruction should push the return address onto a
    -- return-address stack (RAS) only when rd=x1/x5. JALR instructions should push/pop a RAS
    -- as shown in the Table 2.1.

    -- *       *       *          *              *
    -- |   rd  |  rs1  |  rs1=rd  |  RAS Action  |
    -- ------------------------------------------
    -- | !link | !link |     -    |     None     |
    -- | !link |  link |     -    |     Pop      |
    -- |  link | !link |     -    |     Push     |
    -- |  link |  link |     0    |  Pop, Push   |
    -- |  link |  link |     1    |     Push     |

    ras.rdata := ras_in.rdata;

    -- Evaluate if we have to get the value from the RAS.
    if valid_in = '1' and xc_in = '0' and v_fusel_eq(fusel_in, JALR) then
      if ras_in.hit = '1' then
        if rs1_in = GPR_T0 or rs1_in = GPR_RA then -- link registers
          if not (rdv_in = '1' and rd = rs1_in) then -- not if equal
            ras.hit := '1';
          end if;
        end if;
      end if;
    end if;

    -- Generate Exception
    if ras.hit = '1' and inst_addr_misaligned(active, ras_in.rdata) then
      xc      := '1';
    end if;

    ras_out   := ras;
    xc_out    := xc;
    cause_out := XC_INST_ADDR_MISALIGNED;  -- Only valid when xc_out.
    tval_out  := tval;
  end;

end;
