# PiBright
Brightness control for Raspberry Pi.

## Building, Testing, and Installation

You'll need the following dependencies:

```
$ sudo apt install meson ninja-build valac libvala-0.42-dev libgtk-3-dev
```

Run `meson build` to configure the build environment:

    meson --prefix=/usr/local -Dbuildtype=release build
    
This command creates a `build` directory. For all following commands, change to
the build directory before running them.

To build pib, use `ninja`:

    ninja -j4

To install, use `ninja install`

    sudo ninja install

`Note` compositing has to be enabled
