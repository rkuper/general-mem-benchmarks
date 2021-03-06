#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -b|--benchmarks)
      BENCHMARKS="$2"
      shift
      shift
      ;;
    -r|--runs)
      TOTAL_RUNS="$2"
      shift
      shift
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift; shift
      ;;
    -s|--size)
      SIZE="$2"
      shift; shift
      ;;
    -l|--keep_logs)
      KEEP_LOGS="$2"
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

BENCHMARKS=$([ "$BENCHMARKS" == "all" -o -z "${BENCHMARKS+x}" -o "$BENCHMARKS" == "" ] \
  && echo "dsb ycsb graphbig" || echo "$BENCHMARKS")
BENCHMARKS=($BENCHMARKS)
REGEX_NUM='^[0-9]+$'
TOTAL_RUNS=$([[ -v TOTAL_RUNS && $TOTAL_RUNS =~ $REGEX_NUM ]] && echo "$TOTAL_RUNS" || echo "1")
KEEP_LOGS=$([ -v KEEP_LOGS -o -z KEEP_LOGS ] && echo "true" || echo "false")
OUTPUT_FILE=$([ -v OUTPUT_FILE ] && echo "$OUTPUT_FILE" || echo "results.txt")
DEFAULT_USER=`users | awk '{print $1}'`

SIZE=$([ -v SIZE ] && echo "$SIZE" || echo "medium")
case $SIZE in
  small)
    YCSB_COUNTS=100000
    DSB_DURATION=60
    ;;
  medium)
    YCSB_COUNTS=1000000
    DSB_DURATION=200
    ;;
  large)
    YCSB_COUNTS=10000000
    DSB_DURATION=300
    ;;
  *)
    YCSB_COUNTS=1000000
    DSB_DURATION=200
    ;;
esac

declare -a DSB_BENCHMARKS=("hotel" "media")
declare -a YCSB_BENCHMARKS=("a" "b" "c" "f" "d")

declare -a DSB_HOTEL_TIMINGS=()
declare -a DSB_MEDIA_TIMINGS=()
declare -a YCSB_A_TIMINGS=()
declare -a YCSB_B_TIMINGS=()
declare -a YCSB_C_TIMINGS=()
declare -a YCSB_F_TIMINGS=()
declare -a YCSB_D_TIMINGS=()

if [[ -z "${MEM_BENCHMARK_ROOT}" ]]; then
  MEM_BENCHMARK_ROOT=/home/"$DEFAULT_USER"/Documents/benchmarks/mem-benchmarks
else
  MEM_BENCHMARK_ROOT="${MEM_BENCHMARK_ROOT}"
fi

if [[ -z "${LOG_DIRECTORY}" ]]; then
  LOG_DIRECTORY="${MEM_BENCHMARK_ROOT}/logs"
else
  LOG_DIRECTORY="${LOG_DIRECTORY}"
fi



