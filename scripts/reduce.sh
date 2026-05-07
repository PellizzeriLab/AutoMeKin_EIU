#!/bin/bash

dir=$1
pre=$2
input="$dir/${pre}list_screened"
output="$dir/${pre}list_screened.red"

if [ ! -s "$input" ]; then
  echo "reduce.sh: missing or empty input file '$input'" >&2
  exit 1
fi

sed 's/_/ _ /g;s/'"$pre"'/'"$pre"' /g' "$input" | awk '
function add_tokens(line,   count, i, parts) {
  count = split(line, parts, /[[:space:]]+/)
  for (i = 1; i <= count; i++) {
    tokens[++tok_count] = parts[i]
  }
}

function get_token(   t) {
  while (tok_pos > tok_count) {
    if ((getline line) <= 0) return ""
    if (line ~ /^$/) continue
    add_tokens(line)
  }
  t = tokens[tok_pos++]
  return t
}

function get_number(name,   tok) {
  tok = get_token()
  if (tok == "") {
    print "reduce.sh: unexpected EOF while reading " name > "/dev/stderr"
    exit 1
  }
  return tok
}

BEGIN { OFS = " " }
/data/ {
  header = $2
  tok_count = 0
  tok_pos = 1
  for (i = 3; i <= NF; i++) {
    tokens[++tok_count] = $i
  }
  energy = get_number("energy")
  n = get_number("n")
  printf "%s%s%s", header, OFS, energy
  for (i = 1; i <= n; i++) {
    v = get_number("block value")
    m = get_number("block count")
    if (m+0 != m) {
      print "reduce.sh: invalid block count " m " for block " i > "/dev/stderr"
      exit 1
    }
    printf "%s%s", OFS, v
    for (j = 1; j <= m; j++) {
      printf "%s%s", OFS, get_number("block entry")
    }
  }
  sc = get_number("sc")
  if (sc+0 != sc) {
    print "reduce.sh: invalid sc count " sc > "/dev/stderr"
    exit 1
  }
  printf "%s%s", OFS, sc
  for (k = 1; k <= sc; k++) {
    printf "%s%s", OFS, get_number("sc entry")
  }
  marker = get_number("final marker")
  printf "%s%s\n", OFS, marker
}
' > "$output"

