#!/bin/bash

BKP="backup-`date +%Y%m%d%H%M%S`"
mkdir ${BKP}
cp *csv ${BKP}/
mv *log ${BKP}/

echo "Restoring JIRAID into [0-9]*-*csv files"
sed -i -re 's/ENTMQIC-[0-9]+/JIRAID/g' [0-9]*-*csv