####################################
#            Benchmarks            #
####################################
START_TIME=$(date +%s%N)
for BENCHMARK in "${BENCHMARKS[@]}"
do
  case $BENCHMARK in
    dsb)
      START_DSB_TIME=$(date +%s%N)
      for DSB_BENCHMARK in "${DSB_BENCHMARKS[@]}"
      do
          DSB_DIRECTORY="hotelReservation"
          DSB_LUA="./wrk2/scripts/hotel-reservation/mixed-workload_type_1.lua"
          DSB_LOCALHOST="http://localhost:5000"
          case $DSB_BENCHMARK in
            hotel)
                DSB_DIRECTORY="hotelReservation"
                DSB_LUA="./wrk2/scripts/hotel-reservation/mixed-workload_type_1.lua"
                DSB_LOCALHOST="http://localhost:5000"
                ;;
            media)
                DSB_DIRECTORY="mediaMicroservices"
                DSB_LUA="./wrk2/scripts/media-microservices/compose-review.lua"
                DSB_LOCALHOST="http://localhost:8080/wrk2-api/review/compose"
                ;;
            *)
                break
                ;;
          esac

        echo "Running: DEATHSTARBENCH-${DSB_BENCHMARK^^}"
        LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}_${DSB_BENCHMARK}.log"
        {
          echo "#############################"
          echo "#   DeathStarBench: ${DSB_BENCHMARK}   #"
          echo "#############################"
          cd DeathStarBench/"$DSB_DIRECTORY"
          sudo docker stop `docker ps -qa`
          docker-compose up -d

          echo "PCM Test Beginning:"
          echo "==================="
          for run in $(eval echo {1..$TOTAL_RUNS})
          do
            TEMP_START_TIME=$(date +%s%N)
            
            # TODO: Performance metrics for IPC, cache hit rates, LLC Read Latency, and memory (read and write) throughput
            # sudo pcm --external_program \
            #         sudo pcm-memory --external_program \
            #         sudo ./wrk2/wrk -D exp -L -s "$DSB_LUA" "$DSB_LOCALHOST" -t 2 -R 10000 -d "$DSB_DURATION"
            
            sudo ./wrk2/wrk -D exp -L -s "$DSB_LUA" "$DSB_LOCALHOST" -t 2 -R 10000 -d "$DSB_DURATION"
            TEMP_END_TIME=$(date +%s%N)
            case $DSB_BENCHMARK in
              hotel)
                DSB_HOTEL_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              media)
                DSB_MEDIA_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              *)
                ;;
            esac
          done
          cd ../../
        } > "$LOG_FILE"
      done
      END_DSB_TIME=$(date +%s%N)
      ;;



    ycsb)
      START_YCSB_TIME=$(date +%s%N)
      for YCSB_BENCHMARK in "${YCSB_BENCHMARKS[@]}"
      do
        echo "Running: YCSB-${YCSB_BENCHMARK^^}"
        LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}_${YCSB_BENCHMARK}.log"
        {
          echo "#############################"
          echo "#        YCSB - ${YCSB_BENCHMARK}         #"
          echo "#############################"

          echo "PCM Test Beginning:"
          echo "==================="

          sudo "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb load basic \
                  -P "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
                  -p recordcount="$YCSB_COUNTS" -p operationcount="$YCSB_COUNTS" -threads 10 -target 15000 > load.dat
          tail -n 150 load.dat

          for run in $(eval echo {1..$TOTAL_RUNS})
          do
            TEMP_START_TIME=$(date +%s%N)
            
            # TODO: Performance metrics for IPC, cache hit rates, LLC Read Latency, and memory (read and write) throughput
            # sudo pcm --external_program \
            #         sudo pcm-memory --external_program \
            #         sudo "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb run basic \
            #         -P "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
            #         -p recordcount="$YCSB_COUNTS" -p operationcount="$YCSB_COUNTS" -threads 10 -target 15000 > transactions.dat

            sudo "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb run basic \
                    -P "$MEM_BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
                    -p recordcount="$YCSB_COUNTS" -p operationcount="$YCSB_COUNTS" -threads 10 -target 15000 > transactions.dat
            TEMP_END_TIME=$(date +%s%N)
            tail -n 150 transactions.dat; rm transactions.dat
            case $YCSB_BENCHMARK in
              a)
                YCSB_A_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              b)
                YCSB_B_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              c)
                YCSB_C_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              f)
                YCSB_F_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              d)
                YCSB_D_TIMINGS+=("$(($TEMP_END_TIME - $TEMP_START_TIME))")
                ;;
              *)
                ;;
            esac
          done
        } > "$LOG_FILE"
      done
      END_YCSB_TIME=$(date +%s%N)
      ;;



    graphbig)
      START_GRAPHBIG_TIME=$(date +%s%N)
      echo "Running: GraphBIG"
      LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}.log"
      {
        echo "#############################"
        echo "#          GraphBig         #"
        echo "#############################"
        cd graphBIG

        echo "PCM Test Beginning:"
        echo "==================="
        for run in $(eval echo {1..$TOTAL_RUNS})
        do
        
          # TODO: Performance metrics for IPC, cache hit rates, LLC Read Latency, and memory (read and write) throughput
          # sudo pcm --external_program \
          #         sudo pcm-memory --external_program \
          #         sudo make run
          # sudo perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses \
          #         sudo perf stat -M DRAM_BW_Use \
          #         sudo perf stat -M DRAM_Read_Latency \
          #         sudo perf stat -M Summary \
          #         sudo make run

          sudo make run
        done
        # sudo make run
        cat output.log
        cd ..
      } > "$LOG_FILE"
      END_GRAPHBIG_TIME=$(date +%s%N)
      ;;

    *)
      ;;
  esac
