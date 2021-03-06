#!/bin/bash
# 2012-Feb-16 to filter respair.lst
# for rendering in pymol: entries are mostly <0.5 + 
# reformatted so that it's the same as hb.txt

#start_with="sliceAB-"
start_with="clusterAB"

for fldr in $(ls -l | grep '^d' | grep $start_with| awk '{print $NF}')
do
  cd $fldr
  outfile=$fldr"-respair.csv"

  if [[ -f "respair.lst" ]]; then
    echo $fldr
    getnon0rows.sh respair.lst 0.99
    sed -e '/residue/d' -e 's/\([A-Z]\)[+|-]/\1/'  -e 's/\([0-9]\)_/\1/g' respair.lst.non0 | awk '{print $1"\t"$2"\t"$5}' > $outfile
    /bin/rm respair.lst
  else
    echo $fldr": respair.lst missing"
  fi

  cd ../
done

