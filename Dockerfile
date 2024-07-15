FROM python:3.9

# Install Java (Amazon Corretto)
RUN apt-get update && \
    apt-get install -y java-common wget && \
    wget -O- https://apt.corretto.aws/corretto.key | apt-key add - && \
    echo "deb https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list && \
    apt-get update && \
    apt-get install -y java-11-amazon-corretto-jdk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-11-amazon-corretto
ENV PATH $PATH:$JAVA_HOME/bin

# Install Hadoop
ENV HADOOP_VERSION 3.3.6
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV PATH $PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz && \
    tar -xzf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz && \
    mkdir -p /opt/hadoop/data/namenode /opt/hadoop/data/datanode && \
    chmod -R 777 /opt/hadoop/data

# Configure Hadoop
COPY hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/
COPY core-site.xml ${HADOOP_HOME}/etc/hadoop/

# Set HDFS user environment variables
ENV HDFS_NAMENODE_USER root
ENV HDFS_DATANODE_USER root
ENV HDFS_SECONDARYNAMENODE_USER root
ENV YARN_RESOURCEMANAGER_USER root
ENV YARN_NODEMANAGER_USER root

# Install Spark
ENV SPARK_VERSION 3.5.0
ENV SPARK_HOME /opt/spark
ENV PATH $PATH:${SPARK_HOME}/bin
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} && \
    rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Set Spark environment variables
ENV SPARK_CONF_DIR ${SPARK_HOME}/conf

# Clone LLM-JP Corpus repository and install its requirements
RUN git clone https://github.com/llm-jp/llm-jp-corpus.git /app/llm-jp-corpus && \
    cd /app/llm-jp-corpus && \
    pip install -r requirements.txt && \
    cp -r scripts/*.py /app/llm-jp-corpus/

# Set Python path
ENV PYSPARK_PYTHON python3
ENV PYTHONPATH /app/llm-jp-corpus:/app/llm-jp-corpus/scripts:$PYTHONPATH

# Copy requirements and install dependencies
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt pyspark wandb

# Set system-wide environment variables
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto" >> /etc/environment && \
    echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/environment && \
    echo "export HADOOP_HOME=/opt/hadoop" >> /etc/environment && \
    echo "export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop" >> /etc/environment && \
    echo "export PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin" >> /etc/environment && \
    echo "export HDFS_NAMENODE_USER=root" >> /etc/environment && \
    echo "export HDFS_DATANODE_USER=root" >> /etc/environment && \
    echo "export HDFS_SECONDARYNAMENODE_USER=root" >> /etc/environment && \
    echo "export YARN_RESOURCEMANAGER_USER=root" >> /etc/environment && \
    echo "export YARN_NODEMANAGER_USER=root" >> /etc/environment

# Debug: Print Hadoop configuration
RUN echo "Hadoop configuration:" && \
    cat ${HADOOP_CONF_DIR}/core-site.xml && \
    cat ${HADOOP_CONF_DIR}/hdfs-site.xml && \
    echo "Environment variables:" && \
    env | grep -E "JAVA_HOME|HADOOP_HOME|SPARK_HOME|PATH|HDFS_|YARN_"

WORKDIR /app

# Copy processing script
COPY simple_processing.py /app/
COPY process_data.py /app/
COPY start_process_data.sh /app/
COPY save_raw_data.py /app/
COPY start_save_raw_data.sh /app/
RUN chmod +x /app/start_save_raw_data.sh
RUN chmod +x /app/start_process_data.sh
WORKDIR /app


# Copy processing script and start script
#CMD ["/bin/bash", "/app/start_save_raw_data.sh"]

# Copy processing script and start script
CMD ["/bin/bash", "/app/start_process_data.sh"]
