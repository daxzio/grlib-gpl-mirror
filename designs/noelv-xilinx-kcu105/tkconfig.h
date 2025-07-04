#if defined CONFIG_SYN_INFERRED
#define CONFIG_SYN_TECH inferred
#elif defined CONFIG_SYN_UMC
#define CONFIG_SYN_TECH umc
#elif defined CONFIG_SYN_RHUMC
#define CONFIG_SYN_TECH rhumc
#elif defined CONFIG_SYN_DARE
#define CONFIG_SYN_TECH dare
#elif defined CONFIG_SYN_SAED32
#define CONFIG_SYN_TECH saed32
#elif defined CONFIG_SYN_RHS65
#define CONFIG_SYN_TECH rhs65
#elif defined CONFIG_SYN_ATC18
#define CONFIG_SYN_TECH atc18s
#elif defined CONFIG_SYN_ATC18RHA
#define CONFIG_SYN_TECH atc18rha
#elif defined CONFIG_SYN_AXCEL
#define CONFIG_SYN_TECH axcel
#elif defined CONFIG_SYN_AXDSP
#define CONFIG_SYN_TECH axdsp
#elif defined CONFIG_SYN_PROASICPLUS
#define CONFIG_SYN_TECH proasic
#elif defined CONFIG_SYN_ALTERA
#define CONFIG_SYN_TECH altera
#elif defined CONFIG_SYN_STRATIX
#define CONFIG_SYN_TECH stratix1
#elif defined CONFIG_SYN_STRATIXII
#define CONFIG_SYN_TECH stratix2
#elif defined CONFIG_SYN_STRATIXIII
#define CONFIG_SYN_TECH stratix3
#elif defined CONFIG_SYN_STRATIXIV
#define CONFIG_SYN_TECH stratix4
#elif defined CONFIG_SYN_STRATIXV
#define CONFIG_SYN_TECH stratix5
#elif defined CONFIG_SYN_CYCLONEII
#define CONFIG_SYN_TECH stratix2
#elif defined CONFIG_SYN_CYCLONEIII
#define CONFIG_SYN_TECH cyclone3
#elif defined CONFIG_SYN_CYCLONEIV
#define CONFIG_SYN_TECH cyclone3
#elif defined CONFIG_SYN_IHP25
#define CONFIG_SYN_TECH ihp25
#elif defined CONFIG_SYN_IHP25RH
#define CONFIG_SYN_TECH ihp25rh
#elif defined CONFIG_SYN_NEXUS
#define CONFIG_SYN_TECH nexus
#elif defined CONFIG_SYN_BRAVEMED
#define CONFIG_SYN_TECH nx
#elif defined CONFIG_SYN_ECLIPSE
#define CONFIG_SYN_TECH eclipse
#elif defined CONFIG_SYN_PEREGRINE
#define CONFIG_SYN_TECH peregrine
#elif defined CONFIG_SYN_PROASIC
#define CONFIG_SYN_TECH proasic
#elif defined CONFIG_SYN_PROASIC3
#define CONFIG_SYN_TECH apa3
#elif defined CONFIG_SYN_PROASIC3E
#define CONFIG_SYN_TECH apa3e
#elif defined CONFIG_SYN_PROASIC3L
#define CONFIG_SYN_TECH apa3l
#elif defined CONFIG_SYN_IGLOO
#define CONFIG_SYN_TECH apa3
#elif defined CONFIG_SYN_IGLOO2
#define CONFIG_SYN_TECH igloo2
#elif defined CONFIG_SYN_SF2
#define CONFIG_SYN_TECH smartfusion2
#elif defined CONFIG_SYN_RTG4
#define CONFIG_SYN_TECH rtg4
#elif defined CONFIG_SYN_POLARFIRE
#define CONFIG_SYN_TECH polarfire
#elif defined CONFIG_SYN_FUSION
#define CONFIG_SYN_TECH actfus
#elif defined CONFIG_SYN_SPARTAN2
#define CONFIG_SYN_TECH virtex
#elif defined CONFIG_SYN_VIRTEX
#define CONFIG_SYN_TECH virtex
#elif defined CONFIG_SYN_VIRTEXE
#define CONFIG_SYN_TECH virtex
#elif defined CONFIG_SYN_SPARTAN3
#define CONFIG_SYN_TECH spartan3
#elif defined CONFIG_SYN_SPARTAN3E
#define CONFIG_SYN_TECH spartan3e
#elif defined CONFIG_SYN_SPARTAN6
#define CONFIG_SYN_TECH spartan6
#elif defined CONFIG_SYN_VIRTEX2
#define CONFIG_SYN_TECH virtex2
#elif defined CONFIG_SYN_VIRTEX4
#define CONFIG_SYN_TECH virtex4
#elif defined CONFIG_SYN_VIRTEX5
#define CONFIG_SYN_TECH virtex5
#elif defined CONFIG_SYN_VIRTEX6
#define CONFIG_SYN_TECH virtex6
#elif defined CONFIG_SYN_VIRTEX7
#define CONFIG_SYN_TECH virtex7
#elif defined CONFIG_SYN_KINTEX7
#define CONFIG_SYN_TECH kintex7
#elif defined CONFIG_SYN_KINTEXU
#define CONFIG_SYN_TECH kintexu
#elif defined CONFIG_SYN_ARTIX7
#define CONFIG_SYN_TECH artix7
#elif defined CONFIG_SYN_ZYNQ7000
#define CONFIG_SYN_TECH zynq7000
#elif defined CONFIG_SYN_ARTIX77
#define CONFIG_SYN_TECH artix7
#elif defined CONFIG_SYN_ZYNQ7000
#define CONFIG_SYN_TECH zynq7000
#elif defined CONFIG_SYN_RH_LIB18T
#define CONFIG_SYN_TECH rhlib18t
#elif defined CONFIG_SYN_SMIC13
#define CONFIG_SYN_TECH smic013
#elif defined CONFIG_SYN_UT025CRH
#define CONFIG_SYN_TECH ut25
#elif defined CONFIG_SYN_UT130HBD
#define CONFIG_SYN_TECH ut130
#elif defined CONFIG_SYN_UT90NHBD
#define CONFIG_SYN_TECH ut90
#elif defined CONFIG_SYN_TSMC90
#define CONFIG_SYN_TECH tsmc90
#elif defined CONFIG_SYN_TM65GPLUS
#define CONFIG_SYN_TECH tm65gplus
#elif defined CONFIG_SYN_CUSTOM1
#define CONFIG_SYN_TECH custom1
#else
#error "unknown target technology"
#endif

