#!/bin/bash
sharedir=${AMK}/share
source utils.sh

inputfile=$1
cwd=$PWD
mm=$2
#reading input file
read_input
###

en=$(awk 'BEGIN{if('$rate'==0) en=100;if('$rate'==1) en='$energy'};{if($1=="MaxEn") en=$2};END{print en}' $inputfile )
mindirll=$tsdirll/MINs/SORTED
confilell=$tsdirll/working/conf_isomer.out
factor=1.5
if [ -f $minfilell ] && [ -f $kmcfilell ] && [ $mm -eq 1 ]; then
   minn=$(awk '/min0/{print $2}' $minfilell)
   if [ -z "$minn" ]; then
      echo "ERROR: min0 not found in $minfilell"
      exit 1
   fi
   if [ -s "$confilell" ]; then
      minok=$(awk -v min0="$minn" 'BEGIN{min=min0} {for(i=1;i<=NF;i++) if($i==min0) min=$1} END{print min}' $confilell )
   else
      minok=$minn
   fi
###
   if [ $mdc -ge 1 ]; then
      selm=$(awk '{if($3!~/min0/)print $2}' $minfilell | awk 'BEGIN{srand('$srandseed');rn=rand()}
      NF==1{++nmin;n[nmin]=$1}
      END{
      for(i=1;i<=nmin;i++) den+='$factor'^(nmin-i)
      p[nmin]=1/den
      i=1
      ptot=0
      while(i<=nmin){
        p[i]='$factor'^(nmin-i)*p[nmin]
        ptot+=p[i]
        if(rn<ptot) {print n[i];exit}
        i++
        }
      }' )
   else
      selm=$( get_minn.sh $kmcfilell $minok $en $factor | awk 'BEGIN{srand('$srandseed');rn=rand()}
      NF==1{++nmin;n[nmin]=$1}
      END{
      for(i=1;i<=nmin;i++) den+='$factor'^(nmin-i)
      p[nmin]=1/den
      i=1
      ptot=0
      while(i<=nmin){
        p[i]='$factor'^(nmin-i)*p[nmin]
        ptot+=p[i]
        if(rn<ptot) {print n[i];exit}
        i++
        }
      }' )
   fi
   echo ""
   if [ -z $selm ]; then
      echo "get_minn.sh failed selecting a minimum"
      echo "Try now with get_minx.sh..."
      selm=$( get_minx.sh $kmcfilell $minok $en $factor | awk 'BEGIN{srand('$srandseed');rn=rand()}
      NF==1{++nmin;n[nmin]=$1}
      END{
      for(i=1;i<=nmin;i++) den+='$factor'^(nmin-i)
      p[nmin]=1/den
      i=1
      ptot=0
      while(i<=nmin){
        p[i]='$factor'^(nmin-i)*p[nmin]
        ptot+=p[i]
        if(rn<ptot) {print n[i];exit}
        i++
        }
      }' )
   fi
   echo "MD simulations start from MIN $selm"
   names="MIN"$selm
   sqlite3 $mindirll/mins.db "select natom,geom from mins where name='$names'" | sed 's@|@\n\n@g' > ${molecule}.xyz
else
   if [ ! -f ${molecule}_ref.xyz ]; then
      cp ${molecule}.xyz ${molecule}_ref.xyz
   fi
fi
