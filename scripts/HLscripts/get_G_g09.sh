awk 'BEGIN{g=""};/Thermal correction to Gibbs Free Energy/{g=$7;exit};/Gibbs free energy/{g=$4;exit};END{if(g!="") print g}' $1