#if defined CONFIG_SYN_INFER_RAM
#define CFG_RAM_TECH inferred
#elif defined CONFIG_MEM_UMC
#define CFG_RAM_TECH umc
#elif defined CONFIG_MEM_RHUMC
#define CFG_RAM_TECH rhumc
#elif defined CONFIG_MEM_DARE
#define CFG_RAM_TECH dare
#elif defined CONFIG_MEM_SAED32
#define CFG_RAM_TECH saed32
#elif defined CONFIG_MEM_RHS65
#define CFG_RAM_TECH rhs65
#elif defined CONFIG_MEM_VIRAGE
#define CFG_RAM_TECH memvirage
#elif defined CONFIG_MEM_ARTISAN
#define CFG_RAM_TECH memartisan
#elif defined CONFIG_MEM_CUSTOM1
#define CFG_RAM_TECH custom1
#elif defined CONFIG_MEM_VIRAGE90
#define CFG_RAM_TECH memvirage90
#elif defined CONFIG_MEM_INFERRED
#define CFG_RAM_TECH inferred
#else
#define CFG_RAM_TECH CONFIG_SYN_TECH
#endif

#if defined CONFIG_TRANS_GTP0
#define CFG_TRANS_TECH TT_XGTP0
#elif defined CONFIG_TRANS_GTP1
#define CFG_TRANS_TECH TT_XGTP1
#elif defined CONFIG_TRANS_GTX0
#define CFG_TRANS_TECH TT_XGTX0
#elif defined CONFIG_TRANS_GTX1
#define CFG_TRANS_TECH TT_XGTX1
#elif defined CONFIG_TRANS_GTH0
#define CFG_TRANS_TECH TT_XGTH0
#elif defined CONFIG_TRANS_GTH1
#define CFG_TRANS_TECH TT_XGTH1
#else
#define CFG_TRANS_TECH TT_XGTP0
#endif

