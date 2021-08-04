#!/bin/bash
# Bash Color
green='\e[32m'
reset='\e[0m'

printf "${green}[+] Installing Python3 requirements${reset} $*${reset}\n"
sudo apt-get install python3-pip
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install -r requirements.txt

printf "${green}[+] Installing GNU Radio dependencies${reset} $*${reset}\n"
sudo apt-get update
sudo apt install git gnuradio gnuradio-dev  cmake g++ libboost-all-dev libgmp-dev swig python3-numpy \
python3-mako python3-sphinx python3-lxml doxygen libfftw3-dev \
libsdl1.2-dev libgsl-dev libqwt-qt5-dev libqt5opengl5-dev python3-pyqt5 \
liblog4cpp5-dev libzmq3-dev python3-yaml python3-click python3-click-plugins \
python3-zmq python3-scipy python3-gi python3-gi-cairo gobject-introspection gir1.2-gtk-3.0

printf "${green}[+] Installing gr-osmosdr package${reset} $*${reset}\n"
sudo apt install gr-osmosdr

printf "${green}[+] Preparing environment${reset} $*${reset}\n"
mkdir thirdparty
cd thirdparty
REMPATH=`pwd`
sudo ln -s /usr/local/lib/python3/dist-packages/grgsm /usr/lib/python3/dist-packages/
sudo ln -s /usr/local/lib/x86_64-linux-gnu/libgrgsm.so.1.0.0git /usr/lib/x86_64-linux-gnu/libgrgsm.so.1.0.0git
cd ../../

printf "${green}[+] Installing SDK tools${reset} $*${reset}\n"
sudo apt install openjdk-14-jdk
wget https://dl.google.com/android/repository/commandlinetools-linux-6609375_latest.zip
unzip commandlinetools-linux-6609375_latest.zip
sudo mkdir -p /opt/Android
cd tools
./bin/sdkmanager --sdk_root=/opt/Android --update
sudo ./bin/sdkmanager --sdk_root=/opt/Android --install platform-tools

printf "${green}[+] Installing dependencies for srsRAN${reset} $*${reset}\n"
sudo apt-get install cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev
sudo apt install libsoapysdr-dev
#osmo sdr support:
sudo apt-get install osmo-sdr soapysdr-module-osmosdr
#rtl sdr support:
sudo apt-get install rtl-sdr soapysdr-module-rtlsdr
#blade rf support:
sudo apt-get install bladerf soapysdr-module-bladerf
#hack rf support:
sudo apt-get install hackrf soapysdr-module-hackrf
#usrp support:
sudo apt-get install uhd-host uhd-soapysdr soapysdr-module-uhd
#miri SDR support:
sudo apt-get install miri-sdr soapysdr-module-mirisdr
#rf space support:
sudo apt-get install soapysdr-module-rfspace
#airspy support:
sudo apt-get install airspy soapysdr-module-airspy

printf "${green}[+] Installaing srsRAN for Modmobmap${reset} $*${reset}\n"
cd $REMPATH
cd srsRAN
mkdir build
cd build
cmake ../
make -j$(nproc)
printf "${green}[+] Modmobmap install completed!${reset} $*${reset}\n"
