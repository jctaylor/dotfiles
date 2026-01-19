# Cheat sheet for apt and dpkg

## aptitude

aptitude is a TUI interface.

## apt

`apt` is a front end to  `apt-get` and `apt-cache` which uses `dpkg` under the hood.

`apt-get` used to install, upgrade, reinstall, remove, purge

Packages are have links to other packges:
    * depends on -- will get installed otherwise the package install would be borken
    * recommends -- These also get installed by default unless --no-install-recommends
    * suggests ---- Not installed by default but are likely complimentary or enhances the package being installed

```bash
sudo apt update  # downloads package information for the repositories

sudo apt upgrade [pkg ...]    # Upgrades packages to the most recent version (subject to "phasing")
sudo apt install [pkg ...]
sudo apt install -U [pkg ...] # Syntactic sugar for 'sudo apt update && sudo apt install [pkg ...]
                              # Technically it contains a race condition since is lets go of the lock between update and
                              # install

sudo apt install --install-suggests  [pkg ...] 

sudo apt remove [pkg ...]  # Remove the package but leaves its config files
sudo apt purge [pkg ...]   # Like remove, but also delete the config files

sudo apt autoremove   # Remove packages that were installed to statisfy dependancies for other packages and are not
                      #longer needed
```

## Listing packages

```
apt list --installed  # i.e. what I have
apt list              # Everything that is available from source.list sources.d/*
apt-mark showauto     # List all the files that were installed as dependancies of an apt install (or later marked auto)
apt-mark showmanual   # List all the files that were explicitly installed 
apt autoremove --dry-run  # This should list  - dynamic binary

apt list ?obsolete    # List obsolete packages (does this limit to 

# List all manually-installed packages in sections matching libs, perl, or python.  (see man apt-patterns)
apt list '~i !~M (~slibs|~sperl|~spython)'
```

## apt-cache

Get information from APT's package cache.  This is essentially a database of what's  installed and what could be installed


## dpkg

Package level tool. Normally don't use this. 

```
dpkg --install [pkg ...]   # Install the pkg but not it dependancies (maybe this is usefull for source code you are not
                           # going to build.
```

## dpkg-query

```
dpkg-query -L [pkg ...]  # List all the files installed by the package(s)

dpkg -S [path] # Show which package this file was installed by

dpkg -l [globpattern] # List with status (action,status,errors)
```

## dpkg-reconfigure

Sometimes can be used to fix a package that has not been configured correctly.

