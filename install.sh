#!/bin/bash
# Bash Color
green='\e[32m'
reset='\e[0m'
pwd=`pwd`
printf "${green}[+] Installing Modmobmap${reset} $*${reset}\n"
cd Modmobmap
./install_all-Ubuntu_20.04.sh
printf "${green}[+] Installing kalibrate-rtl${reset} $*${reset}\n"
cd $pwd/kalibrate-rtl
sudo apt-get install librtlsdr-dev xterm python
sudo ln -s /usr/local/lib/python3.9/dist-packages/serial /usr/local/lib/python2.7/dist-packages
./bootstrap && CXXFLAGS='-W -Wall -O3' ./configure && make
printf "${green}[+] Installing libbladeRF${reset} $*${reset}\n"
cd $pwd
sudo git clone https://github.com/Nuand/bladeRF/
cd bladeRF/host
mkdir -p build && cd build
cmake ..
make && sudo make install
sudo ldconfig
printf "${green}[+] Installing kalibrate-bladeRF${reset} $*${reset}\n"
cd $pwd/kalibrate-bladeRF
./bootstrap && ./configure && make
printf "${green}[+] Installing srsGUI${reset} $*${reset}\n"
cd $pwd/srsGUI
mkdir build && cd build
cmake ..
make && sudo make install
printf "${green}[+] Installation completed!${reset} $*${reset}\n"
