#!/bin/dash

#nastaveni se bude ukladat v ~/.tm_set
#FUNKCE
#begin [jmeno obdobi] //zalozi nove obdobi a nastavi ho jako aktualni
#start [aktivita] //+ nejaka optiona na pripadne stopnuti aktualne bezici aktivity
#stop [aktivita] //upozorneni pokud neni spustena
#set [dir]  = nastaveni adresare, kam se budou ukladat souhrny za jednotlive tydny
#multi +/- = muze byt naraz spustenych vice aktivit? (pokud ne a uzivatel chce startnout novou, nedovoli mu to, jinak jen vypise upozorneni, ze jeste bezi)
#autostop +/- = + znamena automaticke stopovani spustenych aktivit pri startu novych
#multi i autostop DEFAULT -
#status: vypise vybrany adresar pro ukladani, aktualni stage, nastaveni multi a autostop, vypsane wages a AKTUALNE BEZICI AKTIVITY
#wage [aktivita] h/m/s [cislo] [jednotka] nastavi 'wage' za danou aktivitu za kazdou zapocatou h-hodinu/m-minutu/s-sekundu 
#recap [-w] [obdobi] = zrekapituluje zadane obdobi (nepovinne pouze jednu aktivitu) //-w navic vypocte wage

#format '.tm_set':
#prvni radek: nastaveny adresar pro ukladani
#druhy radek: jmeno aktualniho obdobi
#treti radek: seznam wages (resp ";", pokud nenastaveno); format: [aktivita]:h/m/s:[mnozstvi]:[unit];
#ctvrty radek: "(+/-);(+\-)" = prvni +/- multi, druhe autostop

settingsFile=~/.tm_set

