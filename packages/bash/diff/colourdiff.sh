
_diffc() {
  if [ $# -lt 2 ]
  then
    diff $1 $2
    return $?
  fi

  FILE_A="$1"
  FILE_B="$2"

  shift 2

  colordiff -Naur "${FILE_A}" "${FILE_B}" $@ \
    | diff-so-fancy
}
alias diffc="_diffc"
