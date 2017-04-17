# Switchboard Printers Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-printers/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-printers)

## Building and Installation

You'll need the following dependencies:

* cmake (>= 2.8)
* libswitchboard-2.0-dev
* libgranite-dev
* libgtk-3-dev
* valac (>= 0.22)

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`

    sudo make install

