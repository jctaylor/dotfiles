# Network Manager

NOTE **ifconfig** has been deprecated for more than a decade!

## What it is

It is just a daemon providing a common API used via D-BUS

Settings are handled by plugins. This is why different distros have different config files.

Allows users to define network connectivity via polkit (GUI style priveledge escalation).

Messages can come in from the kernel or other sources and can take action based on settings (i.e. automation).

Everything starts with `udev`. It defines what a device and talks to the kernel and creates entries in the `/dev`
file system. `udev` communicates with D-BUS.

Network Manager is about managing, devices and connections.

udev ---> Device --> Connection Settings

Device names have become more predictable to fix the problem of names changing based on how BIOS enumerates them
Interfaces start with "en" (ethernet), "wl" (wirelss), "ww" (wide area network)

Followed by `o<index>`, `s<slot>[f<function>][d<dev_id>]`, `x<MAC>`,
`[P<domain>]p<bus>s<slot>[f<function>][d<dev_id>]`

A "device" can have multiple connections.

Devices are a kernel view of the hardware and its current state.
Connections are an admin's representation of what is configured.
think of "Connection" as the desired state and "Device" as the kernel stat


## Interfaces

nmcli -- Network Manager Command Line Interface
nmtui -- Network Manager Curses-based User Interface (Terminal UI?)
nm-connection-editor -- Graphical user interface available on all distros
network-manager-applet (nm-applet) -- for a system tray applet

nm-connection-editor looks very similar to gnome-network-manager. 

nmcli [OPTIONS] OBJECT command

### Object types

    `g[eneral]`     NetworkManager's general status and opertaions
    `n[networking]` overall networking control
    `r[adio]`       NetworkManager radio switches
    `c[onnection]`  NetworkManager's connections
    `d[evice]`      devices managed by NetworkManager
    `a[gent]`       NetworkManager secret agent or polkit agent
    `m[onitor]`     monitor NetworkManager changes

## nmcli onliners

`nmcli connection` to see a summary of "connections".
`nmcli device show` to see details of network devices.
`nmcli dev wifi` shows the wifi networks (like on a phone when you are browsing possible connections).
`nmcli d wifi connect <SSID>[password][wep-key-type] ...` this is all I have to do to connect to wifi.
`nmcli d connect eth0` creates a default (dhcp) for eth0.
`nmcli c edit` creates a nmcli shell to change settings. Remember '`save` to make it persistent.

## References

A very good (but lengthy) [video discussion](https://www.youtube.com/watch?v=DHNXIGKWCps) of what Network Manager is)


