import os
import json
import random
from pyspark.sql import SparkSession
import wandb

def generate_sample_data(size=1000):
    data = []
    for _ in range(size):
        data.append({
            "id": f"doc_{_}",
            "text": f"This is a sample document number {_}.",
            "length": random.randint(10, 100)
        })
    return data

def main():
    # Initialize WandB
    run = wandb.init(project="example-for-R", job_type="save-raw-data")

    # Create Spark session
    spark = SparkSession.builder.appName("Save-Raw-Data").getOrCreate()

    # Generate sample data
    sample_data = generate_sample_data()

    # Create DataFrame
    df = spark.createDataFrame(sample_data)

    # Define HDFS path
    hdfs_base_dir = "/user/llm-jp-corpus"
    raw_data_dir = f"{hdfs_base_dir}/raw_data"

    # Save raw data to HDFS with overwrite mode
    df.write.mode("overwrite").json(f"hdfs://{raw_data_dir}")

    # Log artifact to WandB
    raw_artifact = wandb.Artifact("raw_data", type="dataset")
    raw_artifact.add_reference(f"hdfs://{raw_data_dir}", name="raw_data_hdfs")
    run.log_artifact(raw_artifact)

    # Log some metrics
    wandb.log({
        "num_documents": df.count(),
        "avg_length": df.agg({"length": "avg"}).collect()[0][0]
    })

    # Stop Spark session
    spark.stop()

    # Finish WandB run
    wandb.finish()

if __name__ == "__main__":
    main()