#!/bin/bash
# ALP - Apache Log Parser
# 9/Oct/2015 - Jacob.Nicholson@rackspace.com

function parse {
 MIN=$1
 if [ -z "$2" ]; then SHOW=10; else SHOW=$2; fi; \
 if [ -z "$3" ]; then MINSAGO=$(date "+%d/%b/%Y:%H:%M" --date="$MIN min ago" | sed 's#/#\\/#g'); else MINSAGO=$(echo $3 | sed 's#/#\\/#g'); fi; \
 if [ -z "$4" ]; then NOW=$(date "+%d/%b/%Y:%H:%M" | sed 's#/#\\/#g'); else NOW=$(echo $4 | sed 's#/#\\/#g'); fi; \
 for log in $(ls -1 /var/log/httpd/*access*log); \
 do \
 LOG=$(echo $log | awk -F "/" '{print $NF}'); \
 HITS=$(tail -10000 $log | awk "/$MINSAGO/,/$NOW/ {print}"); \
 if [[ $(echo "$HITS" | wc -l) -ge 10 ]]; \
 then MIN_START=$(echo $MINSAGO | sed 's#\\##g'); MIN_STOP=$(echo $NOW | sed 's#\\##g'); \
 echo -e "\n$(tput bold)$(tput setaf 2)$log had $(echo "$HITS" | wc -l) hits between [$MIN_START - $MIN_STOP]$(tput sgr0)\n"; \
 echo -e "=== Duplicate requests [$MIN_START - $MIN_STOP] ===\n"; \
 echo "$HITS" >> /home/rack/LOGS/$LOG"-RAW"; \
 echo "$HITS" | awk -v M=$MIN_START -v N=$MIN_STOP '{REQ[$1" "$6" "$7]++}END{for (i in REQ) print "["M" - "N"]",REQ[i],i}' | sort -nk4 | tail -$SHOW | tee -a /home/rack/LOGS/$LOG"-DUPE" | sed 's#^.*]##'; \
 echo -e "\n=== IP hits [$MIN_START - $MIN_STOP] ===\n"; \
 echo "$HITS" | awk -v M=$MIN_START -v N=$MIN_STOP '{REQ[$1]++}END{for (i in REQ) print "["M" - "N"]",REQ[i],i}' | sort -nk4 | tail -$SHOW | tee -a /home/rack/LOGS/$LOG"-IPs" | sed 's#^.*]##' ; \
 echo -e "\n=== User-Agents [$MIN_START - $MIN_STOP] ===\n"; \
 echo "$HITS" | awk -v M=$MIN_START -v N=$MIN_STOP '{REQ[substr($0, index($0, $12))]++}END{for (i in REQ) print "["M" - "N"]",REQ[i],i}' | sort -nk4 | tail -$SHOW | tee -a /home/rack/LOGS/$LOG"-Agents" | sed 's#^.*]##'; \
 echo
 echo
 read -p "Press [Enter] to move on to next log file..."; \
 echo
 fi;done
 exit
}

function clearLogs {
 echo -e "\nClearing logs...\n"
 rm -rf /home/rack/LOGS/*
}

function help {
 echo -e "\n$(tput bold)$(tput setaf 2)Welcome to Jacob's ALP (Apache Log Parser)$(tput sgr0)"
 echo -e "Usage: /home/rack/alp $(tput bold)$(tput setaf 4)MINUTES $(tput setaf 5)RESULTS $(tput setaf 6)TIME-START $(tput setaf 7)TIME-STOP$(tput sgr0)"
 echo
 echo -e "$(tput bold)$(tput setaf 4)MINUTES = Value in minutes you'd like to look back in logs$(tput sgr0)"
 echo -e "$(tput bold)$(tput setaf 5)RESULTS = Number of unique results you'd like to see$(tput sgr0)"
 echo
 echo "Example: $(tput bold)$(tput setaf 2)/home/rack/alp $(tput setaf 4)1 $(tput setaf 5)5$(tput sgr0)"
 echo "Example: $(tput bold)$(tput setaf 2)/home/rack/alp $(tput setaf 4)1 $(tput setaf 5)5 $(tput setaf 6)10/Oct/2015:03:49 $(tput setaf 7)10/Oct/2015:03:50$(tput sgr0)"
 echo
 echo "$(tput bold)$(tput setaf 2)/var/log/httpd/example.com-access.log had 10 hits between [10/Oct/2015:03:49 - 10/Oct/2015:03:50]$(tput sgr0)"
 echo
 echo "=== IP hits last (1) mins ==="
 echo "[10/Oct/2015:03:49 - 10/Oct/2015:03:50]"
 echo "1 157.55.39.40"
 echo "1 50.57.61.21"
 echo "1 78.136.44.6"
 echo "2 157.55.39.39"
 echo "4 157.55.39.181"
 echo
 echo "=== User-Agents last (1) mins ==="
 echo "[10/Oct/2015:03:49 - 10/Oct/2015:03:50]"
 echo '2 "Rackspace Monitoring/1.1 (https://monitoring.api.rackspacecloud.com)"'
 echo '8 "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"'
 echo
 echo "Each time this script is run, it will attempt to log types"
 echo -e "of requests to logs such as [$(tput bold)$(tput setaf 2)/home/rack/LOGS/domain.tld-access-log-IPs$(tput sgr0)]\n"
 exit
}

case "$1" in
 [1-9]*) parse $1 $2 $3 $4 ;;
 help) help ;;
 clear) clearLogs ;;
    *) help ;;
esac

#if [ -z "$1" ]
# then help
#elif [[ "$1" -eq "clear" ]]
# then clearLogs
#else
#while getopts 'm:r:s:e:f:h' flag; do
#  case "${flag}" in
#    m) MIN=$OPTARG ;;
#    r) RESULTS=$OPTARG ;;
#    s) START=$OPTARG ;;
#    e) END=$OPTARG ;;
#    f) files="${OPTARG}" ;;
#    h) help ;;
#    ?) help ;;
#    *) error "Unexpected option ${flag}" ;;
#  esac
#done
#parse $MIN $RESULTS $START $END
#fi
