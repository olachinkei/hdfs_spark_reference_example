#!/bin/bash

set -e
set -x

# Set up environment variables
export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
export PATH=$JAVA_HOME/bin:$PATH
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
export PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root

# Start HDFS
$HADOOP_HOME/bin/hdfs --daemon start namenode
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Wait for HDFS to be ready
sleep 30

# Set up Python path
export PYTHONPATH=/app/llm-jp-corpus:/app/llm-jp-corpus/scripts:$PYTHONPATH

# Run the processing script
echo "Running the save raw data script..."
$SPARK_HOME/bin/spark-submit \
  --master 'local[*]' \
  --conf spark.hadoop.fs.defaultFS=hdfs://localhost:9000 \
  /app/save_raw_data.py

# Stop HDFS
$HADOOP_HOME/bin/hdfs --daemon stop datanode
$HADOOP_HOME/bin/hdfs --daemon stop namenode