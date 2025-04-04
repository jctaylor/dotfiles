#!/bin/bash

usage="

        WORK IN PROGRESS

USAGE: $script_name [--help]

OPTIONS:

    --help          Print this message and exit

"


# Make sure xcode is installed
xcode-select --install


# Get HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update
grew upgrade



# apktool                   # For Android work
# bash                      # To get a later version of bash (system one is behind)
# bash-completion           # 
# bash-language-server      # nvim dev
# brotli                    # 
# c-ares                    # 
# ca-certificates           # 
# cairo                     # 
# cmake                     # dev
# cmake-docs                # dev
# fontconfig                # ? For hacker fonts?
# freetype                  # 
# fribidi                   # 
# gettext                   # 
# ghostscript               # 
# giflib                    # 
# glib                      # 
# gmp                       # 
# gnupg                     # 
# gnutls                    # 
# graphite2                 # 
# harfbuzz                  # 
# icu4c@76                  # 
# icu4c@77                  # 
# iperf3                    # 
# jbig2dec                  # 
# jpeg-turbo                # 
# leptonica                 # 
# libarchive                # 
# libassuan                 # 
# libb2                     # 
# libevent                  # 
# libgcrypt                 # 
# libgpg-error              # 
# libidn                    # 
# libidn2                   # 
# libksba                   # 
# libnghttp2                # 
# libpng                    # 
# libtasn1                  # 
# libtiff                   # 
# libunistring              # 
# libusb                    # 
# libuv                     # 
# libx11                    # 
# libxau                    # 
# libxcb                    # 
# libxdmcp                  # 
# libxext                   # 
# libxrender                # 
# little-cms2               # 
# lpeg                      # 
# lua-language-server       #  nvim
# luajit                    #  nvim
# luv                       #  nvim
# lz4                       # 
# lzo                       # 
# micro_inetd               # 
# mpdecimal                 # 
# ncurses                   # 
# neovim                    #  nvim
# nettle                    # 
# node                      # 
# npth                      # 
# openjdk                   # 
# openjpeg                  # 
# openssl@3                 # 
# p11-kit                   # 
# pango                     # 
# pcre2                     # 
# pinentry                  # 
# pixman                    # 
# python-lsp-server         #  nvim dev
# python-packaging          # 
# python@3.13               # 
# readline                  # 
# ripgrep                   # 
# sqlite                    # 
# strongswan                # 
# tesseract                 # 
# tmux                      # 
# tree                      # 
# tree-sitter               # 
# unbound                   # 
# unibilium                 # 
# utf8proc                  # 
# webp                      # 
# wget                      # 
# xorgproto                 # 
# xz                        # 
# zstd                      # 
# clay                      # 
# diffmerge                 # 
# font-hack-nerd-font       #  nvim config
# xquartz                   #  X11
#
