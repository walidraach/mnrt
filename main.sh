#!/bin/bash
# Bash Color
green='\e[32m'
red='\e[31m'
yellow='\e[33m'
blue='\e[34m'
lgreen='\e[92m'
lyellow='\e[93m'
lblue='\e[94m'
lmagenta='\e[95m'
lcyan='\e[96m'
blink_red='\033[05;31m'
restore='\033[0m'
reset='\e[0m'

# Upper windows
TOPLEFT="+10+10"
TOPRIGHT="-10+10"
TOP="-0+10"
# Lower windows
BOTTOMLEFT="+10-10"
BOTTOMRIGHT="-10-10"
BOTTOM="+0-10"

##############################################
# Functions
##############################################
# Pause
pwd=`pwd`
function pause() {
        local message="$@"
        [ -z $message ] && message="Press [Enter] to continue.."
        read -p "$message" readEnterkey
}

function ask() {
        # http://djm.me/ask
        while true; do

                if [ "${2:-}" = "Y" ]; then
                        prompt="Y/n"
                        default=Y
                elif [ "${2:-}" = "N" ]; then
                        prompt="y/N"
                        default=N
                else
                        prompt="y/n"
                        default=
                fi

                # Ask the question
                question
                read -p "$1 [$prompt] " REPLY

                # Default?
                if [ -z "$REPLY" ]; then
                        REPLY=$default
                fi

                # Check if the reply is valid
                case "$REPLY" in
                        Y*|y*) return 0 ;;
                        N*|n*) return 1 ;;
                esac
        done
}

function info() {
        printf "${lcyan}[   INFO   ]${reset} $*${reset}\n"
}

function success() {
        printf "${lgreen}[ SUCCESS  ]${reset} $*${reset}\n"
}
 
function warning() {
        printf "${lyellow}[ WARNING  ]${reset} $*${reset}\n"
}

function error() {
        printf "${lmagenta}[  ERROR  ]${reset} $*${reset}\n"
}

function question() {
        printf "${yellow}[ QUESTION ]${reset} $*${reset}\n"
}

function set_fpga() {
	info "Setting latest FPGA on bladeRF" && bladeRF-cli -l $pwd/hostedxA4-latest.rbf
}

function start-scan() {
	info "Starting scan via adb.." && sleep 2
	info "IMPORTANT: Remove the operators.json from cache folder to scan for new operators!" && sleep 2
	cd $pwd/Modmobmap
	if [ -f cache/operators.json ]; then OPTS=" -o"; else OPTS=""; fi
        xterm -geometry $TOP -e /bin/bash -c "echo \"Hit CTRL+C when done discovering stations\" && sleep 2 && python modmobmap.py$OPTS; echo \"Scanning completed\" && sleep 3" &
	info "Returning to menu.." && sleep 2
}

function start-scan-srsran() {
	read -p "Please enter the band to scan for, separete with comma for more [1,3,8,12,40]: " bands
	bands=${bands:-1,3,8,12,40}
        info "Starting scan via srsRAN.." && sleep 2
	set_fpga
        info "Hit CTRL+C when done (when no more stations show up)" && sleep 2
        cd $pwd/Modmobmap
        xterm -geometry $TOP -e /bin/bash -c "python modmobmap.py -m srsran_pss -b $bands -d bladerf;echo \"Exiting..\" && sleep 5" &
	info "Returning to menu.." && sleep 2
}

function apply_cells() {
	local ret=1
	scanfile="$pwd/Modmobmap/cells/$1"
	echo "$scanfile"
	printf "\n"
	cd $pwd/Modmobjam
	info "Checking for errors in selected file.." && sleep 2
	if [ "cat $scanfile | grep Unkn" != "" ]; then sed -i -r 's/\bUnkn\w+/10MHz/g' $scanfile; fi
        info "Starting jammer.." && sleep 2
	xterm -geometry $TOPLEFT -e /bin/bash -c "python3 jammer_gen.py;sleep 10" &
	sleep 10 && xterm -geometry $BOTTOMLEFT -e /bin/bash -c "python3 smartjam_rpcclient.py -f $scanfile;sleep 10" &
	printf "\n"
	info "Returning to menu.." && sleep 2
}

# Show all patches in the current directory
function show_cells() {
	clear
	local IFS opt f i
	printf "${lblue} ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n${reset}"
	printf "${lblue} Please choose the cells list to use\n${reset}"
	printf "${lblue} ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n${reset}"
	printf "\n"
	cd $pwd/Modmobmap/cells
        while IFS= read -r -d $'\0' f; do
                options[i++]="$f"
        done < <(find -L * -type f -print0 )
}

# Select a patch
function select_cells() {
	COLUMNS=12
        select opt in "${options[@]}" "Return"; do
                case $opt in
                        "Return")
			    cd -
                            return 1
                            ;;
                        *)
			    apply_cells $opt
			    return 0
                            ;;
                esac
        done
}

function start-grgsm() {
	info "Starting grgsm.." && sleep 2
	xterm -geometry $TOPLEFT -e /bin/bash -c "grgsm_scanner -v" &
	info "Returning to menu.." && sleep 2
}

