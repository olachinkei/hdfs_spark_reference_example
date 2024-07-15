# hdfs_spark_reference_example
Example of logging data on hfds with wandb reference artifacts

You can try 
1) create original dataset on hfds and track it with wandb reference artifacts
2) create the preprocessed dataset by referring the original dataset with wandb and track it again with wandb reference artifacts


# How to use
## Preparation
Please update the following env variable in docker-compose.yaml
```
- WANDB_API_KEY=<your api key>
- WANDB_ENTITY=<your entity name>
- WANDB_PROJECT=<your project name>
```

## Step1: Log original data
Let's log the reference of the original dataset.
Please comment out a line of script in Docker file in the following way.

```
# Copy processing script and start script
CMD ["/bin/bash", "/app/start_save_raw_data.sh"]
# Copy processing script and start script
#CMD ["/bin/bash", "/app/start_process_data.sh"]
```
Then, run
```
docker-compose up --build
```

## Step2: Log processed data 
Let's log the reference of the processed data
Please comment out a line of script in Docker file in the following way.

```
# Copy processing script and start script
#CMD ["/bin/bash", "/app/start_save_raw_data.sh"]
# Copy processing script and start script
CMD ["/bin/bash", "/app/start_process_data.sh"]
```
Then, run
```
docker-compose up --build
```
