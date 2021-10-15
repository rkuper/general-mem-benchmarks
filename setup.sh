##########################################
#          SETUP FOR BENCHMARKS          #
##########################################

# FIXME: Change the MEM_BENCHMARK_ROOT to match where this directory is
DEFAULT_USER=`users | awk '{print $1}'`
MEM_BENCHMARK_ROOT=/home/"$DEFAULT_USER"/Documents/benchmarks/mem-benchmarks

# Install all necessary dependencies for deathstarbench
sudo apt -y install docker libssl-dev libz-dev luarocks
if [ "$(which luarocks)" == "" ]; then
  sudo luarocks install luasocket
fi

if [ ! -d /usr/local/bin/docker-compose ]; then
  sudo curl -L "https://github.com/docker/compose/releases/download/2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi



#################################
#        SETUP GRAPHBIG         #
#################################
# Download GraphBIG datasets
if [ ! -d ./graphBIG/dataset/cit-patent ]; then
  curl -L "https://atlarge.ewi.tudelft.nl/graphalytics/zip/cit-Patents.zip" --output ./cit-patent.zip
  unzip cit-patent.zip
  echo "edge1|edge2" > cit-patent/edge.csv
  cat cit-patent/cit-Patents.e >> cit-patent/edge.csv
    sed -i 's/ /\|/g' edge.csv
  echo "vertex" > cit-patent/vertex.csv
  cat cit-patent/cit-Patents.v >> cit-patent/vertex.csv
  mv cit-patent graphBIG/dataset
fi

# NOTE: this dataset is a bit bigger, so it may take some more time, especially anything using the edge.csv file
if [ ! -d ./graphBIG/dataset/graph500-22 ]; then
  curl -L "https://atlarge.ewi.tudelft.nl/graphalytics/zip/graph500-22.zip" --output ./graph500-22.zip
  unzip graph500-22.zip
  echo "edge1|edge2" > graph500-22/edge.csv
  cat graph500-22/graph500-22.e >> graph500-22/edge.csv
    sed -i 's/ /\|/g' edge.csv
  echo "vertex" > graph500-22/vertex.csv
  cat graph500-22/graph500-22.v >> graph500-22/vertex.csv
  mv graph500-22 graphBIG/dataset
fi

# Will need CUDA toolkit (and NVIDIA GPU) for GraphBIG
if [ "$(which nvcc)" == "" ]; then
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
  sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
  wget https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
  sudo dpkg -i cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
  sudo apt-key add /var/cuda-repo-ubuntu2004-11-4-local/7fa2af80.pub
  sudo apt-get update
  sudo apt-get -y install cuda nvidia-cuda-toolkit
fi



#######################################
#        SETUP DEATHSTARBENCH         #
#######################################
# The docker-compose command may not work the first time, it sometimes has issues
cd DeathStarBench; git apply ../benchmark-patches/deathstarbench.patch
cd hotelReservation; docker stop `docker ps -qa`; docker-compose up -d
cd wrk2; make

cd mediaMicroservices; docker stop `docker ps -qa`; docker-compose up -d
python3 scripts/write_movie_info.py -c ./datasets/tmdb/casts.json -m ./datasets/tmdb/movies.json && scripts/register_users.sh && scripts/register_movies.sh
cd wrk2; make
cd ../../..
