include .config
GRLIB=../..
TOP=leon3mp
BOARD=ztex-ufm-115
DESIGN=leon3-ztex-ufm-115
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
UCF=$(TOP).ucf
UCF_PLANAHEAD=$(UCF)
QSF=$(GRLIB)/boards/$(BOARD)/$(TOP).qsf
EFFORT=high
XSTOPT=-uc leon3mp.xcf
SYNPOPT="set_option -pipe 1; set_option -retiming 1; set_option -write_apr_constraint 0"
# Set ZTEX variable to SDK directory in your shell
# or modify the variable below:
#ZTEX=~/ztex/ztex

VHDLOPTSYNFILES = \
	mig37/mig_37/user_design/rtl/iodrp_controller.vhd \
	mig37/mig_37/user_design/rtl/iodrp_mcb_controller.vhd \
	mig37/mig_37/user_design/rtl/mcb_raw_wrapper.vhd \
	mig37/mig_37/user_design/rtl/mcb_soft_calibration.vhd \
	mig37/mig_37/user_design/rtl/mcb_soft_calibration_top.vhd \
	mig37/mig_37/user_design/rtl/memc3_infrastructure.vhd \
	mig37/mig_37/user_design/rtl/memc3_wrapper.vhd \
	mig37/mig_37/user_design/rtl/mig_37.vhd \
	mig39/mig_39/user_design/rtl/iodrp_controller.vhd \
	mig39/mig_39/user_design/rtl/iodrp_mcb_controller.vhd \
	mig39/mig_39/user_design/rtl/mcb_raw_wrapper.vhd \
	mig39/mig_39/user_design/rtl/mcb_soft_calibration.vhd \
	mig39/mig_39/user_design/rtl/mcb_soft_calibration_top.vhd \
	mig39/mig_39/user_design/rtl/memc3_infrastructure.vhd \
	mig39/mig_39/user_design/rtl/memc3_wrapper.vhd \
	mig39/mig_39/user_design/rtl/mig_39.vhd \
	config.vhd ahbrom.vhd ahb2mig_ztex.vhd leon3mp.vhd

VHDLSIMFILES=testbench.vhd

SIMTOP=testbench
SDCFILE=$(GRLIB)/boards/$(BOARD)/default.sdc
BITGEN=$(GRLIB)/boards/$(BOARD)/default.ut
CLEAN=soft-clean migclean

TECHLIBS = secureip unisim

LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip ihp usbhc spw
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
	usb grusbhc spacewire ascs slink hcan \
	leon4v0 l2cache pwm gr1553b iommu ge_1000baseX \
	leon5v0 leon5v0/blockred grfpu5 noelv noelv/subsys riscv
FILEADD = MCB.vhd
FILESKIP = grcan.vhd adapters/sgmii.vhd \
	sf2apbslv_wrapper.vhd sf2ficmst_wrapper.vhd sf2ficslv_wrapper.vhd \
	sf2mddr_wrapper.vhd pfmddr_wrapper.vhd

include $(GRLIB)/bin/Makefile
include $(GRLIB)/software/leon3/Makefile

##################  project specific targets ##########################

sudo-ztex-upload:
	sudo $(ZTEX)/java/FWLoader -c -rf -uf $(TOP).bit

sudo-ztex-upload-fw:
	sudo $(ZTEX)/java/FWLoader -c \
	-uu $(ZTEX)/examples/usb-fpga-1.15/standalone/standalone.ihx \
	-rf -uf $(TOP).bit

ztex-upload:
	$(ZTEX)/java/FWLoader -c -rf -uf $(TOP).bit

ztex-upload-fw:
	$(ZTEX)/java/FWLoader -c \
	-uu $(ZTEX)/examples/usb-fpga-1.15/standalone/standalone.ihx \
	-rf -uf $(TOP).bit

mig:
	cp -r grlib_mig/mig37 .
	coregen -b mig37/mig.xco -p mig37
	patch -p0 < grlib_mig/mig.patch

mig39:
	cp -r grlib_mig/mig39 .
	coregen -b mig39/mig.xco -p mig39
	patch -p0 < grlib_mig/mig_patch.txt
	patch -p0 < grlib_mig/memc3_infrastructure_patch.txt
	patch -p0 < grlib_mig/mcb_soft_calibration_patch.txt

migclean:
	-rm -rf mig37 mig39

.PHONY : mig mig39 miclean