usage() {
    echo ""
    echo "USAGE FOR $0:"
    echo "COMMANDS: set [dir]:        sets saving directory to 'dir'"
    echo "          begin [stage]:    begins a new stage (you can also use just 'b [stage]' for short)"
    echo "          start [activity]: starts the selected activity (just 's' for short)"
    echo "          stop [activity]:  stops the selected activity if running ('S' for short)"
    echo "          multi [+/-]:      sets (+) or unsets (-) the MULTI option, which enables you to have multiple activities running at the same time (default -; you can use 'm+'/'m-' for short)"
    echo "          autostop [+/-]:   sets (+) or unsets (-) the AUTOSTOP option, which makes sure that all running activities get stopped when a new one is started (default -; use 'a+'/'a-' for short)"
    echo "          status:           prints current settings and currently running activities"
    echo "          wage [activity] [h/m/s] [wage] [unit]: sets the wage of 'activity' to 'wage' 'unit's per hour/minute/second (depending on the h/m/s option)"
    echo "          recap [-w] [stage]: prints for how long each activity ran during selected stage (only stopped activities)"
    echo "                              -w (optional) also counts and prints the respective wage"
    echo "                              if no stage is set, the current one will be chosen"
    echo ""
    echo "WARNING: only letters from English alphabet are permited for activity/stage/unit names"
    echo ""
}
handleUnsetError() {   #jeden parametr: 1 pokud je potreba jen nastavit saving adresar, jinak 0
    echo "save directory unset; where would you like to have the timemaster metadata stored?"
    read dir
    doSet "$dir"
    if [ "$1" = 1 ]; then return 0; fi
    echo "how would you like to name the current stage?"
    read stage
    doBegin "$stage"
}
doSet() { #parametr = cesta k adresari
    if [ ! -f "$1" ] && [ ! -d "$1" ]; then mkdir "$1"; fi
    dirName=$(cd "$1"; echo $PWD)  #kdyby byla zadana relativni adresa
    if [ -f "$settingsFile" ]; then
        sed '2 i\'"$dirName"'' "$settingsFile" | tail -n +2 > .__temp_file
        cat .__temp_file > "$settingsFile"
        rm .__temp_file 
    else
        echo "$dirName" > "$settingsFile"
	echo "unset" >> "$settingsFile"
	echo ";" >> "$settingsFile"
        echo "-;-" >> "$settingsFile"
    fi
    echo "save directory set to $dirName"
}
doBegin() { #parametr jmeno obdobi
    if [ ! -f "$settingsFile" ]; then handleUnsetError 1; fi
    saveDir=`sed -n '1p' < "$settingsFile"`
    if [ -f "$saveDir/$1.tm" ]; then
        echo "INFO: $1 is already a stage (reopening it)"
    else
        > "$saveDir/$1.tm"
    fi
    sed -n '1p' < "$settingsFile" >> "$settingsFile"
    echo "$1" >> "$settingsFile"
    sed -n '3p' < "$settingsFile" >> "$settingsFile"
    sed -n '4p' < "$settingsFile" >> "$settingsFile"
    tail -n +5 "$settingsFile" > .__temp_file
    cat .__temp_file > "$settingsFile"
    rm .__temp_file 
    echo "stage set to $1"
}
#utility pro startStop:
autostop() {  #dva parametry: cela cesta k saving souboru a nazev aktivity
    nowDate=$(date +%s)
    echo "$2-$nowDate" >> "$1"
    echo "autostopping $2"
}
handleUnstopped() {  #jediny parametr line; bude upravovat .__temp_unstopped
    pm=`echo "$1" | sed 's|[a-zA-Z]*\([+-]\)[0-9]*|\1|'`
    activity=`echo "$1" | sed 's|\([a-zA-Z]*\).*|\1|'`
    if [ "$pm" = "+" ]; then
        echo "$activity" >> .__temp_unstopped
        temp=`cat .__temp_unstopped | tr '\n' ';'`
        echo "$temp" > .__temp_unstopped
    else
        temp=`cat .__temp_unstopped | sed 's|\(.*\)'"$activity"'\(.*\)|\1\2|'`
        echo "$temp" > .__temp_unstopped
    fi
}
doStartStop() {  #dva parametry: nazev aktivity, +/-, tj. zda start, nebo stop
    if [ ! -f "$settingsFile" ]; then handleUnsetError 0; fi
    nowDate=$(date +%s)
    saveDir=`sed -n '1p' < "$settingsFile"`
    if [ ! -f "$saveDir" ] && [ ! -d "$saveDir" ]; then mkdir "$saveDir"; fi
    stageName=`sed -n '2p' < "$settingsFile"`

    #overovani spravnych podminek:
    if [ -f "$saveDir/$stageName.tm" ]; then
        if [ "$2" = + ]; then
            > .__temp_unstopped  #bude slouzit k ukladani nestopnutych aktivit (v teto fazi oddelenych stredniky)
            while read line; do
                handleUnstopped "$line"
            done < "$saveDir/$stageName.tm"
            temp=`cat .__temp_unstopped | tr ';' '\n'`
            echo "$temp" > .__temp_unstopped
            multi=`sed -n '4p' < "$settingsFile" | sed 's|\([+-]\);[+-]|\1|'`
            autostop=`sed -n '4p' < "$settingsFile" | sed 's|[+-];\([+-]\)|\1|'`
            while read line; do
                if [ "$line" = "" ]; then continue; fi
                if [ "$multi" = "-" ] && [ "$autostop" = "-" ]; then
                    echo "$line is not stopped yet"
                    return 0
                fi
                if [ "$autostop" = "+" ]; then
                    autostop "$saveDir/$stageName.tm" "$line"
                else
                    if [ "$1" = "$line" ]; then
                        echo "$1 isn't stopped yet; aborting start"
                        return 0
                    else
                        echo "INFO: $line wasn't stopped yet"
                    fi
                fi
            done < .__temp_unstopped
            rm .__temp_unstopped
        else
            strt=`cat "$saveDir/$stageName.tm" | grep "$1+"`
            if [ -z "$strt" ]; then
                echo "$1 never started"
                return 0
            fi
            stp=`cat "$saveDir/$stageName.tm" | tr '\b' '\1' | sed 's|.*'"$1"'+\(.*\)|\1|' | tr '\1' '\n' | grep "$1-"`
            if [ ! -z "$stp" ]; then
                echo "$1 is already stopped"
                return 0
            fi
        fi
    fi

    echo "$1$2$nowDate" >> "$saveDir/$stageName.tm"
    if [ "$2" = + ]; then echo "started $1"; else echo "stopped $1"; fi
}
printMultiStarted() { #vypise aktualne bezici aktivity; tri parametry - co napsat pred a po nazvu aktivity, a 0/1 jestli vypsat odkdy bezi
    if [ ! -f "$settingsFile" ]; then handleUnsetError 0; fi
    saveDir=`sed -n '1p' < "$settingsFile"`
    stageName=`sed -n '2p' < "$settingsFile"`
    > .__temp_unstopped  #bude slouzit k ukladani nestopnutych aktivit (v teto fazi oddelenych stredniky)
    while read line; do
        handleUnstopped "$line"
    done < "$saveDir/$stageName.tm"
    temp=`cat .__temp_unstopped | tr ';' '\n'`
    echo "$temp" > .__temp_unstopped
    while read unstop; do
        if [ -z "$unstop" ]; then continue; fi
        since=""
        if [ "$3" = "1" ]; then
            since=`cat "$saveDir/$stageName.tm" | tr '\n' ';' | sed 's|.*;'"$unstop"'+\([0-9]*\).*|\1|'`
            #since=`date -d '1970-01-01 UTC + '"$since"' seconds'`
            since=`perl -le 'print scalar localtime $ARGV[0]' $since`
            since=" from $since"
        fi
        echo "$1$unstop$2$since"
    done < .__temp_unstopped
    rm .__temp_unstopped
}
doMulti() {  #jeden parametr (+/-)
    if [ ! -f "$settingsFile" ]; then handleUnsetError 1; fi
    currAutostop=`sed -n '4p' < "$settingsFile" | sed 's|[+-];\([+-]\)|\1|'`
    sed '4 i\'"$1"';'"$currAutostop"'' "$settingsFile" | head -4 > .__temp_file
    cat .__temp_file > "$settingsFile"
    rm .__temp_file
    if [ "$1" = "+" ]; then
        echo "enabled multiple activities running simultaneously"
    else
        echo "disabled multiple activities running simultaneously"
        printMultiStarted "WARN: " " is still running" 0
    fi
}
doAutostop() {  #jeden parametr (+/-)
    currMuddlti=`sed -n '4p' < "$settingsFile" | sed 's|\([+-]\);[+-]|\1|'`
    sed '4 i\'"$currMulti"';'"$1"'' "$settingsFile" | head -4 > .__temp_file
    cat .__temp_file > "$settingsFile"
    rm .__temp_file
    if [ "$1" = "+" ]; then
        echo "unstopped activities will be stopped automatically when starting new ones"
    else
        echo "autostop disabled"
    fi
}
doStatus() {
    echo ""
    saveDir=`sed -n '1p' < "$settingsFile"`
    if [ ! -f "$saveDir" ] && [ ! -d "$saveDir" ]; then mkdir "$saveDir"; fi
    stageName=`sed -n '2p' < "$settingsFile"`
    echo "saving directory: $saveDir"
    echo "current stage: $stageName"
    multi=`sed -n '4p' < "$settingsFile" | sed 's|\([+-]\);[+-]|\1|'`
    autostop=`sed -n '4p' < "$settingsFile" | sed 's|[+-];\([+-]\)|\1|'`
    endis="disabled"
    if [ "$multi" = "+" ]; then endis="enabled"; fi
    echo "multistart $endis"
    if [ "$autostop" = "+" ]; then endis="enabled"; else endis="disabled"; fi
    echo "autostop $endis"

    #vypsani wages:
    echo ""
    wageLine=`cat "$settingsFile" | sed -n '3p'`
    if [ "$wageLine" = ";" ]; then
        echo "wages unset"
    else
        echo "$wageLine" | tr ';' '\n' > .__temp_file
        while read line; do
            if [ -z "$line" ]; then continue; fi
            activity=`echo "$line" | sed 's|\([a-zA-Z]*\):.*|\1|'`
            hms=`echo "$line" | sed 's|[a-zA-Z]*:\([hms]\):.*|\1|'`
            if [ "$hms" = "h" ]; then hms="hour"; elif [ "$hms" = "m" ]; then hms="minute"; else hms="second"; fi
            transfer=`echo "$line" | sed 's|.*:\([0-9]*\)*:.*|\1|'`
            unit=`echo "$line" | sed 's|.*:\([a-zA-Z]*\)|\1|'`
            echo "WAGE for $activity set to $transfer $unit per $hms"
        done < .__temp_file
        rm .__temp_file
    fi

    echo ""
    echo "CURRENTLY RUNNING ACTIVITIES:"
    #vypsani unstopnutych aktivit
    printMultiStarted "" "" 1
    echo ""
}