#if defined CONFIG_SYN_INFER_PADS
#define CFG_PAD_TECH inferred
#else
#define CFG_PAD_TECH CONFIG_SYN_TECH
#endif

#ifndef CONFIG_SYN_NO_ASYNC
#define CONFIG_SYN_NO_ASYNC 0
#endif

#ifndef CONFIG_SYN_SCAN
#define CONFIG_SYN_SCAN 0
#endif


#if defined CONFIG_CLK_ALTDLL
#define CFG_CLK_TECH CONFIG_SYN_TECH
#elif defined CONFIG_CLK_HCLKBUF
#define CFG_CLK_TECH axcel
#elif defined CONFIG_CLK_BRAVEMED
#define CFG_CLK_TECH nx
#elif defined CONFIG_CLK_PRO3PLL
#define CFG_CLK_TECH apa3
#elif defined CONFIG_CLK_PRO3EPLL
#define CFG_CLK_TECH apa3e
#elif defined CONFIG_CLK_PRO3LPLL
#define CFG_CLK_TECH apa3l
#elif defined CONFIG_CLK_FUSPLL
#define CFG_CLK_TECH actfus
#elif defined CONFIG_CLK_CLKDLL
#define CFG_CLK_TECH virtex
#elif defined CONFIG_CLK_CLKPLLE2
#define CFG_CLK_TECH CONFIG_SYN_TECH
#elif defined CONFIG_CLK_DCM
#define CFG_CLK_TECH CONFIG_SYN_TECH
#elif defined CONFIG_CLK_LIB18T
#define CFG_CLK_TECH rhlib18t
#elif defined CONFIG_CLK_RHUMC
#define CFG_CLK_TECH rhumc
#elif defined CONFIG_CLK_SAED32
#define CFG_CLK_TECH saed32
#elif defined CONFIG_CLK_RHS65
#define CFG_CLK_TECH rhs65
#elif defined CONFIG_CLK_DARE
#define CFG_CLK_TECH dare
#elif defined CONFIG_CLK_EASIC45
#define CFG_CLK_TECH easic45
#elif defined CONFIG_CLK_UT130HBD
#define CFG_CLK_TECH ut130
#else
#define CFG_CLK_TECH inferred
#endif

#ifndef CONFIG_CLK_MUL
#define CONFIG_CLK_MUL 2
#endif

#ifndef CONFIG_CLK_DIV
#define CONFIG_CLK_DIV 2
#endif

#ifndef CONFIG_OCLK_DIV
#define CONFIG_OCLK_DIV 1
#endif

#ifndef CONFIG_OCLKB_DIV
#define CONFIG_OCLKB_DIV 0
#endif

#ifndef CONFIG_OCLKC_DIV
#define CONFIG_OCLKC_DIV 0
#endif

#ifndef CONFIG_PCI_CLKDLL
#define CONFIG_PCI_CLKDLL 0
#endif

#ifndef CONFIG_PCI_SYSCLK
#define CONFIG_PCI_SYSCLK 0
#endif

#ifndef CONFIG_CLK_NOFB
#define CONFIG_CLK_NOFB 0
#endif
#ifndef CONFIG_NOELV
#define CONFIG_NOELV 0
#endif

