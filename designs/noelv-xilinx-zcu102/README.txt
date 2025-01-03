RISC-V NOELV Zynq UltraScale+ ZCU102 board Design Template
----------------------

These design template has been built in order to instantiate a NOELV core in a Xilinx
Zynq UltraScale+ ZCU102 board.

Information on the ZCU102 at:

https://www.xilinx.com/products/boards-and-kits/ek-u1-zcu102-g.html

---------------------
Design Requirements
---------------------

The design has been tested with the following tools:

Mentor Modelsim 10.6a
Vivado 2018.1

----------------------
Flow
----------------------

* Design structure

All NOEL-V template design are structured in a similar way. The IP core
instantiations are done in the noelvcore.vhd file located in the 
noelv-generic/rtl/core directory and are common for all designs. The "CORE_DIR" 
Makefile variable points to the location of the "rtl/core" directory and can be
changed to point to a local copy if needed. The top-level design (together with
configuration file) is separate for each template design and handles board 
specific things like: different memory controllers, clock and  reset 
implementations, and external interface connections (pad instantiations).

Files are arranged as follow:
config.vhd                  - Design configuration (generated by make xconfig)
rtl/core/                   - Core-level HDL files (where IPs are instantiated, 
  cfgmap.vhd                  shared by other template designs)
  noelvcore.vhd
  rev.vhd
rtl/                        - Top-level HDL files (including board/testbench
  noelvmp.vhd                 specifics: memory controller, ETH PHY, ...)
  ahbrom.vhd
  ahbrom64.vhd
  ahbrom128.vhd
cfg/                        - Extra configuration level (mostly forwarded form
  config_local.vhd            config.vhd)
tb/                         - Testbench
  testbench.vhd
sw/                         - Local system test application
  systest.c
scripts/                    - Scripts, local constraints files

* Simulate

make map_xilinx_7series_lib
make sim
make sim-launch (no ram.srec if on-chip ahbram)

* Synthesize

make vivado (make vivado-launch for the GUI)


************************
Simulate
************************

* The design does not support DDR4 MIG and GRETH IPs.
* An AHBRAM loaded with the ram.srec image is instantiated only if you opt for the DDR4 memory with the CONFIG_MIG_7SERIES_MODEL variables set to Y. This will instantiate and ahbramsim with the image loaded.
* No ram.srec file will be loaded during simulation if you instantiate the on-chip ahbram.

Default (set in Makefile) is CONFIG_MIG_7SERIES_MODEL=Y

************************
Benchmark
************************

If you would like to perform a benchmark simulation, you first need to compile it and replace the content of ram.srec.

************************
Synthesize
************************

You could launch the Vivado GUI with the following target:

make vivado-launch

If you would like to run in batch mode, then issue the following commands:

make vivado

After successfully programming the FPGA the user might have to press
the 'CPU RESET' button in order to successfully complete the
calibration process in the MIG. Led 6 and led 7 should be constant
green if the Calibration process has been successful.

If user tries to connect to the board and the MIG has not been
calibrated successfully 'grmon' will output: AMBA plug&play not found!

************************
Flow without MIG 
************************

The MIG can be disabled either by deselecting the memory
controller in 'xconfig' or manually
editing the config.vhd file.  When no MIG is
present in the system normal GRLIB flow can be used and no extra
compile steps are needed. Also when when no MIG is present it is
possible to control and set the system frequency via xconfig.  Note
that the system frequency can be modified via Vivado when the MIG is
present by modifying within specified limits for the MIG IP.

************************
Ethernet
************************

Zynq family only allow PS-side to access MIO, where the Ethernet PHY
pins are hardened; read Ethernet_ZCU102.docx for more information.

************************
Run with GRMON
************************

Once the FPGA has been programmed, you could load srec files via grmon and then execute it 
with the run command.


***********************
Output form GRMON
***********************

To be added

***********************
Write BPI Flash
***********************

If you would like to write bitstream into the BPI flahs in order to boot the board to that
particular design, you could issue the following command in Vivado (in a tcl shell):

* not supported yet *

And program the Quad-SPI Flash Memory using the following part name:

N25Q256A11ESF40F

The set to boot from the configuration memory in the Vivado Hardware Manager utility.

Design specifics
----------------

* The DDR4 controller is implemented with Xilinx MIG IP and 
  runs of the 300 MHz clock. The DDR4 memory runs at 1200 MHz.
  The calibration procedures are handled by a Microblaze
  instance into the MIG DDR4 controller, running a C source file.

* The AHB clock is generated by the MMCM module in the DDR4
  controller, and can be controlled via Vivado. When the 
  MIG DDR4 controller isn't present the AHB clock is generated
  from CLKGEN.

* System reset is mapped to the CPU RESET button.

* The application UART1 is connected to the USB/RS232 connector if 
  switch 3, located on the DIP Switch SW2 of the board, is set to OFF.
  
* The AHB UART can be enabled by setting switch 3 to ON.
  Since the board is equipped with one USB/RS232 connector, APB UART1 and
  AHB UART cannot be used at the same time.

* The JTAG DSU interface is enabled and accesible via the JTAG port.
  Start grmon with -xilusb to connect.