doWage() {
    #parametry:
    activity=$1
    hms=$2
    transfer=$3
    unit=$4

    wageLine=`cat "$settingsFile" | sed -n '3p'`
    occur=`echo "$wageLine" | grep ";$activity:[hms]"`
    if [ -z "$occur" ]; then
        wageLine="$wageLine$activity:$hms:$transfer:$unit;"
    else
        echo "This activity already has a wage assigned. Do you wish to rewrite it? [y/n]"
        while read response; do
            if [ "$response" != "y" ] && [ "$response" != "n" ]; then
                echo "invalid response; write 'y' or 'n'"
                continue
            else
                if [ "$response" = "n" ]; then return 0; fi
                wageLine=`echo "$wageLine" | sed 's|\(.*;\)'"$activity"':[hms]:[0-9]*:[a-zA-Z]*\(;.*\)|\1'"$activity:$hms:$transfer:$unit"'\2|'`
                break
            fi
        done
    fi
    sed -n '1p' < "$settingsFile" >> "$settingsFile"
    sed -n '2p' < "$settingsFile" >> "$settingsFile"
    echo "$wageLine" >> "$settingsFile"
    sed -n '4p' < "$settingsFile" >> "$settingsFile"
    temp=`cat "$settingsFile" | tail -n +5`
    echo "$temp" > "$settingsFile"
    echo "Wage recorded"
}

