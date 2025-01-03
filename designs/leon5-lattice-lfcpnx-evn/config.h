/*
 * Automatically generated C config: don't edit
 */
#define AUTOCONF_INCLUDED
/*
 * Synthesis      
 */
#undef  CONFIG_SYN_INFERRED
#undef  CONFIG_SYN_AXCEL
#undef  CONFIG_SYN_AXDSP
#undef  CONFIG_SYN_FUSION
#undef  CONFIG_SYN_PROASIC
#undef  CONFIG_SYN_PROASICPLUS
#undef  CONFIG_SYN_PROASIC3
#undef  CONFIG_SYN_PROASIC3E
#undef  CONFIG_SYN_PROASIC3L
#undef  CONFIG_SYN_IGLOO
#undef  CONFIG_SYN_IGLOO2
#undef  CONFIG_SYN_SF2
#undef  CONFIG_SYN_RTG4
#undef  CONFIG_SYN_POLARFIRE
#undef  CONFIG_SYN_UT130HBD
#undef  CONFIG_SYN_UT90NHBD
#undef  CONFIG_SYN_CYCLONEIII
#undef  CONFIG_SYN_STRATIX
#undef  CONFIG_SYN_STRATIXII
#undef  CONFIG_SYN_STRATIXIII
#undef  CONFIG_SYN_STRATIXIV
#undef  CONFIG_SYN_STRATIXV
#undef  CONFIG_SYN_ALTERA
#undef  CONFIG_SYN_ATC18
#undef  CONFIG_SYN_ATC18RHA
#undef  CONFIG_SYN_CUSTOM1
#undef  CONFIG_SYN_DARE
#undef  CONFIG_SYN_CMOS9SF
#define CONFIG_SYN_NEXUS 1
#undef  CONFIG_SYN_BRAVEMED
#undef  CONFIG_SYN_ECLIPSE
#undef  CONFIG_SYN_RH_LIB18T
#undef  CONFIG_SYN_RHUMC
#undef  CONFIG_SYN_RHS65
#undef  CONFIG_SYN_SAED32
#undef  CONFIG_SYN_SMIC13
#undef  CONFIG_SYN_TM65GPLUS
#undef  CONFIG_SYN_TSMC90
#undef  CONFIG_SYN_UMC
#undef  CONFIG_SYN_ARTIX7
#undef  CONFIG_SYN_KINTEX7
#undef  CONFIG_SYN_KINTEXU
#undef  CONFIG_SYN_SPARTAN3
#undef  CONFIG_SYN_SPARTAN3E
#undef  CONFIG_SYN_SPARTAN6
#undef  CONFIG_SYN_VIRTEX2
#undef  CONFIG_SYN_VIRTEX4
#undef  CONFIG_SYN_VIRTEX5
#undef  CONFIG_SYN_VIRTEX6
#undef  CONFIG_SYN_VIRTEX7
#undef  CONFIG_SYN_ZYNQ7000
#undef  CONFIG_SYN_INFER_RAM
#undef  CONFIG_SYN_INFER_PADS
#undef  CONFIG_SYN_NO_ASYNC
#undef  CONFIG_SYN_SCAN
/*
 * LEON5 Processor system
 */
#define CONFIG_PROC_NUM (1)
#define CONFIG_FPU_NANOFPU 1
#undef  CONFIG_FPU_GRFPU5
#define CONFIG_LEON5_HP 1
#undef  CONFIG_LEON5_GP
#undef  CONFIG_LEON5_EP
#define CONFIG_LEON5_PERFCFG (0)
#define CONFIG_LEON5_RF_0 1
#undef  CONFIG_LEON5_RF_1
#define CONFIG_LEON5_RFCFG (0)
/*
 * Cache memory Configuration  
 */
#define CONFIG_LEON5_CMCFG_TAG (0)
#define CONFIG_LEON5_CMCFG_DATA (0)
/*
 * Tightly coupled memory      
 */
