#!/bin/bash
cd "$2"/IRC
name="$(sqlite3 inputs.db "select name from gaussian where id=$1")"
if [ "$3" = "g09" ];then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" > ${name}.com
   g09 <${name}.com &>${name}.log
   rm ${name}.com
elif [ "$3" = "g16" ];then
   echo -e "$(sqlite3 inputs.db "select input from gaussian where id=$1")\n\n" > ${name}.com
   g16 <${name}.com &>${name}.log
   rm ${name}.com
elif [ "$3" = "qcore" ];then
   DVV_hl.py ${name} &> irc_${name}.log
fi
