##########################################
#          AUTO-RUN BENCHMARKS           #
##########################################

# Will need cuda toolkit (and NVIDIA GPU)


wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-4-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda nvidia-cuda-toolkit

# Install all necessary dependencies
sudo apt -y install docker libssl-dev libz-dev luarocks
sudo luarocks install luasocket

sudo curl -L "https://github.com/docker/compose/releases/download/2.0.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# GRAPHBIG
curl -L "https://atlarge.ewi.tudelft.nl/graphalytics/zip/cit-Patents.zip" --output ./cit-patent.zip
unzip cit-patent.zip
echo "edge1|edge2" > cit-patent/edge.csv
cat cit-patent/cit-Patents.e >> cit-patent/edge.csv
sed -i 's/ /\|/g' edge.csv
echo "vertex" > cit-patent/vertex.csv
cat cit-patent/cit-Patents.v >> cit-patent/vertex.csv
mv cit-patent graphbig/dataset


