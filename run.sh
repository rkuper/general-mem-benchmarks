#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -b|--benchmarks)
      BENCHES="$2"
      shift
      shift
      ;;
    -r|--runs)
      TOTAL_RUNS="$2"
      shift
      shift
      ;;
    -l|--keep_logs)
      KEEP_LOGS="$2"
      shift
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
DEFAULT_USER=`users | awk '{print $1}'`

declare -a DSB_BENCHMARKS=("hotel" "media")
declare -a YCSB_BENCHMARKS=("a" "b" "c" "f" "d")

if [[ -z "${LOG_DIRECTORY}" ]]; then
  LOG_DIRECTORY="./logs"
else
  LOG_DIRECTORY="${LOG_DIRECTORY}"
fi

if [[ -z "${BENCHMARK_ROOT}" ]]; then
  BENCHMARK_ROOT=/home/"$DEFAULT_USER"/Documents/benchmarks
else
  BENCHMARK_ROOT="${BENCHMARK_ROOT}"
fi
cd $BENCHMARK_ROOT



####################################
#            Benchmarks            #
####################################
for BENCHMARK in "${BENCHMARKS[@]}"
do
  case $BENCHMARK in
    dsb)
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

        LOG_FILE=""$LOG_DIRECTORY"/"$BENCHMARK"_"$DSB_BENCHMARK".log"
        {
          echo "#############################"
          echo "#   DeathStarBench: ${DSB_BENCHMARK}   #"
          echo "#############################"
          cd deathstarbench/"$DSB_DIRECTORY"
          docker stop `docker ps -qa`
          sudo docker-compose up -d

          echo "PCM Test Beginning:"
          echo "==================="
          for run in $(eval echo {1..$total_runs})
          do
            sudo pcm --external_program \
                    sudo ./wrk2/wrk -D exp -L -s "$DSB_LUA" "$DSB_LOCALHOST" -t 2 -R 10000 -d 200
            sudo pcm-memory --external_program \
                    sudo ./wrk2/wrk -D exp -L -s "$DSB_LUA" "$DSB_LOCALHOST" -t 2 -R 10000 -d 200
          done
          cd ../../
        } > "$LOG_FILE"
      done
      ;;



    ycsb)
      for YCSB_BENCHMARK in "${YCSB_BENCHMARKS[@]}"
      do
        LOG_FILE=""$LOG_DIRECTORY"/"$BENCHMARK"_"$YCSB_BENCHMARK".log"
        {
          echo "#############################"
          echo "#        YCSB - ${YCSB_BENCHMARK}         #"
          echo "#############################"

          sudo "$BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb load basic -P "$BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
                  -P "$BENCHMARK_ROOT"/ycsb-0.17.0/large.dat -threads 10 -target 15000 > load.dat

          echo "PCM Test Beginning:"
          echo "==================="
          for run in $(eval echo {1..$total_runs})
          do
            sudo pcm --external_program \
                    sudo "$BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb run basic -P "$BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
                    -P "$BENCHMARK_ROOT"/ycsb-0.17.0/large.dat -threads 10 -target 15000 > transactions.dat
            tail -n 110 transactions.dat; transactions.dat

            sudo pcm-memory --external_program \
                    sudo "$BENCHMARK_ROOT"/ycsb-0.17.0/bin/ycsb run basic -P "$BENCHMARK_ROOT"/ycsb-0.17.0/workloads/workload"$YCSB_BENCHMARK" \
                    -P "$BENCHMARK_ROOT"/ycsb-0.17.0/large.dat -threads 10 -target 15000 > transactions.dat
            tail -n 110 transactions.dat; transactions.dat
          done
        } > "$LOG_FILE"
      done
      ;;



    graphbig)
      LOG_FILE=""$BENCHMARK".log"
      {
        echo "#############################"
        echo "#          GraphBig         #"
        echo "#############################"
        cd graphbig

        echo "PCM Test Beginning:"
        echo "==================="
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm --external_program \
                  sudo make run
          sudo pcm-memory --external_program \
                  sudo make run
        done
        sudo make run
        cat output.log
        cd ..
      } > "$LOG_FILE"
      ;;
  esac
done



####################################
#             Metrics              #
####################################
{
  for BENCHMARK in "${BENCHMARKS[@]}"
  do
    echo "###############################"
    echo "Averages for benchmark $BENCHMARK"
    echo "###############################"

    case $BENCHMARK in
      dsb)
        for DSB_BENCHMARK in "${DSB_BENCHMARKS[@]}"
        do
          LOG_FILE=""$LOG_DIRECTORY"/"$BENCHMARK"_"$DSB_BENCHMARK".log"
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

          print_generic_metrics "$LOG_FILE"
        done
        ;;



      ycsb)
        for YCSB_BENCHMARK in "${YCSB_BENCHMARKS[@]}"
        do
          LOG_FILE=""$LOG_DIRECTORY"/"$BENCHMARK"_"$YCSB_BENCHMARK".log"
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
            if [ $insert_op -ge 1 ]
            then
              insert_throughput_sum=$(( insert_throughput_sum + `sed -n $(expr $line_check)p \
                "$LOG_FILE" | awk '{print $3}' | cut -d. -f1` ))
              insert_throughput_num=$(( insert_throughput_num + 1 ))
            else
              other_throughput_sum=$(( other_throughput_sum + `sed -n $(expr $line_check)p \
                "$LOG_FILE" | awk '{print $3}' | cut -d. -f1` ))
              other_throughput_num=$(( other_throughput_num + 1 ))
            fi
          done
          # if [ $insert_throughput_num -ge 1 ]
          # then
            # echo "Insert Throughput (ops/sec): " $(( insert_throughput_sum / insert_throughput_num ))
          # fi
          if [ $other_throughput_num -ge 1 ]
          then
            echo "Update/Read Throughput (ops/sec): " $(( other_throughput_sum / other_throughput_num ))
          fi

          operations=("READ" "UPDATE")
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

          print_generic_metrics "$LOG_FILE"
        done
        ;;



      graphbig)
        LOG_FILE=""$BENCHMARK".log"
        print_generic_metrics "$LOG_FILE"
        ;;
    esac

    echo ""
  done
} > "$LOG_DIRECTORY"/results.txt


if [ "$keep_logs" == "false" ]
then
    rm *.log
fi

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