#ifndef CONFIG_NOELV_XLEN
#define CONFIG_NOELV_XLEN 64
#endif

#ifndef CONFIG_PROC_NUM
#define CONFIG_PROC_NUM 1
#endif

#ifndef CONFIG_PROC_TYP
#define CONFIG_PROC_TYP 4
#endif

#ifndef CONFIG_PROC_LITE
#define CONFIG_PROC_LITE 0
#endif

#ifndef CONFIG_PROC_S
#define CONFIG_PROC_S 0
#endif

#ifndef CONFIG_PROC_NOFPU
#define CONFIG_PROC_NOFPU 0
#endif

#ifndef CONFIG_PROC_NODBUS
#define CONFIG_PROC_NODBUS 0
#endif

#ifndef CONFIG_IU_DISAS
#define CONFIG_IU_DISAS 0
#endif

#ifndef CONFIG_DOMAINS_NUM
#define CONFIG_DOMAINS_NUM 4
#endif

#ifndef CONFIG_EIID_NUM
#define CONFIG_EIID_NUM 63
#endif
#ifndef CONFIG_L2_ENABLE
#define CONFIG_L2_ENABLE 0
#endif

#ifndef CONFIG_L2_LITE
#define CONFIG_L2_LITE 0
#endif

#if defined CONFIG_L2_ASSO1
#define CFG_L2_ASSO 1
#elif defined CONFIG_L2_ASSO2
#define CFG_L2_ASSO 2
#elif defined CONFIG_L2_ASSO3
#define CFG_L2_ASSO 3
#elif defined CONFIG_L2_ASSO4
#define CFG_L2_ASSO 4
#else
#define CFG_L2_ASSO 1
#endif

#if defined CONFIG_L2_SZ1
#define CFG_L2_SZ 1
#elif defined CONFIG_L2_SZ2
#define CFG_L2_SZ 2
#elif defined CONFIG_L2_SZ4
#define CFG_L2_SZ 4
#elif defined CONFIG_L2_SZ8
#define CFG_L2_SZ 8
#elif defined CONFIG_L2_SZ16
#define CFG_L2_SZ 16
#elif defined CONFIG_L2_SZ32
#define CFG_L2_SZ 32
#elif defined CONFIG_L2_SZ64
#define CFG_L2_SZ 64
#elif defined CONFIG_L2_SZ128
#define CFG_L2_SZ 128
#elif defined CONFIG_L2_SZ256
#define CFG_L2_SZ 256
#elif defined CONFIG_L2_SZ512
#define CFG_L2_SZ 512
#else
#define CFG_L2_SZ 1
#endif

#if defined CONFIG_L2_LINE64
#define CFG_L2_LINE 64
#else
#define CFG_L2_LINE 32
#endif

#ifndef CONFIG_L2_HPROT
#define CONFIG_L2_HPROT 0
#endif

#ifndef CONFIG_L2_PEN
#define CONFIG_L2_PEN 0
#endif

#ifndef CONFIG_L2_WT
#define CONFIG_L2_WT 0
#endif

#ifndef CONFIG_L2_RAN
#define CONFIG_L2_RAN 0
#endif
#ifndef CONFIG_L2_MAP
#define CONFIG_L2_MAP 00F0
#endif

#ifndef CONFIG_L2_SHARE
#define CONFIG_L2_SHARE 0
#endif

#ifndef CONFIG_L2_MTRR
#define CONFIG_L2_MTRR 0
#endif

#if defined CONFIG_L2_EDAC_NONE
#define CONFIG_L2_EDAC 0
#elif defined CONFIG_L2_EDAC_YES
#define CONFIG_L2_EDAC 1
#elif defined CONFIG_L2_EDAC_TECHSPEC
#define CONFIG_L2_EDAC 2
#else
#define CONFIG_L2_EDAC 0
#endif

#ifndef CONFIG_L2_AXI
#define CONFIG_L2_AXI 0
#endif
#ifndef CONFIG_AHB_SPLIT
#define CONFIG_AHB_SPLIT 0
#endif

