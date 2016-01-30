#/bin/gawk -f

function getHHMMSS(seconds){
        s = seconds
        h=int(s/3600);
        s=s-(h*3600);
        m=int(s/60);
        s=s-(m*60);
        return sprintf("%02s:%02s:%02s", h, m, s)
}

function isAValidIP(n){
        split(n,octets,".")
        return ((octets[1] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octets[2] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octets[3] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/) &&
                (octets[4] ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/))
}

BEGIN{
        FS=":"

        email="administrator@mydomain.com"

# BGP Neighbour 1
        S_IP="192.0.2.1"
        S_name="Neigh_1"
        S_lastDate_UP=""
        S_lastDate_DOWN=""
        S_amountOfFailures=0
        S_totalOfFailures=0
        show_neighbour_1=0

# BGP Neighbour 2
        C_IP="192.0.2.2"
        C_name="Neigh_2"
        C_lastDate_UP=""
        C_lastDate_DOWN=""
        C_amountOfFailures=0
        C_totalOfFailures=0
        show_neighbour_2=0
}
{
        year=substr($1,0,4)
        month=substr($1,6,2)
        day=substr($1,9,2)
        hour=substr($1,12,2)
        minute=$2
        second=substr($3,0,2)

        if (( $4 ~ /^ %ADJCHANGE/ ) && ( $5 ~ /^ neighbor /)){
                split($5,description," ")
                if (description[2] == S_IP){
                        show_neighbour_1=1
                        if (description[3] == "Down"){
                                S_timeDown=mktime(year" "month" "day" "hour" "minute" "second)
                                S_lastDate_DOWN=year"/"month"/"day" "hour":"minute":"second
                        }else if (description[3] == "Up"){
                                S_timeUp=mktime(year" "month" "day" "hour" "minute" "second)
                                S_lastDate_UP=year"/"month"/"day" "hour":"minute":"second
                                S_amountOfFailures++
                                if (!S_lastDate_DOWN){
                                        S_lastDate_DOWN=year"/"month"/"day" 00:00:00"
                                        S_timeDown=mktime(year" "month" "day" 00 00 00")
                                }
                                S_failureStart[S_amountOfFailures]=S_lastDate_DOWN
                                S_failureEnd[S_amountOfFailures]=S_lastDate_UP
                                S_failure[S_amountOfFailures]= S_timeUp - S_timeDown
                                S_totalOfFailures+=S_failure[S_amountOfFailures]
                        }
                } else if (description[2] == C_IP){
                        show_neighbour_2=1
                        if (description[3] == "Down"){
                                C_timeDown=mktime(year" "month" "day" "hour" "minute" "second)
                                C_lastDate_DOWN=year"/"month"/"day" "hour":"minute":"second
                        }else if (description[3] == "Up"){
                                C_timeUp=mktime(year" "month" "day" "hour" "minute" "second)
                                C_lastDate_UP=year"/"month"/"day" "hour":"minute":"second
                                C_amountOfFailures++
                                if (!C_lastDate_DOWN){
                                        C_lastDate_DOWN=year"/"month"/"day" 00:00:00"
                                        C_timeDown=mktime(year" "month" "day" 00 00 00")
                                }
                                C_failureStart[C_amountOfFailures]=C_lastDate_DOWN
                                C_failureEnd[C_amountOfFailures]=C_lastDate_UP
                                C_failure[C_amountOfFailures]= C_timeUp - C_timeDown
                                C_totalOfFailures+=C_failure[C_amountOfFailures]
                        }
                }
        }
}
END {
        output="From: BGP ALARM <"email">\n"
        output=output"Subject: BGP ALARM - "date" \n"
        output=output"Content-type: text/html\n\n"

        output=output"<h3> BGP session's failure </h3>"
        if (show_neighbour_1){
                output=output"<table border=1><caption>"S_name" ("S_IP")</caption><thead><tr><th>Start</th><th>End</th><th>Duration</th></tr></thead></tbody>"
                for (i=1; i <= S_amountOfFailures; i++){
                        output=output"<tr><td>"S_failureStart[i]"</td><td>"S_failureEnd[i]"</td><td>"getHHMMSS(S_failure[i])"</td></tr>"
                }
                if (S_timeDown > S_timeUp){
                        output=output"<tr><td>"S_lastDate_DOWN"</td><td><b style=\"color:red;\">Still DOWN</b></td><td>...</td></tr>"
                }
                output=output"</tbody></table><p>Total of <b>"S_amountOfFailures"</b> outages, summarizing "S_totalOfFailures" seconds ("getHHMMSS(S_totalOfFailures)")</p>"
                print "Neighbour 1: Amount of outages = "S_amountOfFailures" summarizing a total of "S_totalOfFailures" seconds ("getHHMMSS(S_totalOfFailures)")"
        }

        if (show_neighbour_2){
                output=output"<table border=1><caption>"C_name" ("C_IP")</caption><thead><tr><th>Start</th><th>End</th><th>Duration</th></tr></thead></tbody>"
                for (i=1; i <= C_amountOfFailures; i++){
                        output=output"<tr><td>"C_failureStart[i]"</td><td>"C_failureEnd[i]"</td><td>"getHHMMSS(C_failure[i])"</td></tr>"
                }
                if (C_timeDown > C_timeUp){
                        output=output"<tr><td>"C_lastDate_DOWN"</td><td><b style=\"color:red;\">Still DOWN</b></td><td>...</td></tr>"
                }
                output=output"</tbody></table><p>Total of <b>"C_amountOfFailures"</b> outages, summarizing "C_totalOfFailures" seconds ("getHHMMSS(C_totalOfFailures)")</p>"
                print "Neighbour 2: Amount of outages = "C_amountOfFailures" summarizing a total of "C_totalOfFailures" seconds ("getHHMMSS(C_totalOfFailures)")"
        }

        if (show_neighbour_1 || show_neighbour_2){
                system("echo '"output"' | sendmail "email)
        }
}
