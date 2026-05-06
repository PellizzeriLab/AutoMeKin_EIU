#!/bin/bash
source utils.sh
#remove tmp files
tmp_files=(tmp tmp_code tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing"
   exit
fi

cwd=$PWD
exe=$(basename $0)

###reading input file
read_input
####

en=$(awk 'BEGIN{if('$rate'==0) en=100;if('$rate'==1) en='$energy'};{if($1=="MaxEn") en=$2};END{print en}' $inputfile )

nlprlist=$(wc -l $tsdirhl/PRODs/PRlist | awk '{print $1}')

if [ $nlprlist -eq 1 ];then
   echo "No products for this system"
   minn0=$(awk '/min0/{print $2}' $tsdirhl/MINs/SORTED/MINlist_sorted)
   if [ -z "$minn0" ]; then
      echo "ERROR: cannot find min0 in $tsdirhl/MINs/SORTED/MINlist_sorted"
      exit 1
   fi
   if [ -s "$tsdirhl/working/conf_isomer.out" ]; then
      minn=$(awk -v min0="$minn0" 'BEGIN{min=min0} {for(i=1;i<=NF;i++) if($i==min0) min=$1} END{print min}' $tsdirhl/working/conf_isomer.out)
   else
      minn=$minn0
   fi
   if [ -z "$minn" ]; then
      echo "WARNING: could not map min0 to a starting minimum in $tsdirhl/working/conf_isomer.out; using $minn0"
      minn=$minn0
   fi
   if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirhl/KMC/RXNet_long.cg ) -eq 0 ]; then 
      echo "No connected paths found (RXNet_long.cg is empty)"
   else
      linked_paths.py $tsdirhl/KMC/RXNet_long.cg $minn $en > $tsdirhl/KMC/RXNet_long.cg_groupedprods
   fi
   exit
fi

echo "codes of products" > tmp_code
rm -f ${tsdirhl}/PRODs/PRlist_tags.log
for name in $(sqlite3 $tsdirhl/PRODs/prodhl.db "select name from prodhl")
do
   name_sql=$(sql_quote "$name")
   formula="$(sqlite3 $tsdirhl/PRODs/prodhl.db "select natom,geom from prodhl where name='$name_sql'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
   echo "$formula" >>tmp_code
   formula_sql=$(sql_quote "$formula")
   sqlite3 ${tsdirhl}/PRODs/prodhl.db "update prodhl set formula='$formula_sql' where name='$name_sql';"
   sqlite3 ${tsdirhl}/PRODs/prodhl.db "select energy,formula from prodhl where name='$name_sql'" | awk '{for (i=1;i<=NF;i++) printf "%s",$i;printf "\n"}' | sed 's@|@ @g' > tmp_pf
   sqlite3 ${tsdirhl}/PRODs/prodhl.db "select natom,geom from prodhl where name='$name_sql'" | sed 's@|@\n\n@g' > tmp_geom
   tag_prod.py tmp_geom | sed 's@-0.000@0.000@g' > tmp_tag
   paste tmp_pf tmp_tag >> ${tsdirhl}/PRODs/PRlist_tags.log
   echo "Getting the formula for $name"
done

paste $tsdirhl/PRODs/PRlist tmp_code > $tsdirhl/PRODs/PRlist_kmc

lastmin=$(awk '{lm=$2};END{print lm}' $tsdirhl/MINs/SORTED/MINlist_sorted )

sed 's/ + /+/g' $tsdirhl/PRODs/PRlist_kmc | awk 'BEGIN{n='$lastmin'} 
{if(NR==1) print $0
if($1=="PROD") {++i
  fl[i]=$NF
  j=1
  p=1
  while(j<=i-1){
   if(fl[i]==fl[j]) {p=0;code[i]=code[j];break}
   j++
   }
  if(p==1) {++n;code[i]=n}
  print $1,$2,code[i]
  }
}' > $tsdirhl/PRODs/PRlist_kmc.log


cat $tsdirhl/PRODs/PRlist_kmc.log $tsdirhl/KMC/RXNet_long.cg | awk '/PROD/{if(NF==3) ncode[$2]=$3} 
/KMC file/{lp=1;print $0}
{if(lp==1) {
  if($10~"MIN" || $1~"number") print $0
  if($10~"PROD") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %15.0f %6.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,ncode[$11],$12,$13,$14
  }
}' >tmp

minn0=$(awk '/min0/{print $2}' $tsdirhl/MINs/SORTED/MINlist_sorted)
if [ -z "$minn0" ]; then
   echo "ERROR: cannot find min0 in $tsdirhl/MINs/SORTED/MINlist_sorted"
   exit 1
fi
if [ -s "$tsdirhl/working/conf_isomer.out" ]; then
   minn=$(awk -v min0="$minn0" 'BEGIN{min=min0} {for(i=1;i<=NF;i++) if($i==min0) min=$1} END{print min}' $tsdirhl/working/conf_isomer.out)
else
   minn=$minn0
fi
if [ -z "$minn" ]; then
   echo "WARNING: could not map min0 to a starting minimum in $tsdirhl/working/conf_isomer.out; using $minn0"
   minn=$minn0
fi

if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirhl/KMC/RXNet_long.cg ) -eq 0 ]; then 
   echo "No connected paths found (RXNet_long.cg is empty)"
   exit
else
   linked_paths.py tmp $minn $en > $tsdirhl/KMC/RXNet_long.cg_groupedprods
fi


