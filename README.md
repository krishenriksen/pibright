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

## Support the project

<a href="https://www.paypal.me/krishenriksendk" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>
