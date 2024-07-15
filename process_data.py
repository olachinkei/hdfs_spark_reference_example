import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType
import wandb

def process_text(text):
    # Simple processing: convert to uppercase
    return text.upper()

def main():
    # Initialize WandB
    run = wandb.init(project="example-for-R", job_type="process-data")

    # Create Spark session
    spark = SparkSession.builder.appName("Process-Data").getOrCreate()

    # Use the raw data artifact
    raw_artifact = run.use_artifact('wandb-japan/example-for-R/raw_data:latest', type='dataset')
    raw_data_path = raw_artifact.get_path("raw_data_hdfs")
    raw_data_path = raw_data_path.ref 
    print("print(raw_data_path) ->", raw_data_path)


    # Define HDFS path for processed data
    hdfs_base_dir = "/user/llm-jp-corpus"
    processed_data_dir = f"{hdfs_base_dir}/processed_data"

    # Read raw data from HDFS
    df = spark.read.json(raw_data_path)

    # Define UDF for text processing
    process_text_udf = udf(process_text, StringType())

    # Apply processing
    processed_df = df.withColumn("processed_text", process_text_udf(df.text))

    # Save processed data to HDFS with overwrite mode
    processed_df.write.mode("overwrite").json(f"hdfs://{processed_data_dir}")

    # Log processed artifact to WandB
    processed_artifact = wandb.Artifact("processed_data", type="dataset")
    processed_artifact.add_reference(f"hdfs://{processed_data_dir}", name="processed_data_hdfs")
    run.log_artifact(processed_artifact)

    # Log some metrics
    wandb.log({
        "num_documents": processed_df.count(),
        "avg_length": processed_df.agg({"length": "avg"}).collect()[0][0]
    })

    # Stop Spark session
    spark.stop()

    # Finish WandB run
    wandb.finish()

if __name__ == "__main__":
    main()