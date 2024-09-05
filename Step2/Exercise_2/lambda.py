import json
import logging
import os

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("log lambda start")

    logger.info(f"Received event: {json.dumps(event)}")

    return "{} from Lambda!".format(os.environ['greeting'])
