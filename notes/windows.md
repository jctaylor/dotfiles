# Make windows more comfortable to work in


## WSL

Install Ubuntu 
Install these dotfiles

## Hack Nerd Fonts

Download [zip](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip)

Unzip using file browser
Select all ttf files. Right click, choose "more options" -> "Install for all users"

There is some issue in Windows 11 where installing in Control panel UI vs Settings UI, the fonts can not be found after reboot.

## Focus follows mouse (without raising window)

Contol Panel -> Ease of Access -> Make the mouse easoer to use -> chek "Activate a window by hovering ..."

This will make the window under the mouse activate after some small delay. When the window activates, it will also raise the window.

To change the autoraise feature, run 'regedit' 

Subtract 0x40 (actually turn off that bit) from the first byte of `HKEY_CURRENT_USER\Control Panel\Desktop\UserPreferenceMask`. In my case, the entry was "df 5e 07 80 12 00 00 00"
The "df" (bin 0b11011111) needs to be "9f" (0b10011111)