#define CONFIG_LEON5_ITCM_NONE 1
#undef  CONFIG_LEON5_ITCM_1K
#undef  CONFIG_LEON5_ITCM_2K
#undef  CONFIG_LEON5_ITCM_4K
#undef  CONFIG_LEON5_ITCM_8K
#undef  CONFIG_LEON5_ITCM_16K
#undef  CONFIG_LEON5_ITCM_32K
#undef  CONFIG_LEON5_ITCM_64K
#undef  CONFIG_LEON5_ITCM_128K
#undef  CONFIG_LEON5_ITCM_256K
#undef  CONFIG_LEON5_ITCM_512K
#undef  CONFIG_LEON5_ITCM_1M
#define CONFIG_LEON5_DTCM_NONE 1
#undef  CONFIG_LEON5_DTCM_1K
#undef  CONFIG_LEON5_DTCM_2K
#undef  CONFIG_LEON5_DTCM_4K
#undef  CONFIG_LEON5_DTCM_8K
#undef  CONFIG_LEON5_DTCM_16K
#undef  CONFIG_LEON5_DTCM_32K
#undef  CONFIG_LEON5_DTCM_64K
#undef  CONFIG_LEON5_DTCM_128K
#undef  CONFIG_LEON5_DTCM_256K
#undef  CONFIG_LEON5_DTCM_512K
#undef  CONFIG_LEON5_DTCM_1M
#define CONFIG_LEON5_ITCMCFG (0)
#define CONFIG_LEON5_DTCMCFG (0)
/*
 * Fault-tolerance  
 */
#define CONFIG_IUFT_NONE 1
#undef  CONFIG_IUFT_TECHSPEC
#undef  CONFIG_IUFT_RTL
#define CONFIG_CACHE_FT_NONE 1
#undef  CONFIG_CACHE_FT_TECHSPEC
#undef  CONFIG_CACHE_FT_RTL
#define CONFIG_LEON5_RF_FTCFG (0)
#define CONFIG_LEON5_CACHE_FTCFG (0)
#undef  CONFIG_AHB_32BIT
#undef  CONFIG_AHB_64BIT
#define CONFIG_AHB_128BIT 1
#define CONFIG_BWMASK 00FF
#define CONFIG_CACHE_FIXED 0
/*
 * Debug Link           
 */
#define CONFIG_DSU_UART 1
#undef  CONFIG_DSU_JTAG
/*
 * Peripherals             
 */
/*
 * AHB Status Register             
 */
#define CONFIG_AHBSTAT_ENABLE 1
#define CONFIG_AHBSTAT_NFTSLV (1)
/*
 * On-chip RAM/ROM                 
 */
#undef  CONFIG_AHBROM_ENABLE
#define CONFIG_AHBRAM_ENABLE 1
#undef  CONFIG_AHBRAM_SZ1
#undef  CONFIG_AHBRAM_SZ2
#undef  CONFIG_AHBRAM_SZ4
#undef  CONFIG_AHBRAM_SZ8
#undef  CONFIG_AHBRAM_SZ16
#undef  CONFIG_AHBRAM_SZ32
#undef  CONFIG_AHBRAM_SZ64
#define CONFIG_AHBRAM_SZ128 1
#undef  CONFIG_AHBRAM_SZ256
#undef  CONFIG_AHBRAM_SZ512
#undef  CONFIG_AHBRAM_SZ1024
#undef  CONFIG_AHBRAM_SZ2048
#undef  CONFIG_AHBRAM_SZ4096
#define CONFIG_AHBRAM_START 400
#undef  CONFIG_AHBRAM_PIPE
/*
 * GPIO
 */
#undef  CONFIG_GRGPIO_ENABLE
/*
 * VHDL Debugging        
 */
#undef  CONFIG_IU_DISAS
#undef  CONFIG_AHB_DTRACE