updateSums() { #upravi .__temp_sums a .__temp_file podle prijate radky
    pm=`echo "$1" | sed 's|[a-zA-Z]*\([+-]\)[0-9]*|\1|'`
    activity=`echo "$1" | sed 's|\([a-zA-Z]*\)[+-][0-9]*|\1|'`
    timestamp=`echo "$1" | sed 's|[a-zA-Z]*[+-]\([0-9]*\)|\1|'`
    if [ "$pm" = "+" ]; then
        new="$activity$timestamp;"
        temp=`cat .__temp_file | sed 's|\(.*\)|\1'"$new"'|'`
        echo "$temp" > .__temp_file
    else
        startTime=`cat .__temp_file | sed 's|.*;'"$activity"'\([0-9]*\);.*|\1|'`
        diff=$((timestamp-startTime))
        occur=`cat .__temp_sums | grep ";$activity[0-9]*"`
        if [ ! -z "$occur" ]; then
            curTime=`cat .__temp_sums | sed 's|.*;'"$activity"'\([0-9]*\).*|\1|'`
            timestamp=$((curTime+diff))
            temp=`cat .__temp_sums | sed 's|\(.*;\)'"$activity"'[0-9]*;\(.*\)|\1'"$activity$timestamp"';\2|'`
            echo "$temp" > .__temp_sums
        else
            temp=`cat .__temp_sums | sed 's|\(.*\)|\1'"$activity$diff"';|'`
            echo "$temp" > .__temp_sums
        fi
    fi
}
doRecap() {  #dva parametry: +/- urcujici, jestli vypisovat wage, jmeno stage
    #casy budu ukladat v sekundach do .__temp_sums ve formatu
    #[jmeno aktivity][pocet sekund behu];
    #navic budu do .__temp_file ukladat cas zacatku, podle ktereho zjistim rozdil (vzdy [jmeno aktivity][pocatecni cas];
    if [ ! -f "$settingsFile" ]; then echo "nothing to recap"; return 1; fi
    saveDir=`sed -n '1p' < "$settingsFile"`
    stageName="$2"
    if [ ! -f "$saveDir/$stageName.tm" ]; then echo "no data for this stage"; return 1; fi

    echo ";" > .__temp_file
    echo ";" > .__temp_sums
    while read line; do
        updateSums "$line"
    done < "$saveDir/$stageName.tm"

    if [ "$1" = "+" ]; then wageLine=`cat "$settingsFile" | sed -n '3p'`; fi
    temp=`cat .__temp_sums | tr ';' '\n'`
    echo "$temp" > .__temp_sums
    while read sum; do
        if [ -z "$sum" ]; then continue; fi
        activity=`echo "$sum" | sed 's|\([a-zA-Z]*\)[0-9]*|\1|'`
        timestamp=`echo "$sum" | sed 's|[a-zA-Z]*\([0-9]*\)|\1|'`
        hours=$((timestamp/3600))
        mins=$(( (timestamp-hours*3600)/60 ))
        secs=$((timestamp-hours*3600-mins*60))
        writeLine="$activity: $hours:$mins:$secs"
        if [ "$1" = "+" ]; then    #ma se pocitat wage?
            occur=`echo "$wageLine" | grep ".*;$activity:"`
            if [ -z "$occur" ]; then
                writeLine="$writeLine (no wage assigned)"
            else
                occur=`echo "$wageLine" | sed 's|.*;'"$activity"':\([hms]:[0-9]*:[a-zA-Z]*\);|\1|'`
                hms=`echo "$occur" | sed 's|\([hms]\).*|\1|'`
                transfer=`echo "$occur" | sed 's|.*:\([0-9]*\):.*|\1|'`
                unit=`echo "$occur" | sed 's|.*:\([a-zA-Z]*\)|\1|'`
                count=$hours
                if [ "$hms" = "m" ]; then
                    count=$((timestamp/60))
                elif [ "$hms" = "s" ]; then
                    count=$timestamp
                fi
                wage=$((transfer*count))
                writeLine="$writeLine -corresponding wage: $wage $unit"
            fi
        fi
        echo "$writeLine"
    done < .__temp_sums
    rm .__temp_file
    rm .__temp_sums
}