#ifndef CONFIG_AHB_RROBIN
#define CONFIG_AHB_RROBIN 0
#endif

#ifndef CONFIG_AHB_FPNPEN
#define CONFIG_AHB_FPNPEN 0
#endif

#ifndef CONFIG_AHB_IOADDR
#define CONFIG_AHB_IOADDR FFF
#endif

#ifndef CONFIG_APB_HADDR
#define CONFIG_APB_HADDR 800
#endif

#ifndef CONFIG_AHB_MON
#define CONFIG_AHB_MON 0
#endif

#ifndef CONFIG_AHB_MONERR
#define CONFIG_AHB_MONERR 0
#endif

#ifndef CONFIG_AHB_MONWAR
#define CONFIG_AHB_MONWAR 0
#endif

#ifndef CONFIG_AHB_DTRACE
#define CONFIG_AHB_DTRACE 0
#endif

#ifndef CONFIG_DSU_UART
#define CONFIG_DSU_UART 0
#endif


#ifndef CONFIG_DSU_JTAG
#define CONFIG_DSU_JTAG 0
#endif

#ifndef CONFIG_DSU_ETH
#define CONFIG_DSU_ETH 0
#endif

#ifndef CONFIG_DSU_IPMSB
#define CONFIG_DSU_IPMSB C0A8
#endif

#ifndef CONFIG_DSU_IPLSB
#define CONFIG_DSU_IPLSB 0033
#endif

#ifndef CONFIG_DSU_ETHMSB
#define CONFIG_DSU_ETHMSB 020000
#endif

#ifndef CONFIG_DSU_ETHLSB
#define CONFIG_DSU_ETHLSB 000009
#endif

#if defined CONFIG_DSU_ETHSZ1
#define CFG_DSU_ETHB 1
#elif CONFIG_DSU_ETHSZ2
#define CFG_DSU_ETHB 2
#elif CONFIG_DSU_ETHSZ4
#define CFG_DSU_ETHB 4
#elif CONFIG_DSU_ETHSZ8
#define CFG_DSU_ETHB 8
#elif CONFIG_DSU_ETHSZ16
#define CFG_DSU_ETHB 16
#elif CONFIG_DSU_ETHSZ32
#define CFG_DSU_ETHB 32
#else
#define CFG_DSU_ETHB 1
#endif

#ifndef CONFIG_DSU_ETH_PROG
#define CONFIG_DSU_ETH_PROG 0
#endif

#ifndef CONFIG_DSU_ETH_DIS
#define CONFIG_DSU_ETH_DIS 0
#endif


#ifndef CONFIG_MIG_7SERIES
#define CONFIG_MIG_7SERIES 0
#endif
#ifndef CONFIG_MIG_7SERIES_MODEL
#define CONFIG_MIG_7SERIES_MODEL 0
#endif
#ifndef CONFIG_AHBSTAT_ENABLE
#define CONFIG_AHBSTAT_ENABLE  0
#endif

#ifndef CONFIG_AHBSTAT_NFTSLV
#define CONFIG_AHBSTAT_NFTSLV  1
#endif

#ifndef CONFIG_NANDFCTRL2_ENABLE
#define CONFIG_NANDFCTRL2_ENABLE 0
#endif

#ifndef CONFIG_NFC2_NROFCE
#define CONFIG_NFC2_NROFCE 0
#endif

#ifndef CONFIG_NFC2_NROFCH
#define CONFIG_NFC2_NROFCH 0
#endif

#ifndef CONFIG_NFC2_NROFRB
#define CONFIG_NFC2_NROFRB 0
#endif

#ifndef CONFIG_NFC2_NROFSEFI
#define CONFIG_NFC2_NROFSEFI 0
#endif

#ifndef CONFIG_NFC2_RND
#define CONFIG_NFC2_RND 0
#endif

