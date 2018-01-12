![status][st:experimental] [![Build Status][travis:image]][travis:status]

[travis:image]: https://travis-ci.org/CapeLeidokos/Leidokos-CMake.svg?branch=master
[travis:status]: https://travis-ci.org/CapeLeidokos/Leidokos-CMake

[st:stable]: https://img.shields.io/badge/stable-✔-black.svg?style=flat&colorA=44cc11&colorB=494e52
[st:broken]: https://img.shields.io/badge/broken-X-black.svg?style=flat&colorA=e05d44&colorB=494e52
[st:experimental]: https://img.shields.io/badge/experimental----black.svg?style=flat&colorA=dfb317&colorB=494e52

# Leidokos-CMake
Enables portable and parallel builds of Kaleidoscope using the CMake build system.

## Disclaimer
This project is not meant as a replacement for or a competition to Kaleidoscope's stock build systems,
but rather as an additional tool, directed to experienced programmers.

The maintainers of Kaleidoscope pointed out that they are currently not planning to support 
other build systems apart from the Arduino IDE and their own GNU make based
build system. Please respect their decision and do not bother them with
questions about Leidokos-CMake. 

Instead, direct any issue reports and questions [here](https://github.com/CapeLeidokos/Leidokos-CMake).

Pull requests are, of course, highly welcome, as well as testers that work with other (exotic) plaforms apart from Linux.

## Acknowledgements
Great thanks to the developers of Arduino-CMake, namely the original developer [queezythegreat](https://github.com/queezythegreat)
and the current maintainer [JonasProgrammer](https://github.com/JonasProgrammer). 
Your very well designed tool provides a transparent replacement to arduino-builder.

Also, many thanks to the developers and maintainers of Kaleidoscope for the firmware and 
the inspiration that lead to the creation of this project.

## Introduction
Kaleidoscope's stock build system is designed to be user friendly and welcoming. 
It enables builds using the Arduino IDE or through a GNU make based approach.

Both approaches lack certain features that advanced users are likely to miss, namely, 

* platform independentness, 
* support for parallel builds,
* integration with IDEs,
* support of faster, modern build tools such as Ninja.

Also, both the Arduino IDE and the make based command line build system compile everything, 
thereby causing a lot of undesired waiting time in modify-compile-test-modify cycles.

All this motivates the search for a more developer-friendly approach.

## CapeLeidokos
Leidokos-CMake is an essential part of the CapeLeidokos build, develop and testing infrastructure for the Kaleidoscope firmware.

<img src="https://github.com/CapeLeidokos/CapeLeidokos/blob/master/CapeLeidokos.svg?sanitize=true">

## CMake a portable solution
CMake is a well established, mature, widely used and well supported configuration system. It is
used by a large number of open source projects and has in the last 15 years more and more 
replaced autotools. Due to its availability on multiple platforms, it
is especially well suited for cross-platform development.

Based on CMake, [Arduino-CMake](https://github.com/arduino-cmake/arduino-cmake) was developed as
a replacement for the Arduino IDE for sophisticated users.

Arduino-CMake supports the generation of Arduino firmwares without the need to use arduino-builder,
Arduino's traditional dependency resolution tool. It provides its own auto-detection algorithm, 
that comes with the great advantage against arduino-builder, that it is able to resolve 
all dependencies between the firmware, libraries
and their source files in a way that is fully transparent and compatible with
the great variety of build systems that are supported by CMake. 

CMake in its current version (3.5.1 on Ubuntu 16.04) supports the following build systems (taken from `man cmake-generators`).

* Unix Makefiles               = Generates standard UNIX makefiles.
* Ninja                        = Generates build.ninja files.
* Watcom WMake                 = Generates Watcom WMake makefiles.
* CodeBlocks - Ninja           = Generates CodeBlocks project files.
* CodeBlocks - Unix Makefiles  = Generates CodeBlocks project files.
* CodeLite - Ninja             = Generates CodeLite project files.
* CodeLite - Unix Makefiles    = Generates CodeLite project files.
* Eclipse CDT4 - Ninja         = Generates Eclipse CDT 4.0 project files.
* Eclipse CDT4 - Unix Makefiles= Generates Eclipse CDT 4.0 project files.
* KDevelop3                    = Generates KDevelop 3 project files.
* KDevelop3 - Unix Makefiles   = Generates KDevelop 3 project files.
* Kate - Ninja                 = Generates Kate project files.
* Kate - Unix Makefiles        = Generates Kate project files.
* Sublime Text 2 - Ninja       = Generates Sublime Text 2 project files.
* Sublime Text 2 - Unix Makefiles
                               = Generates Sublime Text 2 project files.

Of course, on Windows other build systems are supported, ammong those also some commercial IDEs. Checkout 
the list of generators displayed at the end of the text that is output when you enter 
```bash
cmake --help
```

To support the user, CMake supports several graphical front-ends, whose availability differs between platforms. 
On Linux, e.g. a curses based GUI is available, that is started with the command
```bash
ccmake ..
```
         
**Note:** Almost every call to `cmake` or `ccmake` expects a directory that defines where the configuration
file (`CMakeLists.txt`) resides. In the example above, we assumed the command to be entered
from a directory that is one level below the Leidokos-CMake root directory, therefore the `..` 
at the end of the command.

## Prerequisites
### CMake
To build with Leidokos-CMake, the CMake build system must be installed. 
On Ubuntu Linux, e.g. install it as
```bash
sudo apt-get install cmake cmake-curses-gui
```

### Arduino-CMake
Leidokos-CMake currently depends on a [patched version](https://github.com/CapeLeidokos/arduino-cmake) of 
[Arduino-CMake](https://github.com/arduino-cmake/arduino-cmake) that is provided as a git submodule in the
`3rd_party/arduino-cmake` directory of this project.
As soon as some pull requests ([1](https://github.com/arduino-cmake/arduino-cmake/pull/17), [2](https://github.com/arduino-cmake/arduino-cmake/pull/19)) have been merged to upstream [Arduino-CMake](https://github.com/arduino-cmake/arduino-cmake), we will return to using the original Arduino-CMake.

## For the impatient: A brief example
The following example shows how Leidokos-CMake can be used to build the stock firmware on a
Linux system using GNU make as build system.

```bash
TARGET_DIR=<your_prefered_test_location>
cd ${TARGET_DIR}

# Clone the keyboardio arduino boards the standard way
#
mkdir -p hardware/keyboardio
git clone --recursive https://github.com/keyboardio/Arduino-Boards.git \
    hardware/keyboardio/avr

# Clone Leidokos-CMake as a sibling to the stock plugins
#
cd hardware/keyboardio/avr/libraries
git clone --recursive https://github.com/CapeLeidokos/Leidokos-CMake.git

# Generate and change to a build directory
#
cd ${TARGET_DIR}
mkdir build
cd build

# Configure the build system
#
cmake ${TARGET_DIR}/hardware/keyboardio/avr/libraries/Leidokos-CMake

# Run the build
#
make
```

## Usage
To build with CMake and GNU make on a Linux platform, do the following.

1. Clone the Leidokos-CMake repository to your `.../hardware/keyboardio/avr/libraries` folder.
```bash
cd <a_suitable_path>/hardware/keyboardio/avr/libraries
git clone --recursive https://github.com/CapeLeidokos/Leidokos-CMake.git
```

2. Generate an (out-of-source) build directory
```bash
cd Leidokos-CMake
mkdir build
cd build
```

3. Setup the CMake build system (this will use CMake's default generator for your platform)
```bash
cmake ..
```

4. Build
```bash
make
```

Instructions for other systems (Windows, OSX) can slightly vary. Please consult your platform specific documentation of CMake.

## Upload
To upload the firmware, enter the following (assuming you selected the `Unix Makefiles` generator).
```bash
make upload
```
In general (for any arbitrary generator), enter the somewhat more detailed command
```bash
cmake --build . --target upload
```

## Parallel builds
For most of its generators (for an explanation about what a generator is, see below) CMake supports parallel builds, 
that allow to use all cores of a multi-core machine to shorten build times.

To build in parallel using 8 threads, using GNU make, run 

```bash
make -j 8
```

instead of the standard build command `make`.

## Builds with other build systems
If you want to use another build system, please consult the list of supported CMake Generators.
A CMake Generator is a set of definitions that enables CMake to emit specific files can be used by
different build systems, e.g. `Makefile`'s for GNU make.

The [Ninja](https://ninja-build.org/) build system is known to be lightning fast if it comes to 
finishing almost completed builds. It is at least very much faster than GNU make.

If you want to use Ninja to build Kaleidoscope, do as follows

```bash
# On Ubuntu Linux
sudo apt-get install ninja-build

# Follow steps 1. and 2. of the general instructions above

# Configure the build system
cmake -G Ninja ..

# Build
ninja
```

For all build system (including those listed above), the build process can also be triggered
as
```bash
cmake --build . [--target <target>]
```
after the build system has been configured.

## Auxiliary build targets
Similar to GNU make, CMake allows for the definition of build targets, that can be individually
executed. If no target is explicitly specified, the build system executes the default target, 
which tries to build the firmware.

The targets available can be shown using the `help` target, either
as 
```bash
cmake --build . --target help
```
or
```bash
make help
```
or
```bash
ninja help
```
depending of the CMake Generator that has been selected.

## Useful targets for developers
### Compile, pre-processing and assembly generation for individual sources
The list of sources that are part of a Kaleidoscope build is also displayed, when
the `help` target is executed. For each source that is compiled there are three targets listed, ending in a
file with extension `.obj`, `.i` and `.s`. 

| Extension | Purpose                                               |
|:--------- |:----------------------------------------------------- |
| `.obj`    | Compiles an object file                               |
| `.i`      | Pre-processes the file and stops after pre-processing |
| `.s`      | Compiles and generates assembly code                  |

For a file `.../my_source.cpp` there will, e.g. a target `.../my_source.i` that
can be triggered as
```bash
cmake --build . --target .../my_source.i
```
The output of the pre-processing process the follows informs about the
actual target path of the generated file.

### Disassembly
For those familiary with assembly code, the `decompile` or `disassembly` target allows
to generate a disassembly of the firmware code.

### Symbol list
A symbol list can be output by using the `nm` target.

### Verbose builds
The `Unix Makefiles` generator supports the generation of verbose makefiles. Those
allow for extra verbose debugging output that can easily be toggled 
via the environment variable `VERBOSE`, e.g.
```bash
VERBOSE=1 make
```

## Advanced configuration
Although, Leidokos-CMake is meant to be as auto-detecting and smart as possible,
it may be necessary to configure the system.

The following table provides an overview of configuration variables that are
available to tweak the CMake build system.

| CMake Variable                  | Purpose                                                           |
|:------------------------------- |:----------------------------------------------------------------- |
| KALEIDOSCOPE_BOARD              | The keyboard hardware |
| KALEIDOSCOPE_FIRMWARE_SKETCH    | Filepath of the Arduino sketch (the *.ino) file                   |
| KALEIDOSCOPE_ARDUINO_PROGRAMMER | The programmer to be used (see the [Arduino-CMake documentation](https://github.com/arduino-cmake/arduino-cmake)<br>for more information on available programmers)                    |
| KALEIDOSCOPE_DOWNLOAD_ARDUINO   | If this flag is enabled, the build system automatically downloads<br> Arduino during the configuration phase.                           |
| KALEIDOSCOPE_HARDWARE_BASE_PATH | A path to the `.../hardware` directory below which <br>
hardware definitions are situated |
| KALEIDOSCOPE_HOST_BUILD         | Enable this flag if you want to build for the host system instead of the Arduino architecture 
(virtual build) |
| KALEIDOSCOPE_VENDOR_ID          | The vendor ID of the target keyboard |
| KALEIDOSCOPE_ARCHITECTURE_ID    | The target keyboard's architecture (e.g. avr) |
| KALEIDOSCOPE_LIBRARIES_DIR      | The path to the libraries directory where the Kaleidoscope modules live (must only be explicitly set when this path is not below KALEIDOSCOPE_HARDWARE_BASE_PATH) |
| LEIDOKOS_CMAKE_SOURCE_DIR   | The path to the Leidokos-CMake sources. This is only required to be set when Leidokos-CMake is wrapped by other CMake build systems |
| KALEIDOSCOPE_ADDITIONAL_HEADERS | A list of absolute paths of header files that are included in the firmware build. This is only required for advanced use, e.g. when Leidokos-CMake is embedded in another CMake build system |
| KALEIDOSCOPE_BINARY_BASENAME    | An alternative name for the generated firmware binary. The default name is used if empty |

The value of a variable can either be set at the CMake command line during the configuration
stage, e.g. as
```bash
cmake -DKALEIDOSCOPE_KEYBOARD_HARDWARE="Shortcut" ..
```
or it can be modified later on using one of CMake's GUIs, e.g. the curses GUI (Unix/Linux) that
is started as
```bash
ccmake ..
```

## Supported platforms
Leidokos-CMake is tested on Ubuntu Linux (16.04) with Arduino 1.8.5. As CMake and 
arduino-cmake are both platform independent, this build system is supposed to
work on other platforms, too.

Testers working with other platforms are highly welcome! 

## Travis-testing
Currently we test if the build system actually builds the stock firmware and if the symbols in the firmware that
is build do match those of the stock firmware if build with the legacy GNU make build system.