first=${1}
if [ "$first" = "-h" ] || [ "$first" = "--help" ]; then
    usage;
    exit 0
fi
case "$first" in
    start)
        doStartStop $2 "+"
    ;;
    s)
        doStartStop $2 "+"
    ;;
    stop)
        doStartStop $2 "-"
    ;;
    S)
        doStartStop $2 "-"
    ;;
    set)
        doSet $2
    ;;
    begin)
        doBegin $2
    ;;
    b)
        doBegin $2
    ;;
    multi)
        if [ "$2" != + ] && [ "$2" != - ]; then 
            echo "invalid argument $2"
        fi
        doMulti $2
    ;;
    m+)
        doMulti "+"
    ;;
    m-)
        doMulti "-"
    ;;
    autostop)
        if [ "$2" != + ] && [ "$2" != - ]; then 
            echo "invalid argument $2"
        fi
        doAutostop "$2"
    ;;
    a+)
        doAutostop "+"
    ;;
    a-)
        doAutostop "-"
    ;;
    wage)
        doWage $2 $3 $4 $5
    ;;
    recap)
        withWage="-"
        if [ "$2" = "-w" ]; then
            withWage="+"
            stage="$3"
        else
            stage="$2"
        fi
        #pri nenastavene stage vypis aktualni
        if [ -z "$stage" ]; then
            if [ ! -f "$settingsFile" ]; then echo "ERROR: no data for recap"; return 1; fi
            saveDir=`sed -n '1p' < "$settingsFile"`
            stageName=`sed -n '2p' < "$settingsFile"`
            if [ ! -d "$saveDir" ] || [ ! -f "$saveDir/$stageName.tm" ]; then echo "no data for this stage"; return 1; fi
            stage="$stageName"
        fi

        doRecap "$withWage" "$stage"
    ;;
    status)
        doStatus
    ;;
    *)
        echo "unsupported command: $first"
    ;;
esac
