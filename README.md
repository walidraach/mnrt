# Mindgenix Mobile Network Research Tool

## Installation for Kali 2021.2 and Ubuntu 20.10

`sudo ./install.sh`

## Usage

`sudo ./main.sh`

### 1. Scan for cells with Phone
  Scan for near 2G/3G/4G stations using a Samsung Galaxy S4/S5. Plug in to PC with USB cable with ADB Debugging enabled in Developer Settings. Hit CTRL+C when done to save the results to cells folder.
### 2. Scan for cells with BladeRF
  Scan for near 2G/3G/4G stations using your bladeRF. Enter the required bands to start scanning. Hit CTRL+C when done to save the results to cells folder.
### 3. Scan for near GSM cells using grgsm
  Scan for GSM stations with grgsm using RTL-SDR.
### 4. Scan for near GSM cells using kalibrate-rtl
  Scan for GSM stations with kalibrate-rtl. Using RTL-SDR, find the strongest frequency to sniff later on.
### 5. Scan for near GSM cells using kalibrate-bladeRF
  Scan for GSM stations with kalibrate-bladeRF. Using bladeRF, find the strongest frequency to sniff later on.
### 6. Sniff on specific freq
  Start sniffing for IMSI numbers using RTL-SDR or bladeRF. Enter the strongest frequency found from previous GSM scanning. 
### 7. Sniff for immediate assignment
  Start sniffing for Immediate Assignment while running GSM IMSI sniffer.
### 8. Jam cells
  Jam near 2G/3G/4G cells using bladeRF. Select the previous scanning results located in Modmobmap/cells directory.
### 9. LTE sniff with srsRAN
  Select the required operator and start a passive LTE station which collects IMSI, using bladeRF.

## Contributors

[Mindgenix Technology & Development](https://www.mindgenix.org)
