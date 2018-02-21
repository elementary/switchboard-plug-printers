# Switchboard Printers Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-printers/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-printers)

## Building and Installation

You'll need the following dependencies:

* libcups2-dev
* libswitchboard-2.0-dev
* libgranite-dev
* libgtk-3-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
