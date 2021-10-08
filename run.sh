#!/bin/bash

total_runs=$([ $# -gt 0 ] && echo "$1" || echo "1")
declare -a benches=("dsb" "ycsb" "graphbig")
keep_logs=$([ $2 == "true" ] && echo "true" || echo "false")

if [[ -z "${BENCHMARK_ROOT}" ]]; then
  BENCHMARK_ROOT=/home/rkuper2/Documents/benchmarks
else
  BENCHMARK_ROOT="${BENCHMARK_ROOT}"
fi
cd $BENCHMARK_ROOT


####################################
#            Benchmarks            #
####################################
for bench in "${benches[@]}"
do
  case $bench in
    dsb)
      {
        echo "#############################"
        echo "#   DeathStarBench: Media   #"
        echo "#############################"
        cd ../deathstarbench/mediaMicroservices
        sudo docker-compose up -d;

        echo "PCM Core Test Beginning:"
        echo "========================"
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/wrk -D exp -L -s /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 10000 -d 300
        done

        echo "PCM Memory Test Beginning:"
        echo "=========================="
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/wrk -D exp -L -s /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 10000 -d 300
        done
        cd ../../
      } > dsb_temp.txt
			;;



    ycsb)
      {
        echo "#############################"
        echo "#            YCSB           #"
        echo "#############################"
        echo "PCM Core Test Beginning:"
        echo "========================"
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb load basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -s -threads 10 -target 15000 > load.dat
          tail -n 110 temp_load.txt
          sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb run basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -s -threads 10 -target 15000 > transactions.dat
          tail -n 110 temp_txn.txt; rm load.dat transactions.dat
        done

        echo "PCM Memory Test Beginning:"
        echo "=========================="
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb load basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -threads 10 -target 15000 > load.dat
          tail -n 110 load.dat
          sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb run basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -threads 10 -target 15000 > transactions.dat
       > temp_txn.txt
          tail -n 110 temp_txn.txt; rm load.dat transactions.dat
        done
      } > ycsb_temp.txt
			;;



    graphbig)
      {
        echo "#############################"
        echo "#          GraphBig         #"
        echo "#############################"
        cd ../graphbig

        echo "PCM Core Test Beginning:"
        echo "========================"
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm --external_program sudo make run
        done

        echo "PCM Memory Test Beginning:"
        echo "=========================="
        for run in $(eval echo {1..$total_runs})
        do
          sudo pcm-memory --external_program sudo make run
        done
        sudo make run
        cat output.log
      } > graphbig_temp.txt
			;;
	esac
done



####################################
#             Metrics              #
####################################
for bench in "${benches[@]}"
do
  echo "Averages for benchmark $bench"

  case $bench in
    dsb)
		  echo "Requests/sec: " \
    		`awk '/Requests\/sec/ {sum += $2; n++} END { if (n > 0) print sum / n; }' \
    		./"$bench"_temp.txt`

		  echo "Transfer/sec: " \
    		`awk '/Transfer\/sec/ {sum += substr($2, 1, length($2)-2); n++} END { if (n > 0) print sum / n; }' \
    		./"$bench"_temp.txt`

		  echo "Average Latency: " \
    		`awk '/Thread Stats / {getline; \
					if (substr($2, length($2), length($2)) == "m") sum += substr($2, 1, length($2)-1) * 60; \
					else sum += substr($2, 1, length($2)-1); n++} END { if (n > 0) print sum / n; }' \
    		./"$bench"_temp.txt`

      tail_vals=("50.000%" "90.000%" "99.000%")
      for tail_val in "${tail_vals[@]}"
      do
        echo "$tail_val Tail: " \
          `awk '/'"$tail_val"'/ {\
          if (substr($2, length($2), length($2)) == "m") sum += substr($2, 1, length($2)-1) * 60; \
          else sum += substr($2, 1, length($2)-1); n++} \
          END { if (n > 0) print sum / n; }' \
          ./"$bench"_temp.txt`
			done
			;;

    ycsb)
      insert_throughput_num=0
      insert_throughput_sum=0
      other_throughput_num=0
      other_throughput_sum=0
      check_lines=($(grep -n "\[OVERALL\], Throughput" ./"$bench"_temp.txt | cut -d: -f1))
      for line_check in "${check_lines[@]}"
      do
      	# line_check=$(expr $line_check - 2)
      	insert_op=`sed -n $(expr $line_check - 2)p ./"$bench"_temp.txt | grep "INSERT" | wc -c`
        if [ $insert_op -ge 1 ]
      	then
      		insert_throughput_sum=$(( insert_throughput_sum + `sed -n $(expr $line_check)p \
      			./"$bench"_temp.txt | awk '{print $3}' | cut -d. -f1` ))
      		insert_throughput_num=$(( insert_throughput_num + 1 ))
      	else
      		other_throughput_sum=$(( other_throughput_sum + `sed -n $(expr $line_check)p \
      			./"$bench"_temp.txt | awk '{print $3}' | cut -d. -f1` ))
      		other_throughput_num=$(( other_throughput_num + 1 ))
      	fi
      done
      echo "Insert Throughput (ops/sec): " $(( insert_throughput_sum / insert_throughput_num ))
      echo "Update/Read Throughput (ops/sec): " $(( other_throughput_sum / other_throughput_num ))

      operations=("INSERT" "READ" "UPDATE")
      for operation in "${operations[@]}"
      do
  		  echo "$operation Latency (us): " \
    	  	`awk '/\['"$operation"'\], AverageLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
    	  	./"$bench"_temp.txt`

  		  echo "$operation 95% Tail Latency (us): " \
    	  	`awk '/\['"$operation"'\], 95thPercentileLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
    	  	./"$bench"_temp.txt`

  		  echo "$operation 99% Tail Latency (us): " \
    	  	`awk '/\['"$operation"'\], 99thPercentileLatency/ {sum += $3; n++} END { if (n > 0) print sum / n; }' \
    	  	./"$bench"_temp.txt`
			done
      ;;

    graphbig)
      ;;
  esac

  echo "IPC: " \
    `awk '/\ TOTAL\ / { sum += $4; n++} END { if (n > 0) print sum / n; }' \
    ./"$bench"_temp.txt`

  echo "L2 Hit Rate: " \
    `awk '/\ TOTAL\ / {sum += $12; n++} END { if (n > 0) print sum / n}' \
    ./"$bench"_temp.txt`

  echo "L3 Hit Rate: " \
    `awk '/\ TOTAL\ / {sum += $11; n++} END { if (n > 0) print sum / n}' \
    ./"$bench"_temp.txt`

  echo "LLC Read Miss Latency: " \
    `awk '/LLCRDMISSLAT \(ns\)/ {getline; getline; sum += $9; n++} END { if (n > 0) print sum / n; }' \
    ./"$bench"_temp.txt`

  echo "System Read Throughput (MB/s): " \
    `awk '/System Read Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    ./"$bench"_temp.txt`

  echo "System Write Throughput (MB/s): " \
    `awk '/System Read Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    ./"$bench"_temp.txt`

  echo "System Memory Throughput (MB/s): " \
    `awk '/System Read Throughput/ {sum += $5; n++} END {if (n > 0) print sum / n}' \
    ./"$bench"_temp.txt`
done

if [ "$keep_logs" == "false" ]
then
	for temp_file in "${arr[@]}"
	do
		rm "$temp_file"_temp.txt
	done
fi
