#/bin/bash
format="%20s %35s %-35s %4s %4s \n"
printf "$format" "IMSI ;" "country ;" " operator ;" " MCC ;" " MNC"
printf "%50s \n" "-------------------------------------------------------------------------------------------------------------"
cat lte_imsi_results.txt | awk '!seen[$0]++' | while read line
  do
    MCC=$(echo $line | cut -c1-3)
    MNC=$(echo $line | cut -c4-6)
    COUNTRY=$(grep "$MCC $MNC" ../configs/imsi_carriers.txt | cut -d ';' -f1)
    OP=$(grep "$MCC $MNC" ../configs/imsi_carriers.txt | cut -d ';' -f2)
    if [ "$COUNTRY" = "" ]; then
      MNC=$(echo $line | cut -c4-5)
      COUNTRY=$(grep -w "$MCC $MNC" ../configs/imsi_carriers.txt | cut -d ';' -f1)
      OP=$(grep -w "$MCC $MNC" ../configs/imsi_carriers.txt | cut -d ';' -f2)
    fi
    printf "$format" "$line ;" " $COUNTRY ;" "$OP ;" " $MCC ;" " $MNC"
 done
