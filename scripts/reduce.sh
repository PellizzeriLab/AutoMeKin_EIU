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
BEGIN { OFS = " " }
/data/ {
  header = $2
  if (getline <= 0) { print "reduce.sh: unexpected EOF after data header" > "/dev/stderr"; exit 1 }
  second = $1
  if (getline <= 0) { print "reduce.sh: unexpected EOF before n value" > "/dev/stderr"; exit 1 }
  n = $1
  printf "%s%s%s", header, OFS, second
  for (i = 1; i <= n; i++) {
    if (getline <= 0) { print "reduce.sh: unexpected EOF reading block lines" > "/dev/stderr"; exit 1 }
    printf "%s%s", OFS, $1
    m = $2
    for (j = 1; j <= m; j++) {
      printf "%s%s", OFS, $(2+j)
    }
  }
  if (getline <= 0) { print "reduce.sh: unexpected EOF before sc line" > "/dev/stderr"; exit 1 }
  sc = $1
  if (getline <= 0) { print "reduce.sh: unexpected EOF reading sc values" > "/dev/stderr"; exit 1 }
  for (k = 1; k <= sc; k++) {
    printf "%s%s", OFS, $k
  }
  if (getline <= 0) { print "reduce.sh: unexpected EOF reading final marker" > "/dev/stderr"; exit 1 }
  printf "%s%s\n", OFS, $1
}
' > "$output"