done



####################################
#             Metrics              #
####################################
print_generic_metrics () {
  echo "IPC: " \
    `awk '/\ TOTAL\ / { sum += $4; n++} END { if (n > 0) print sum / n; }' \
    "$1"`

  echo "L2 Hit Rate: " \
    `awk '/\ TOTAL\ / {sum += $12; n++} END { if (n > 0) print sum / n}' \
    "$1"`

  echo "L3 Hit Rate: " \
    `awk '/\ TOTAL\ / {sum += $11; n++} END { if (n > 0) print sum / n}' \
    "$1"`

  echo "LLC Read Miss Latency: " \
    `awk '/LLCRDMISSLAT \(ns\)/ {getline; getline; sum += $9; n++} END { if (n > 0) print sum / n; }' \
    "$1"`

  echo "System Read Throughput (MB/s): " \
    `awk '/System Read Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    "$1"`

  echo "System Write Throughput (MB/s): " \
    `awk '/System Write Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    "$1"`

  echo "System Memory Throughput (MB/s): " \
    `awk '/System Memory Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    "$1"`
}

{
  for BENCHMARK in "${BENCHMARKS[@]}"
  do
    echo "###############################"
    echo "Averages for benchmark $BENCHMARK"
    echo "###############################"

    case $BENCHMARK in
      dsb)
        echo "[DEATHSTARBENCH] Average Elapsed Benchmarking Time: $((($END_DSB_TIME - $START_DSB_TIME)/TOTAL_RUNS)) nanoseconds"
        for DSB_BENCHMARK in "${DSB_BENCHMARKS[@]}"
        do
          LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}_${DSB_BENCHMARK}.log"
          echo ""
          echo "Averages for workload ${DSB_BENCHMARK}:"
          echo "=============================="
          echo "Requests/sec: " \
            `awk '/Requests\/sec/ {sum += $2; n++} END { if (n > 0) print sum / n; }' \
            "$LOG_FILE"`

          echo "Transfer/sec: " \
            `awk '/Transfer\/sec/ {sum += substr($2, 1, length($2)-2); n++} END { if (n > 0) print sum / n; }' \
            "$LOG_FILE"`

          echo "Average Latency: " \
            `awk '/Thread Stats / {getline; \
            if (substr($2, length($2), length($2)) == "m") sum += substr($2, 1, length($2)-1) * 60; \
            else sum += substr($2, 1, length($2)-1); n++} END { if (n > 0) print sum / n; }' \
            "$LOG_FILE"`

          tail_vals=("50.000%" "90.000%" "99.000%")
          for tail_val in "${tail_vals[@]}"
          do
            echo "$tail_val Tail: " \
              `awk '/'"$tail_val"'/ {\
              if (substr($2, length($2), length($2)) == "m") sum += substr($2, 1, length($2)-1) * 60; \
              else sum += substr($2, 1, length($2)-1); n++} \
              END { if (n > 0) print sum / n; }' \
              "$LOG_FILE"`
          done

          # print_generic_metrics "$LOG_FILE"

          START_INDEX=$((`echo ${DSB_BENCHMARKS[@]/"$DSB_BENCHMARK"//} | cut -d/ -f1 | wc -w | tr -d ' '` * TOTAL_RUNS))
          TEMP_SUM=0
          for RUN in $(eval echo {$START_INDEX..$((START_INDEX + TOTAL_RUNS - 1))})
          do
            TEMP_SUM=$((DSB_${DSB_BENCHMARK^^}_TIMINGS[RUN % TOTAL_RUNS] + TEMP_SUM))
          done
          echo "[${DSB_BENCHMARK^^}] Elapsed Benchmarking Time: $((TEMP_SUM/TOTAL_RUNS)) nanoseconds"
        done
        ;;



      ycsb)
        echo "[YCSB] Average Elapsed Benchmarking Time: $((($END_YCSB_TIME - $START_YCSB_TIME)/TOTAL_RUNS)) nanoseconds"
        for YCSB_BENCHMARK in "${YCSB_BENCHMARKS[@]}"
        do
          LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}_${YCSB_BENCHMARK}.log"
          echo ""
          echo "Averages for workload ${YCSB_BENCHMARK}:"
          echo "========================"
          insert_throughput_num=0
          insert_throughput_sum=0
          other_throughput_num=0
          other_throughput_sum=0
          check_lines=($(grep -n "\[OVERALL\], Throughput" "$LOG_FILE" | cut -d: -f1))
          for line_check in "${check_lines[@]}"
          do
            insert_op=`sed -n $(expr $line_check - 2)p "$LOG_FILE" | grep "INSERT" | wc -c`
            if [ $insert_op -ge 1 ]; then
              insert_throughput_sum=$(( insert_throughput_sum + `sed -n $(expr $line_check)p \
                "$LOG_FILE" | awk '{print $3}' | cut -d. -f1` ))
              insert_throughput_num=$(( insert_throughput_num + 1 ))
            else
              other_throughput_sum=$(( other_throughput_sum + `sed -n $(expr $line_check)p \
                "$LOG_FILE" | awk '{print $3}' | cut -d. -f1` ))
              other_throughput_num=$(( other_throughput_num + 1 ))
            fi
          done
          if [ $insert_throughput_num -ge 1 ]; then
            echo "Insert Throughput (ops/sec): " $(( insert_throughput_sum / insert_throughput_num ))
          fi
          if [ $other_throughput_num -ge 1 ]; then
            echo "Update/Read Throughput (ops/sec): " $(( other_throughput_sum / other_throughput_num ))
          fi

          case $YCSB_BENCHMARK in
            a)
              operations=("INSERT" "READ" "UPDATE")
              ;;
            b)
              operations=("INSERT" "READ" "UPDATE")
              ;;
            c)
              operations=("INSERT" "READ")
              ;;
            f)
              operations=("INSERT" "READ-MODIFY-WRITE" "UPDATE")
              ;;
            d)
              operations=("INSERT" "READ")
              ;;
            *)
              operations=("INSERT" "READ" "UPDATE")
              ;;
          esac
          for operation in "${operations[@]}"
          do
            echo "$operation Latency (us): " \
              `awk '/\['"$operation"'\], AverageLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
              "$LOG_FILE"`

            echo "$operation 95% Tail Latency (us): " \
              `awk '/\['"$operation"'\], 95thPercentileLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
              "$LOG_FILE"`

            echo "$operation 99% Tail Latency (us): " \
              `awk '/\['"$operation"'\], 99thPercentileLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
              "$LOG_FILE"`
          done

          # print_generic_metrics "$LOG_FILE"

          START_INDEX=$((`echo ${YCSB_BENCHMARKS[@]/"$YCSB_BENCHMARK"//} | cut -d/ -f1 | wc -w | tr -d ' '` * TOTAL_RUNS))
          TEMP_SUM=0
          for RUN in $(eval echo {$START_INDEX..$((START_INDEX + TOTAL_RUNS - 1))})
          do
            TEMP_SUM=$((YCSB_${YCSB_BENCHMARK^^}_TIMINGS[RUN % TOTAL_RUNS] + TEMP_SUM))
          done
          echo "[YCSB - ${YCSB_BENCHMARK^^}] Elapsed Benchmarking Time: $((TEMP_SUM/TOTAL_RUNS)) nanoseconds"
        done
        ;;



      graphbig)
        echo "[GRAPHGIB] Average Elapsed Benchmarking Time: $((($END_GRAPHBIG_TIME - $START_GRAPHBIG_TIME)/TOTAL_RUNS)) nanoseconds"
        LOG_FILE="${LOG_DIRECTORY}/${BENCHMARK}.log"
        echo "Benchmark: <BENCHMARK_NAME>"
        echo "== time: <LOAD_DATASET_TIME>"
        echo "== time: <RUN_TIME>"
        grep 'Benchmark\|time' graphBIG/output.log
        # print_generic_metrics "$LOG_FILE"
        ;;
    esac

    echo ""
    echo ""
    echo ""
  done
  END_TIME=$(date +%s%N)
  echo "[OVERALL] Average Elapsed Benchmarking Time: $((($END_TIME - $START_TIME)/TOTAL_RUNS)) nanoseconds"
} > "$LOG_DIRECTORY"/"$OUTPUT_FILE"


if [ "$KEEP_LOGS" == "false" ]
then
    rm "$LOG_DIRECTORY"/*.log
fi
