#!/bin/bash
set -e
rm -rf /tmp/automekin-gauss-test
mkdir -p /tmp/automekin-gauss-test
cd /tmp/automekin-gauss-test
cat > g09 <<'BASH'
#!/bin/bash
cat > /tmp/automekin-gauss-test/g09.log
BASH
chmod +x g09
export PATH=/tmp/automekin-gauss-test:/c/Program\ Files/KoshyJohn.com/DiskMax/bin:$PATH
sqlite3 inputs.db "create table gaussian (id INTEGER PRIMARY KEY,name TEXT,input TEXT, unique(name));"
multiline=$'%%chk=test.chk\n#p b3lyp/6-31g(d) opt freq\n\nTest input\n\n0 1\nH 0.0 0.0 0.0\nH 0.0 0.74 0.0\n\n'
sqlite3 inputs.db "insert into gaussian (name,input) values ('test', '$multiline');"
bash /w/OneDrive\ -\ Eastern\ Illinois\ University/Documents/GitHub/AutoMeKin_EIU/scripts/HLscripts/runTS.sh 1 /tmp/automekin-gauss-test g09
echo '----FILE----'
cat /tmp/automekin-gauss-test/test.com
echo '----END----'
echo '----OD----'
od -An -t x1 /tmp/automekin-gauss-test/test.com
echo '----END OD----'