#ifndef CONFIG_NFC2_MEM0_DATA
#define CONFIG_NFC2_MEM0_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM0_SPARE
#define CONFIG_NFC2_MEM0_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM0_ECC_SEL
#define CONFIG_NFC2_MEM0_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_MEM1_DATA
#define CONFIG_NFC2_MEM1_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM1_SPARE
#define CONFIG_NFC2_MEM1_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM1_ECC_SEL
#define CONFIG_NFC2_MEM1_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_MEM2_DATA
#define CONFIG_NFC2_MEM2_DATA 0
#endif

#ifndef CONFIG_NFC2_MEM2_SPARE
#define CONFIG_NFC2_MEM2_SPARE 0
#endif

#ifndef CONFIG_NFC2_MEM2_ECC_SEL
#define CONFIG_NFC2_MEM2_ECC_SEL 0
#endif

#ifndef CONFIG_NFC2_ECC0_GFSIZE
#define CONFIG_NFC2_ECC0_GFSIZE 0
#endif

#ifndef CONFIG_NFC2_ECC0_CHUNK
#define CONFIG_NFC2_ECC0_CHUNK 0
#endif

#ifndef CONFIG_NFC2_ECC0_CAP
#define CONFIG_NFC2_ECC0_CAP 0
#endif

#ifndef CONFIG_NFC2_ECC1_GFSIZE
#define CONFIG_NFC2_ECC1_GFSIZE 0
#endif

#ifndef CONFIG_NFC2_ECC1_CHUNK
#define CONFIG_NFC2_ECC1_CHUNK 0
#endif

#ifndef CONFIG_NFC2_ECC1_CAP
#define CONFIG_NFC2_ECC1_CAP 0
#endif

#ifndef CONFIG_NFC2_RST_CYCLES
#define CONFIG_NFC2_RST_CYCLES 10
#endif

#ifndef CONFIG_NFC2_TAG_SIZE
#define CONFIG_NFC2_TAG_SIZE 0
#endif

#if defined CONFIG_NFC2_FT_DMR
#define CONFIG_NFC2_FT 1
#elif defined CONFIG_NFC2_FT_TMR
#define CONFIG_NFC2_FT 2
#elif defined CONFIG_NFC2_FT_BCH
#define CONFIG_NFC2_FT 4
#elif defined CONFIG_NFC2_FT_TECHSPEC
#define CONFIG_NFC2_FT 5
#else
#define CONFIG_NFC2_FT 0
#endif
#ifndef CONFIG_GRETH_ENABLE
#define CONFIG_GRETH_ENABLE 0
#endif

#ifndef CONFIG_GRETH_GIGA
#define CONFIG_GRETH_GIGA 0
#endif

#if defined CONFIG_GRETH_FIFO4
#define CFG_GRETH_FIFO 4
#elif defined CONFIG_GRETH_FIFO8
#define CFG_GRETH_FIFO 8
#elif defined CONFIG_GRETH_FIFO16
#define CFG_GRETH_FIFO 16
#elif defined CONFIG_GRETH_FIFO32
#define CFG_GRETH_FIFO 32
#elif defined CONFIG_GRETH_FIFO64
#define CFG_GRETH_FIFO 64
#else
#define CFG_GRETH_FIFO 8
#endif

#ifndef CONFIG_GRETH_FT
#define CONFIG_GRETH_FT 0
#endif

#ifndef CONFIG_GRETH_EDCLFT
#define CONFIG_GRETH_EDCLFT 0
#endif

#ifndef CONFIG_GRETH_SGMII_MODE
#define CONFIG_GRETH_SGMII_MODE 0
#endif

#ifndef CONFIG_GRETH_FMC_MODE
#define CONFIG_GRETH_FMC_MODE 0
#endif

#ifndef CONFIG_GRETH_PHY_ADDR
#define CONFIG_GRETH_PHY_ADDR 1
#endif

