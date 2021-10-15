## Included Benchmarks
- DeathStarBench (cloud microservices): Hotel Reservation, Media Microservices
- YCSB (cloud/big data): Workloads:
 -  a - 50/50 reads and writes
 - b - 95/5 reads and writes
 - c - 100% reads
 - d - Read latest workload
 - f - Read-modify-write
- GraphBIG (graph computing)
 - BFS
 - DFS
 - Connected Components
 - Degree Centrality
 - K-Core
 - Shortest Path
 - Triangle Count
 - Topological Morph
 - Page Rank
 - Graph Coloring

## Dependencies
Dependencies for DeathStarBench:
- Docker
- Docker-compose
- luarocks
- luasocket
- Python 3.5+
- libssl-dev
- libz-dev

Dependencies for YCSB:
- Maven

Dependencies for GraphBIG:
- nvidia-cuda-toolkit

## Setup
Run the setup script to auto-install dependencies, download larger YCSB datasets, and setup benchmarks:
`$ ./setup.sh`

## Running a Test
Options when running:
- -r - number of runs per test to average
- -s - size of benchmark inputs to use (small, medium=default, large)
- -l - keeps the logs for each individual benchmark
- -b - specify which benchmarks to run (all=default, dsb, ycsb, graphbig)

Example: run three times per benchmark (averaging out results), keeping logs, and run only deathstarbench and ycsb with small workload input sizes:
`$ ./run.sh -r 3 -l -b "dsb ycsb" -s small `
