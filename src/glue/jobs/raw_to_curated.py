import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.window import Window

# -------------------------------------------------------------------
# Job arguments
# -------------------------------------------------------------------
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "RAW_DATABASE",
        "RAW_TABLE",
        "CURATED_BUCKET",
        "CURATED_PREFIX"
    ]
)

# -------------------------------------------------------------------
# Spark / Glue context
# -------------------------------------------------------------------
sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)

# -------------------------------------------------------------------
# Read raw data from Glue Catalog
# -------------------------------------------------------------------
raw_df = glue_context.create_dynamic_frame.from_catalog(
    database=args["RAW_DATABASE"],
    table_name=args["RAW_TABLE"]
).toDF()

# -------------------------------------------------------------------
# Basic schema enforcement
# -------------------------------------------------------------------
required_columns = ["user_id", "event_time", "event_type"]

missing_cols = [c for c in required_columns if c not in raw_df.columns]
if missing_cols:
    raise ValueError(f"Missing required columns: {missing_cols}")

# -------------------------------------------------------------------
# Deduplication logic (event-time based)
# -------------------------------------------------------------------
window_spec = Window.partitionBy("user_id", "event_time", "event_type") \
                    .orderBy(F.col("event_time").desc())

deduped_df = (
    raw_df
    .withColumn("row_num", F.row_number().over(window_spec))
    .filter(F.col("row_num") == 1)
    .drop("row_num")
)

# -------------------------------------------------------------------
# Add partition column
# -------------------------------------------------------------------
curated_df = deduped_df.withColumn(
    "event_date",
    F.to_date(F.col("event_time"))
)

# -------------------------------------------------------------------
# Write curated data to S3 (idempotent)
# -------------------------------------------------------------------
output_path = f"s3://{args['CURATED_BUCKET']}/{args['CURATED_PREFIX']}"

(
    curated_df
    .write
    .mode("append")
    .partitionBy("event_date")
    .format("parquet")
    .save(output_path)
)

# -------------------------------------------------------------------
# Commit job
# -------------------------------------------------------------------
job.commit()
