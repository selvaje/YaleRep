find . -name "*.*"  | xargs -n 1 -P 4 bash -c $'  touch -a -m  $1    ' _