#ifndef CONFIG_GRGPIO_ENABLE
#define CONFIG_GRGPIO_ENABLE 0
#endif
#ifndef CONFIG_GRGPIO_IMASK
#define CONFIG_GRGPIO_IMASK 0000
#endif
#ifndef CONFIG_GRGPIO_WIDTH
#define CONFIG_GRGPIO_WIDTH 1
#endif

#ifndef CONFIG_SPWRTR_ENABLE
#define CONFIG_SPWRTR_ENABLE 0
#endif

#if defined CONFIG_SPWRTR_RX_SDR
#define CONFIG_SPWRTR_INPUT 2
#elif defined CONFIG_SPWRTR_RX_DDR
#define CONFIG_SPWRTR_INPUT 3
#elif defined CONFIG_SPWRTR_RX_XOR
#define CONFIG_SPWRTR_INPUT 0
#elif defined CONFIG_SPWRTR_RX_XORER1
#define CONFIG_SPWRTR_INPUT 5
#elif defined CONFIG_SPWRTR_RX_XORER2
#define CONFIG_SPWRTR_INPUT 6
#elif defined CONFIG_SPWRTR_RX_AFLEX
#define CONFIG_SPWRTR_INPUT 1
#else
#define CONFIG_SPWRTR_INPUT 2
#endif

#if defined CONFIG_SPWRTR_TX_SDR
#define CONFIG_SPWRTR_OUTPUT 0
#elif defined CONFIG_SPWRTR_TX_DDR
#define CONFIG_SPWRTR_OUTPUT 1
#elif defined CONFIG_SPWRTR_TX_AFLEX
#define CONFIG_SPWRTR_OUTPUT 2
#else
#define CONFIG_SPWRTR_OUTPUT 0
#endif

#ifndef CONFIG_SPWRTR_RTSAME
#define CONFIG_SPWRTR_RTSAME 0
#endif

#if defined CONFIG_SPWRTR_RXFIFO16
#define CONFIG_SPWRTR_RXFIFO 16
#elif defined CONFIG_SPWRTR_RXFIFO32
#define CONFIG_SPWRTR_RXFIFO 32
#elif defined CONFIG_SPWRTR_RXFIFO64
#define CONFIG_SPWRTR_RXFIFO 64
#elif defined CONFIG_SPWRTR_RXFIFO128
#define CONFIG_SPWRTR_RXFIFO 128
#elif defined CONFIG_SPWRTR_RXFIFO256
#define CONFIG_SPWRTR_RXFIFO 256
#elif defined CONFIG_SPWRTR_RXFIFO512
#define CONFIG_SPWRTR_RXFIFO 512
#elif defined CONFIG_SPWRTR_RXFIFO1024
#define CONFIG_SPWRTR_RXFIFO 1024
#elif defined CONFIG_SPWRTR_RXFIFO2048
#define CONFIG_SPWRTR_RXFIFO 2048
#else
#define CONFIG_SPWRTR_RXFIFO 64
#endif

#ifndef CONFIG_SPWRTR_TECHFIFO
#define CONFIG_SPWRTR_TECHFIFO 1
#endif


#if defined CONFIG_SPWRTR_FT_NOFT
#define CONFIG_SPWRTR_FT 0
#elif defined CONFIG_SPWRTR_FT_PAR
#define CONFIG_SPWRTR_FT 1
#elif defined CONFIG_SPWRTR_FT_TMR
#define CONFIG_SPWRTR_FT 2
#else
#define CONFIG_SPWRTR_FT 0
#endif

#ifndef CONFIG_SPWRTR_SPWEN
#define CONFIG_SPWRTR_SPWEN 0
#endif

#ifndef CONFIG_SPWRTR_AMBAEN
#define CONFIG_SPWRTR_AMBAEN 0
#endif

#ifndef CONFIG_SPWRTR_FIFOEN
#define CONFIG_SPWRTR_FIFOEN 0
#endif

