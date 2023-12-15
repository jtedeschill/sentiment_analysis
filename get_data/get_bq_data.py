import os
import logging
import requests
import json

import google.cloud.bigquery as bq
from google.oauth2 import service_account

import pandas as pd
from dotenv import load_dotenv
import datetime


# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


load_dotenv()


# Set up credentials
credentials = service_account.Credentials.from_service_account_file(
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'])

# Set up client
client = bq.Client(credentials=credentials, project=credentials.project_id)

# Set up query

query = """
select 
    task_id,
    account_id,
    description,
    subject
 from `hired-393411.Hired.sfdc_task` 
 where task_subtype = 'Email' and subject like '%[In]%' and task_id not in (select distinct task_id from `hired-393411.Hired.classified_emails`) and task_id in ('00T6T00007l8lMbUAI',
'00T6T00007l8k98UAA',
'00T6T00007l8LR6UAM',
'00T6T00007l8heNUAQ',
'00T6T00007l8nOdUAI',
'00T6T00007l8mBZUAY',
'00T6T00007l8kkWUAQ',
'00T6T00007l8howUAA',
'00T6T00007l8nMjUAI',
'00T6T00007l8kvXUAQ',
'00T6T00007l8kHuUAI',
'00T6T00007l8WXRUA2',
'00T6T00007l8igLUAQ',
'00T6T00007l8hYyUAI',
'00T6T00007l8idqUAA',
'00T6T00007l8l26UAA',
'00T6T00007l8i0yUAA',
'00T6T00007l8iZyUAI',
'00T6T00007l8ifSUAQ',
'00T6T00007l8irTUAQ'
)
 order by created_date desc
 limit 1000
 """
logger.info(f"Running query: {query}")



# Run query
query_job = client.query(query)

# send call cloud function 

# Get results and to each line call cloud function
logger.info("Getting results")

results = query_job.result()



for row in results:

    # convert to json
    row = dict(row.items())
    print(row.keys())
    
    data =  row

    for key, value in data.items():
        if isinstance(value, datetime.datetime):
            data[key] = value.strftime('%Y-%m-%d %H:%M:%S')



    # curl localhost:8080 make this in python

    # requests.post('http://localhost:8080', json=data)



    try:
        logging.info(f"Task id: {data['task_id']}")
        r = requests.post(os.environ['GOOGLE_CLOUD_FUNCTION_URL'], json=data)
        logging.info(f"Response: {r}")
        logging.info(f"Status code: {r.status_code}")
        logging.info(f"Content: {r.content}")
        logging.info(f"url: {r.url}")
    except:
        logging.info(f"Error: {r}")
# Output: Hello world!

# Send json to cloud function




# # Set up query
# query = """
# select *
#  from `hired-393411.Hired.sfdc_task`

