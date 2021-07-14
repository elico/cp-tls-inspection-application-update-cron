# Example of a crontab job

```
*/10 * * * * wget -q https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh -O /storage/cron-example-with-diff-dstdom.sh  >/dev/null 2>&1 && md5sum /storage/cron-example-with-diff-dstdom.sh |grep "^aaf096ee1b0b946f7be4d29186902bfb " && bash /storage/cron-example-with-diff-dstdom.sh NgTechBypassDstDomain https://gist.githubusercontent.com/elico/249034a199d17ce52524f47fad49964f/raw/bdd95d87232f8173185acc14540d58bfb2c9ff79/010-GeneralTLSInspectionBypass.dstdom >/dev/null 2>&1
```

# Example of update bash script 

```bash
#!/usr/bin/env bash
wget https://raw.githubusercontent.com/elico/cp-tls-inspection-application-update-cron/master/cron-example-with-diff-dstdom.sh \
        -O /storage/cron-example-with-diff-dstdom.sh && \
        md5sum /storage/cron-example-with-diff-dstdom.sh | grep "^aaf096ee1b0b946f7be4d29186902bfb " && \
        bash /storage/cron-example-with-diff-dstdom.sh NgTechBypassDstDomain https://gist.githubusercontent.com/elico/249034a199d17ce52524f47fad49964f/raw/bdd95d87232f8173185acc14540d58bfb2c9ff79/010-GeneralTLSInspectionBypass.dstdom
```