#ifndef CONFIG_SPWRTR_SPWPORTS
#define CONFIG_SPWRTR_SPWPORTS 2
#endif

#ifndef CONFIG_SPWRTR_AMBAPORTS
#define CONFIG_SPWRTR_AMBAPORTS 0
#endif

#ifndef CONFIG_SPWRTR_FIFOPORTS
#define CONFIG_SPWRTR_FIFOPORTS 0
#endif

#if defined CONFIG_SPWRTR_ARB_RR
#define CONFIG_SPWRTR_ARB 0
#else
#define CONFIG_SPWRTR_ARB 0
#endif

#ifndef CONFIG_SPWRTR_RMAP
#define CONFIG_SPWRTR_RMAP 0
#endif

#ifndef CONFIG_SPWRTR_RMAPCRC
#define CONFIG_SPWRTR_RMAPCRC 0
#endif

#if defined CONFIG_SPWRTR_FIFO2_4
#define CONFIG_SPWRTR_FIFO2 4
#elif defined CONFIG_SPWRTR_FIFO2_8
#define CONFIG_SPWRTR_FIFO2 8
#elif defined CONFIG_SPWRTR_FIFO2_16
#define CONFIG_SPWRTR_FIFO2 16
#elif defined CONFIG_SPWRTR_FIFO2_32
#define CONFIG_SPWRTR_FIFO2 32
#else
#define CONFIG_SPWRTR_FIFO2 4
#endif

#ifndef CONFIG_SPWRTR_ALMOST
#define CONFIG_SPWRTR_ALMOST 8
#endif

#ifndef CONFIG_SPWRTR_RXUNAL
#define CONFIG_SPWRTR_RXUNAL 0
#endif

#if defined CONFIG_SPWRTR_RMAPBUF2
#define CONFIG_SPWRTR_RMAPBUF 2
#elif defined CONFIG_SPWRTR_RMAPBUF4
#define CONFIG_SPWRTR_RMAPBUF 4
#elif defined CONFIG_SPWRTR_RMAPBUF6
#define CONFIG_SPWRTR_RMAPBUF 6
#elif defined CONFIG_SPWRTR_RMAPBUF8
#define CONFIG_SPWRTR_RMAPBUF 8
#else
#define CONFIG_SPWRTR_RMAPBUF 4
#endif

#ifndef CONFIG_SPWRTR_DMACHAN
#define CONFIG_SPWRTR_DMACHAN 1
#endif

#ifndef CONFIG_SPWRTR_AHBSLVEN
#define CONFIG_SPWRTR_AHBSLVEN 1
#endif

#ifndef CONFIG_SPWRTR_TIMERBITS
#define CONFIG_SPWRTR_TIMERBITS 0
#endif

#ifndef CONFIG_SPWRTR_PNP
#define CONFIG_SPWRTR_PNP 1
#endif

#ifndef CONFIG_SPWRTR_AUTOSCRUB
#define CONFIG_SPWRTR_AUTOSCRUB 1
#endif


#ifndef CONFIG_GRCANFD_ENABLE
#define CONFIG_GRCANFD_ENABLE 0
#endif

#ifndef CONFIG_GRCANFDIRQ
#define CONFIG_GRCANFDIRQ 0
#endif

#ifndef CONFIG_GRCANFDSINGLE
#define CONFIG_GRCANFDSINGLE 0
#endif
#ifndef CONFIG_GRHSSL_ENABLE
#define CONFIG_GRHSSL_ENABLE 0
#endif

#ifndef CONFIG_GRHSSL_NUM
#define CONFIG_GRHSSL_NUM 1
#endif

#ifndef CONFIG_GRHSSL_SPFI
#define CONFIG_GRHSSL_SPFI 1
#endif

#ifndef CONFIG_GRHSSL_WIZL
#define CONFIG_GRHSSL_WIZL 0
#endif

#ifndef CONFIG_DEBUG_UART
#define CONFIG_DEBUG_UART 0
#endif
