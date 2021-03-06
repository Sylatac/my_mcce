#!/bin/bash
# To be run in folder where pdbs to be renamed reside
###  Dclc_extract_0_opt.pdb: 22 char  -> sliceA-00.pdb;  Dclc_extract_19_opt.pdb: 23 char
###     WCcluster29_opt.pdb: 19 char; WCcluster2_opt.pdb: 18
###
if [[ $# -eq 0 ]]; then
  echo "Call: rename-slices.sh name_startwith => rename-slices.sh Dclc_extract_"
  echo "Call: rename-slices.sh name_startwith => rename-slices.sh WCcluster"
  exit 0
fi
## 1. Process files (WCcluster ::  water-wire)
startwith=$1
chain="AB" # preset for dimer

current=$(basename $(pwd))
echo "Current: "$current
DIM="original"	# Dimer_slices"
if [[ "$current" == "$DIM" ]]; then
  if [[ "$startwith" == WCcluster* ]]; then
    newname="cluster"$chain"-"
  else
    newname="slice"$chain"-"
  fi
fi
##echo "Note: rename-slices.sh can ony deal with "Dclc_extract_" or "WCcluster" cases."
read -p "Processing files that start with "$startwith" -> "$newname": OK (1/0)?" reply
if [ "$reply" -eq 0 ]; then
  exit 0
else
  read -p "Process the 'dry' pdbs (1/0)?" doDry
  read -p "Process the 'wet' pdbs (1/0)?" doWet
fi
#............................................................................
for pdb in $( ls -l "$startwith"*.pdb | awk '{print $NF}')
do
  ## Rename  ............................................................
  if [[ "$startwith" == WCcluster* ]]; then
    # Change single to double digit in pdb name, 5 -> 05 for sorting & processing purpose
    if [ ${#pdb} -lt 19 ]; then
      # 1 digit
      id=$(printf "%02d" $(echo $pdb | grep -o '[0-9]'))
      sedARG=" -e 's/$startwith/$newname/' -e 's/[0-9]_opt.pdb/$id.pdb/' "
    else
      # 2
      id=$(printf "%2d" $(echo $pdb | grep -o '[0-9][0-9]'))
      sedARG=" -e 's/$startwith/$newname/' -e 's/[0-9][0-9]_opt.pdb/$id.pdb/' "
    fi
  else ## "$startwith" == "extract"
    if [ ${#pdb} -lt 23 ]; then
      # 1 digit
      id=$(printf "%02d" $(echo $pdb | grep -o '[0-9]'))
      sedARG=" -e 's/"$startwith"/"$newname"/' -e 's/[0-9]_opt.pdb/"$id".pdb/' "
    else
      # 2
      id=$(printf "%2d" $(echo $pdb | grep -o '[0-9][0-9]'))
      sedARG=" -e 's/"$startwith"/"$newname"/' -e 's/[0-9][0-9]_opt.pdb/"$id".pdb/' "
    fi
  fi
  new=$(echo "$pdb" | eval sed "$sedARG")

  ## Process Dry  ............................................................
  if [ "$doDry" -eq 1 ]; then
    echo $pdb " -> "$new
    # Rename Cl ions; remove the O/H-atom labeled as terminal,
    # rename waters, delete other lines:
    sed -e 's/TIP3/HOH /; s/OH2 HOH/O   HOH/; s/H1   HOH/1H   HOH/; s/H2   HOH/2H   HOH/' \
        -e '/SOD /d; / OT2 /d' -e '/^CRYST/d; /END/d; /TER/d' \
        -e 's/ HSE / HIS /; s/CLA CLA /CL   CL /' $pdb > $new
    dry=${new/%.pdb/-dry.pdb}
    grep -v HOH $new > $dry
  fi

  ## Process Wet  ............................................................
  if [ "$doWet" -eq 1 ]; then
    hohpdb=${new/%.pdb/-wat.pdb}
    echo $pdb " -> "$hohpdb
    if [ "$doDry" -eq 0 ]; then
      sed -e 's/TIP3/HOH /; s/OH2 HOH/O   HOH/; s/H1   HOH/1H   HOH/; s/H2   HOH/2H   HOH/' \
        -e '/SOD /d; / OT2 /d' -e '/^CRYST/d; /END/d; /TER/d' \
        -e 's/ HSE / HIS /; s/CLA CLA /CL   CL /' $pdb > $new
    fi
    grep HOH $new > $hohpdb
    rename-dupwaters-pdb.sh $hohpdb
  fi
  #..........................................................................

  /bin/rm -f $new
done

if [ "$doWet" -eq 1 ]; then
  echo "Next to do:  reduce-watspher-fldrs.sh clusterAB"
fi
