#!/bin/bash
set -e
set -o pipefail

print_usage() {
  printf "Usage: updategatekeeper.sh --input <inputFile> --output <outputFile>"
}

function check_defined {
  if [ -z "$1" ]
  then 
    echo "No $2 given. Use $3 or $4 to enter $2"
    exit 1
  fi
}

# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--input") set -- "$@" "-i" ;;
    "--output") set -- "$@" "-n" ;;
    *)        set -- "$@" "$arg"
  esac
done

while getopts 'i:o:' flag; do
  case "${flag}" in
    i) INPUT_FILE="${OPTARG}" ;;
    o) OUTPUT_FILE="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

check_defined "$INPUT_FILE" "input file" --input -i
check_defined "$OUTPUT_FILE" "output file" --output -o

# Find argument to run python 3 (py on Windows, python3 on Unix)
if [[ "$OSTYPE" =~ ^msys ]]; then
  py_cmd=py
  pip_cmd=pip
else
  py_cmd=python3
  pip_cmd=pip3
fi

# Check if python 3 is installed
if ! [[ $($py_cmd --version 2>&1) =~ 3 ]];
then
    echo "Python 3 is not installed. Please install before running this script"
fi

if ! [[ $( $pip_cmd list | grep PyYAML 2>&1 ) ]];
then
  $pip_cmd install pyyaml
fi

# Get current working directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

$py_cmd $dir/updategatekeeper.py $INPUT_FILE $OUTPUT_FILE
echo "Sucessfully updated ${OUTPUT_FILE##*/}"

set +e
