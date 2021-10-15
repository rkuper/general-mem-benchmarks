#!/bin/bash

START_TIME=$(date +%s%N)
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -b|--benchmarks)
      BENCHMARKS="$2"
      shift; shift
      ;;
    -r|--runs)
      TOTAL_RUNS="$2"
      shift; shift
      ;;
    -l|--keep_logs)
      KEEP_LOGS="$2"
      shift;
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift
      ;;
  esac
done
default_user=`users | awk '{print $1}'`
echo "$default_user"
# TOTAL_RUNS=$([ -v TOTAL_RUNS ] && echo "$TOTAL_RUNS" || echo "1")
REGEX_NUM='^[0-9]+$'
TOTAL_RUNS=$([[ -v TOTAL_RUNS && $TOTAL_RUNS =~ $REGEX_NUM ]] && echo "$TOTAL_RUNS" || echo "1")
KEEP_LOGS=$([ -v KEEP_LOGS -o -z KEEP_LOGS ] && echo "true" || echo "false")
BENCHMARKS=$([ "$BENCHMARKS" == "all" -o -z "${BENCHMARKS+x}" -o "$BENCHMARKS" == "" ] \
  && echo "dsb ycsb graphbig" || echo "$BENCHMARKS")
BENCHMARKS=($BENCHMARKS)

echo "BENCHMARKS: ${BENCHMARKS}"
echo "TOTAL_RUNS: ${TOTAL_RUNS}"
echo "KEEP_LOGS:  ${KEEP_LOGS}"


echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
for BENCHMARK in "${BENCHMARKS[@]}"
do
        echo "$BENCHMARK"
done
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""


echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
for BENCHMARK in "${BENCHMARKS[@]}"
do
  case $BENCHMARK in
    dsb)
      if [ "$BENCHMARK" == "dsb" ]
      then
        echo "WHAT"
      fi
      ;;
    ycsb)
      echo "IS"
      ;;
    graphbig)
      echo "THIS"
      ;;
  esac
done
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""



echo "$TOTAL_RUNS"

declare -a BENCHIES=("a" "b" "c")
declare -a THINGA_TIMINGS=("2" "10")
declare -a THINGB_TIMINGS=("100" "120")
declare -a THINGC_TIMINGS=("1000" "1200")
for BENCH in "${BENCHIES[@]}"
do
  START_INDEX=$((`echo ${BENCHIES[@]/"$BENCH"//} | cut -d/ -f1 | wc -w | tr -d ' '` * TOTAL_RUNS))
  TEMP_SUM=0
  for RUN in $(eval echo {$START_INDEX..$((START_INDEX + TOTAL_RUNS - 1))})
  do
    TEMP_SUM=$((THING${BENCH^^}_TIMINGS[RUN % TOTAL_RUNS] + TEMP_SUM))
  done
  echo "SUM= $TEMP_SUM"
  # TEMP_TOTAL=${#THING${}[@]}
  echo "[${BENCH^^}] Elapsed Benchmarking Time: $((TEMP_SUM/TOTAL_RUNS)) nanoseconds"
done
echo "$BENCHMARKS"
