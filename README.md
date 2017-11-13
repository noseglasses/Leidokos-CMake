# Kaleidoscope-CMake
Enables portable and parallel builds of Kaleidoscope using the CMake build system.

# Motivation
Kaleidoscope comes with its own build system, actually two build systems.
It can be build from the Arduino IDE and at the command line using makefiles
and a project specific set of bash-scripts.

The Makefile based solution is a great aid as it can be integrated in workflows
such as testing frameworks. Unfortunately, it lacks some features that
many developers might be used to, namely, 

* platform independentness, 
* parallel builds,
* integration with IDEs,
* support for faster, modern build tools such as ninja,
* everything is compiled everytime.

# CMake a portable solution
Fortunately, there is CMake a well established, mature, widely used and well supported build system.
Quite a while ago, [Arduino-CMake](https://github.com/arduino-cmake/arduino-cmake) was developed as
a replacement for the Arduino IDE for sophisticated users.

Arduino-CMake supports the generation of Arduino firmwares without the need to use arduino-builder. 
It supports an auto-detection algorithm that was tailored as a replacement for arduino-builders
detection engine, yet with the advantage that all dependencies between the firmware, their libraries
and the source files are resolved in a way that is fully transparent and allows for the generation
of all sorts of low level build systems that are supported by CMake.

# Prerequisites
To build with Kaleidoscope-CMake, the CMake build system must be installed.

# Usage
To build with CMake and make on a Linux platform, do the following.

1. Clone the Kaleidoscope-CMake repository to your `.../hardware/keyboardio/avr/libraries` folder.
```
cd <a_suitable_path>/hardware/keyboardio/avr/libraries
git clone --recursive https://github.com/noseglasses/Kaleidoscope-CMake.git
```

2. Generate an (out-of-source) build directory
```
cd Kaleidoscope-CMake
mkdir build
cd build
```

3. Setup the CMake build system
```
cmake ..
```

4. Build
```
make
```

# Parallel builds
If you want parallel builds, run your build tool in a way that triggers a build process suitable for a 
multicore platform. To build with 8 threads in parallel, run 
```
make -j 8
```
instead of the standard build command.

# Builds with other build systems
TODO