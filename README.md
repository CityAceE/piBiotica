# piBiotica

**piBiotica** is a fork of the ZX Spectrum emulator [piBacteria](http://πbacteria.speccy.org), written by *Antonio José Villena Godoy* in ARM assembly language for the Raspberry Pi.
Currently done: 
* The emulator text has been translated for compilation in [FASMARM](https://arm.flatassembler.net/) assembler.
* Added possibility to load ZX Spectrum programs in [SNA](https://sinclair.wiki.zxnet.co.uk/wiki/SNA_format) format during the compilation process.
* Fixed some bugs in Z80 emulation. Now [Z80all instruction exerciser](https://mdfs.net/Software/Z80/Exerciser/Spectrum/) passes all tests without errors.
* Extended output of register contents to the console.
* Changed method of output to console. Single output method for QEMU and real Raspberry Pi is used.
