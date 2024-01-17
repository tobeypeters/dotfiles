## AdLib sound for TempleOS/TinkerOS/ZealOS for VMs and real hardware with 2^64 different 64-bit instruments

### Using the driver
Put `Midi.HH` and `OPL2.HC/ZC` in the same directory, if using real hardware (modify `OPL2.HC/ZC` as described below) and run `#include "OPL2"`.  Now every sound the sound system would normally make is passed through to the OPL2 instead of the PC speaker and you have many more sound options available to you as well as volume control!

### VM options:
- VMware: It might just work, it did for me.
- QEMU: For older versions of QEMU use `-soundhw adlib` for newer versions use `-audiodev alsa,id=snd0 -device adlib,audiodev=snd0` substituting alsa for your desired sound backend as appropriate.
- HyperV/VirtualBox: no OPL2 support
- Passthru of a real hardware device such as an OPL2LPT or serial OPL device to a VM is a possible option, but is an advanced setup beyond the scope of this document.

### Real hardware bare-metal options:
- Parallel port: This can also be used with an <a href="https://www.serdashop.com/OPL2LPT">OPL2LPT</a>/<a href="https://www.serdashop.com/OPL3LPT">OPL3LPT</a> connected via the parallel port or a cheaper <a href="https://github.com/zjuyzj/OPL2LPT-Replica">clone OPL2LPT</a>.  To do this change the `#define ISA_OPL` to `#define OPL2LPT` in `OPL.HC/ZC` and set the `#define LPT_IOPORT_OPL_BASE` value as appropriate for your parallel port.  Note: You need a real 5V parallel port, a USB to Parallel Port will not work and a PCIe Parallel Port card also will very likely not work.
- Clone/Real AdLib ISA card: (should work, but very few systems with ISA slots have a 64-bit CPU to support TOS.  Report back if you have success!)
- Serial port: Work in progress currently not available, but will be possible in the future.
- PCI Sound Card: Will likely not work even if it has legacy Adlib support, most of these require a driver to enable it.  If you find one that just works, please report back!

### Brief overview of some functions this provides:
- `PickInst` - Displays a pop-up dialog letting you pick the instrument to use.
- `RandInst` - Generates a random instrument from a random 64-bit number
- `U64Inst` - Setup an instruments registers from a 64-bit number (use this to restore and re-use random instruments you generated with `RandInst` and like)
- `AdlibInit` - Sets up a normal square wave instrument similar to the original TOS PC speaker sound.
- `SetVolume` - Controls volume (pass values 0-100 percent)

### Random instruments for your random GodSong, finding your 64-bit instrument
One option is to keep running `RandInst;Beep;` (type it, highlight it (hold `SHIFT` and use `LEFT-ARROW`) copy it with `CTRL-C` and then keep pasting it `CTRL-V` and hitting enter with until you hear something you like.  On TinkerOS you can just re-paste the last run command with `F8`.  When you find something you like, save the 64-bit and you can re-create that same unique 64-bit instrument by passing the 64-bit value to `U64Inst`.  Another option is to play some music on repeat and keep running `RandInst` until you find something you like.

### How did I make 2^64 different instruments?
AdLib OPL2 chips are actually able to produce more than 2^64 different instruments.  Instruments are created by assigning values to different registers that control how the AM/FM synthesis happens.  

A good introduction to some of the registers available on the chip is here: <a href="https://github.com/DhrBaksteen/ArduinoOPL2/blob/master/indepth.md">An in-depth look at programming the OPL2 and OPL3</a>.  

A very useful program for composing your own instruments is here: <a href="https://github.com/Wohlstand/OPL3BankEditor">OPL3BankEditor</a>

Melodic instruments are typically defined by 11 registers.  I took the state space spanned by these registers 256^11 = 2^88 and pruned it down.  Not all of the possible 2^88 values produce sound that is useful or sounds good.  I reduced the state space to 2^64 values which span a part of the state space which is more likely to produce interesting sounds.  You can see how I factored 2^64 and distrubuted the bits to the various registers in the following code:

```
static U8 base[11]= {20,2,111,21,0,0,6,0,86,15,0};
static U8 mod1[11]= {128,64,128,128,16,2,128,32,128,128,2};
static U8 mod2[11]= {1,  1, 1,  1,  1, 1,1,  1, 1,  32, 1};

// 64-bit instrument is factored into an instrument as follows:
// 2^64 = 128*64*128*128*16*2*128*32*128*128*2
//        * 1* 1*  1*  1* 1*1*  1* 1*  1* 32*1

U0 U64Inst(U64 inst)
{// Setup an instruments registers from a 64-bit number
  I64 i;
  U8 opl2inst[12];
  opl2inst[0]=0;
  for (i=0; i<11; i++)
  {
    opl2inst[i+1]=base[i];
    opl2inst[i+1]+=inst%mod1[i];
    inst/=mod1[i];
    opl2inst[i+1]+=inst%mod2[i];
    inst/=mod2[i];
  }
  SetInst(opl2inst);
}
```

### Why is only 1 of the 9 possible instruments/operators supported?
The <a href="https://tinkeros.github.io/WbTempleOS/Doc/Charter.html#l39">TempleOS charter says single-voice MIDI-like samples for sounds.</a>  You are free to call the write function to write any values to any registers and fully make use of all the OPL2 operators.  I did not do this by default because I did not want to make something overly complex that violated what Terry put in his TempleOS charter and nothing in TempleOS uses more than 1 sound at a time.
