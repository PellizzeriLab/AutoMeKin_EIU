awk 'BEGIN{zpe=""};/Zero-point vibrational energy/{getline;zpe=$1;exit};/Zero-point correction=/{gsub(/.*= */,"",$0);print $1;exit};END{if(zpe!="") print zpe}' $1
