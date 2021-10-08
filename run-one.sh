# EXAMPLE sudo pcm --external_program taskset 0x4000 ./wrk -D exp -L -s ./scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 100000

echo "#############################"
echo "#   DeathStarBench: Media   #"
echo "#############################"
cd deathstarbench/mediaMicroservices
sudo docker-compose up -d;
# python3 /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/scripts/write_movie_info.py -c /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/datasets/tmdb/casts.json -m /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/datasets/tmdb/movies.json && /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/scripts/register_users.sh && /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/scripts/register_movies.sh
echo "PCM Core Test Beginning:"
echo "========================"
sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/wrk -D exp -L -s /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 10000 -d 60
echo "PCM Memory Test Beginning:"
echo "=========================="
sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/wrk -D exp -L -s /home/rkuper2/Documents/benchmarks/deathstarbench/mediaMicroservices/wrk2/scripts/media-microservices/compose-review.lua http://localhost:8080/wrk2-api/review/compose -R 10000 -d 60
cd ../../



echo "#############################"
echo "#            YCSB           #"
echo "#############################"
echo "PCM Core Test Beginning:"
echo "========================"
sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb load basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat > temp_load.txt
tail -n 110 temp_load.txt; rm temp_load.txt
sudo pcm --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb run basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -s -threads 10 -target 100 -p measurementtype=timeseries -p timeseries.granularity=2000 > temp_txn.txt
tail -n 110 temp_txn.txt; rm temp_txn.txt
echo "PCM Memory Test Beginning:"
echo "=========================="
sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb load basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat > temp_load.txt
tail -n 100 temp_load.txt; rm temp_load.txt
sudo pcm-memory --external_program sudo /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/bin/ycsb run basic -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/workloads/workloada -P /home/rkuper2/Documents/benchmarks/ycsb-0.17.0/large.dat -s -threads 10 -target 100 -p measurementtype=timeseries -p timeseries.granularity=2000 > temp_txn.txt
tail -n 100 temp_txn.txt; rm temp_txn.txt



echo "#############################"
echo "#          GraphBig         #"
echo "#############################"
cd graphbig
echo "PCM Core Test Beginning:"
echo "========================"
sudo pcm --external_program sudo make run
echo "PCM Memory Test Beginning:"
echo "=========================="
sudo pcm-memory --external_program sudo make run
sudo make run
cat output.log
