AddPackage arch-install-scripts # Scripts to aid in installing Arch Linux
AddPackage autoconf # A GNU tool for automatically configuring source code
AddPackage automake # A GNU tool for automatically creating Makefiles
AddPackage base # Minimal package set to define a basic Arch Linux installation
AddPackage binutils # A set of programs to assemble and manipulate binary and object files
AddPackage bison # The GNU general-purpose parser generator
AddPackage ccache # Compiler cache that speeds up recompilation by caching previous compilations
AddPackage cmake # A cross-platform open-source make system
AddPackage dosfstools # DOS filesystem utilities
AddPackage efibootmgr # Linux user-space application to modify the EFI Boot Manager
AddPackage fakeroot # Tool for simulating superuser privileges
AddPackage flex # A tool for generating text-scanning programs
AddPackage fwupd # Simple daemon to allow session software to update firmware
AddPackage gcc # The GNU Compiler Collection - C and C++ frontends
AddPackage git # the fast distributed version control system
AddPackage gst-plugins-good # Multimedia graph framework - good plugins
AddPackage gnome-keyring # Stores passwords and encryption keys
AddPackage go # Core compiler tools for the Go programming language
AddPackage groff # GNU troff text-formatting system
AddPackage htop # Interactive process viewer
AddPackage inetutils # A collection of common network programs
AddPackage kernel-modules-hook # Keeps your system fully functional after a kernel upgrade
AddPackage lib32-glibc # GNU C Library (32-bit)
AddPackage libtool # A generic library support script
AddPackage linux # The Linux kernel and modules
AddPackage linux-firmware # Firmware files for Linux
AddPackage m4 # The GNU macro processor
AddPackage make # GNU make utility to maintain groups of programs
AddPackage man-db # A utility for reading man pages
AddPackage mlocate # Merging locate/updatedb implementation
AddPackage nano # Pico editor clone with enhancements
AddPackage neofetch # A CLI system information tool written in BASH that supports displaying images.
AddPackage neovim # Fork of Vim aiming to improve user experience, plugins, and GUIs
AddPackage ntfs-3g # NTFS filesystem driver and utilities
AddPackage openssh # Premier connectivity tool for remote login with the SSH protocol
AddPackage pacman # A library-based package manager with dependency support
AddPackage pacman-contrib # Contributed scripts and tools for pacman systems
AddPackage patch # A utility to apply patch files to original sources
AddPackage perl-rename # Renames multiple files using Perl regular expressions.
AddPackage pkgconf # Package compiler and linker metadata toolkit
AddPackage polkit-gnome # Legacy polkit authentication agent for GNOME
AddPackage python-pip # The PyPA recommended tool for installing Python packages
AddPackage python-tqdm # Fast, Extensible Progress Meter
AddPackage realtime-privileges # Realtime privileges for users
AddPackage reflector # A Python 3 module and script to retrieve and filter the latest Pacman mirror list.
AddPackage rsync # A file transfer program to keep remote files in sync
AddPackage screen # Full-screen window manager that multiplexes a physical terminal
AddPackage sl # Steam Locomotive runs across your terminal when you type "sl" as you meant to type "ls".
AddPackage sudo # Give certain users the ability to run some commands as root
AddPackage texinfo # GNU documentation system for on-line information and printed output
AddPackage tmux # A terminal multiplexer
AddPackage udiskie # Removable disk automounter using udisks
AddPackage unrar # The RAR uncompression program
AddPackage unzip # For extracting and viewing files in .zip archives
AddPackage wget # Network utility to retrieve files from the Web
AddPackage which # A utility to show the full path of commands
AddPackage xdg-user-dirs # Manage user directories like ~/Desktop and ~/Music
AddPackage yadm # Yet Another Dotfiles Manager
AddPackage zip # Compressor/archiver for creating and modifying zipfiles
AddPackage zsh # A very advanced and programmable command interpreter (shell) for UNIX

AddPackage --foreign aconfmgr-git # A configuration manager for Arch Linux
AddPackage --foreign autojump # A faster way to navigate your filesystem from the command line
AddPackage --foreign ly # TUI display manager
AddPackage --foreign needrestart # Restart daemons after library updates.
AddPackage --foreign paru-bin # AUR helper based on yay
AddPackage --foreign systemd-boot-pacman-hook # Pacman hook to upgrade systemd-boot after systemd upgrade.
AddPackage --foreign topgrade # Invoke the upgrade procedure of multiple package managers

CopyFile /etc/ly/config.ini
CopyFile /etc/polkit-1/rules.d/10-manage-openvpn.rules
CopyFile /etc/polkit-1/rules.d/20-manage-reflector.rules
CopyFile /etc/sysctl.d/20-quiet-printk.conf
CopyFile /etc/systemd/logind.conf
CopyFile /etc/systemd/network/10-wired.network
CopyFile /etc/systemd/network/20-wireless.network
CopyFile /etc/systemd/resolved.conf
CopyFile /etc/systemd/sleep.conf
CopyFile /etc/udev/rules.d/backlight.rules

CreateLink /etc/udev/rules.d/80-net-setup-link.rules /dev/null
