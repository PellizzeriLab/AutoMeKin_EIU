printf "create table t(x text); insert into t values (\'line1\nline2\nline3\');\n" | sqlite3 test.db
inp=$(sqlite3 test.db "select x from t")
printf "%s" "$inp" | od -An -t x1
echo
printf "%s\n" "$inp" | cat -n

