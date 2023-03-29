
set -x

sudo docker run -d --net=host --name ceresmeta-server \
  -p 2379:2379 \
  ceresdb/ceresmeta-server:v1.0.0

sudo docker run -d --net=host --name ceresdb-server0 \
  -v $(pwd)/config-ceresdb-cluster0.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server:v1.0.0


sudo docker run -d --net=host --name ceresdb-server1 \
  -v $(pwd)/config-ceresdb-cluster1.toml:/etc/ceresdb/ceresdb.toml \
  ceresdb/ceresdb-server:v1.0.0

sudo docker run -d --name ceresdb-server \
  -p 8831:8831 \
  -p 3307:3307 \
  -p 5440:5440 \
  ceresdb/ceresdb-server:v1.0.0
