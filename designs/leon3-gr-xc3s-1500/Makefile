include .config

GRLIB=../..
TOP=leon3mp
BOARD=gr-xc3s-1500
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
#UCF=$(GRLIB)/boards/$(BOARD)/$(TOP).ucf
UCF=leon3mp.ucf
QSF=$(GRLIB)/boards/$(BOARD)/$(TOP).qsf
EFFORT=high
ISEMAPOPT=-timing
XSTOPT=
SYNPOPT="set_option -pipe 0; set_option -retiming 0; set_option -write_apr_constraint 0"
VHDLSYNFILES=config.vhd ahbrom.vhd vga_clkgen.vhd leon3mp.vhd
VHDLSIMFILES=testbench.vhd
SIMTOP=testbench
#SDCFILE=$(GRLIB)/boards/$(BOARD)/default.sdc
SDCFILE=default.sdc
BITGEN=$(GRLIB)/boards/$(BOARD)/default.ut
CLEAN=soft-clean
VCOMOPT=-explicit
TECHLIBS = unisim

LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip hynix cypress ihp gsi fmf spansion
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest ddr \
	leon4v0 l2cache/v2 l2cache/v3 l2cache/str gr1553b iommu ascs slink pwm \
	ge_1000baseX canfd \
	leon5v0 leon5v0/blockred grfpu5 noelv noelv/subsys riscv
FILESKIP = grcan.vhd adapters/sgmii.vhd \
	sf2apbslv_wrapper.vhd sf2ficmst_wrapper.vhd sf2ficslv_wrapper.vhd \
	sf2mddr_wrapper.vhd pfmddr_wrapper.vhd

include $(GRLIB)/bin/Makefile
include $(GRLIB)/software/leon3/Makefile


##################  project specific targets ##########################