function start-catcher-freq() {
        cd $pwd/IMSI-catcher
        read -p "Please enter the GSM frequency to sniff [942.2M]: " freq
	freq=${freq:-942.2M}
	read -p "Please enter device name to use [rtl] or bladerf: " device
	device=${device:-bladerf}
	info "Starting grgsm_livemon using $device on frequency $freq.." && sleep 2
	xterm -geometry $TOPRIGHT -e /bin/bash -c "grgsm_livemon -f $freq --args=$device" &
        xterm -geometry $BOTTOMRIGHT -e /bin/bash -c "python3 simple_IMSI-catcher.py --sniff --txt=$pwd/logs/gsm_imsi_results.txt" &
        info "Returning to menu.." && sleep 2
}

function start-immediate-catcher() {
        cd $pwd/IMSI-catcher
        info "Starting immedate assignment catcher.." && sleep 2
        xterm -geometry $BOTTOMRIGHT -e /bin/bash -c "python3 immediate_assignment_catcher.py" &
        info "Returning to menu.." && sleep 2
}

function start-scan-kal() {
        cd $pwd/kalibrate-rtl/src
        info "Starting scan with kalibrate-rtl" && sleep 2
        xterm -e /bin/bash -c "./kal -s GSM900 && read -p \"Scanning done, hit [Enter] to close\"" &
        info "Returning to menu.." && sleep 2
}

function start-scan-kal-blade() {
        cd $pwd/kalibrate-bladeRF/src
        info "Starting scan with kalibrate-bladeRF" && sleep 2
	set_fpga
        xterm -e /bin/bash -c "./kal -s GSM900 && read -p \"Scanning done, hit [Enter] to close\"" &
        info "Returning to menu.." && sleep 2
}

function start-srsran() {
        cd $pwd
	question "Please select a network name for the LTE station"
	options=("Zain" "Zain #2" "STC" "Test" "Telenor NORWAY" "Vodafone UK")
	select opt in "${options[@]}"
	do
    	    case $opt in
        	"Zain")
            		MCC=420 && MNC=07 && break
            		;;
        	"Zain #2")
            		MCC=420 && MNC=04 && break
            		;;
        	"STC")
            		MCC=420 && MNC=01 && break
            		;;
                "Test")
                        MCC=001 && MNC=01 && break
                        ;;
                "Telenor NORWAY")
                        MCC=242 && MNC=01 && break
                        ;;
                "Vodafone UK")
                        MCC=234 && MNC=15 && break
                        ;;
        	*) echo "invalid option $REPLY";;
	    esac
	done
	info "Setting network to $MCC$MNC" && sleep 2
        sed -i "s/.*mcc = .*/mcc = $MCC/" configs/epc.conf && sed -i "s/.*mnc = .*/mnc = $MNC/" configs/epc.conf
        sed -i "s/.*mcc = .*/mcc = $MCC/" configs/enb.conf && sed -i "s/.*mnc = .*/mnc = $MNC/" configs/enb.conf
        info "Starting srsRAN" && sleep 2
	set_fpga
        xterm -geometry $TOPLEFT -e /bin/bash -c "srsepc configs/epc.conf" &
        xterm -geometry $TOPRIGHT -e /bin/bash -c "srsenb configs/enb.conf" &
	xterm -geometry $BOTTOM -e /bin/bash -c "cd logs && watch -n 1 ./extract_details.sh | tee -a lte_imsi_detailed.txt || cp lte_imsi_detailed.txt lte_imsi_detailed_$(date +%F-%H-%M).txt && >lte_imsi_results.txt && read -p \" Output written to file, hit [Enter] to close\"" &
        info "Returning to menu.." && sleep 2
}

# Banner
show_banner() {
printf "\t _______ __           __                     __\n"
printf "\t|   |   |__|.-----.--|  |.-----.-----.-----.|__|.--.--.\n"
printf "\t|       |  ||     |  _  ||  _  |  -__|     ||  ||_   _|\n"
printf "\t|__|_|__|__||__|__|_____||___  |_____|__|__||__||__.__|\n"
printf "\t${lcyan}----Mobile----Network----${reset}$*${reset}|_____|${lcyan}----Research----Tool----${reset} $*${reset}\n\n"
}

# Read passive menu choices
read_passive_choice(){
        local passivechoice
        read -p "Enter selection: " passivechoice
        case ${passivechoice,,} in
                1)
                   start-scan
                   ;;
                2)
                   start-scan-srsran
                   ;;
                3)
                   start-grgsm
                   ;;
		4)
                   start-scan-kal
                   ;;
                5)
                   start-scan-kal-blade
                   ;;
                6)
                   start-catcher-freq
                   ;;
                7)
                   start-immediate-catcher
                   ;;
                8)
                   show_cells
                   select_cells
                   ;;
                9)
                   start-srsran
                   ;;
                e)
                   info "Exiting..\n\n"
                   exit
                   ;;
                *)
                   error "Please select a valid option" && sleep 2
        esac
}


# Passive Menu
function passive_menu() {
        clear
	show_banner
	printf "\t1) Scan for cells with Phone\n"
	printf "\t2) Scan for cells with BladeRF\n"
        printf "\t3) Scan for near GSM cells using grgsm (RTL-SDR)\n"
        printf "\t4) Scan for near GSM cells using kalibrate-rtl (RTL-SDR)\n"
        printf "\t5) Scan for near GSM cells using kalibrate-bladeRF\n"
        printf "\t6) Start GSM Sniffing on specific freq\n"
	printf "\t7) Start GSM Sniffing for immediate assignment\n"
	printf "\t8) Jam cells\n"
        printf "\t9) Start LTE sniffing with srsRAN\n"
	printf "\tE) Exit\n\n"
}

# Main
while true
do
        passive_menu
	read_passive_choice
done
