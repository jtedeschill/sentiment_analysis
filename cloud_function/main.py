import requests
import json
from openai import OpenAI
import openai
import time
import logging
import os
import re
import flask
import functions_framework
from google.cloud import pubsub_v1
from openai import OpenAI

logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(message)s", level=logging.INFO
)

logger = logging.getLogger(__name__)

project_id = os.environ["PROJECT_ID"]
topic_name = "classify-emails-topic"
api_key = os.environ["OPENAI_API_KEY"]

os.environ["GOOGLE_PROJECT_ID"] = project_id
client = OpenAI(
    api_key=api_key,
)


def classify_email(client, email_content=""):
    response = client.chat.completions.create(
        model="gpt-3.5-turbo-1106",
        response_format={"type": "json_object"},
        messages=[
            {
                "role": "system",
                "content": """You are a robot sentiment classifier, 
    specializing in classifying emails into positive, neutral, negative, `out of office`, `left the company`,  `tool notification` categories. 
    You are given an email and asked to classify it into one of these categories.
    designed to output JSON, being the key "result" and the value being the classification.""",
            },
            {"role": "user", "content": f"{email_content}"},
        ],
    )
    logging.info(f"Response: {response}")

    return response


@functions_framework.http
def main(request: flask.Request) -> flask.typing.ResponseReturnValue:
    """Responds to any HTTP request.
    Args:
        request (flask.Request): HTTP request object.
    Returns:

    """
    request_json = request.get_json()


    request_content = request_json["subject"] + " " + re.sub(r">+", ">", request_json["description"])[:150 ]

    try:
        res = classify_email(client=client, email_content=request_content)

        logging.info(f"Request: {request_content}")
        logging.info(f"Response: {res}")

        request_json["openai_response"] = json.loads(res.choices[0].message.content)[
            "result"
        ]
        request_json["openai_total_tokens"] = res.usage.total_tokens
        request_json["openai_completion_tokens"] = res.usage.completion_tokens
        request_json["openai_prompt_tokens"] = res.usage.prompt_tokens
        request_json["openai_model"] = res.model
        request_json["openai_system_fingerprint"] = res.system_fingerprint
        request_json["openai_created"] = str(res.created)
        request_json["openai_object"] = res.object
        request_json["openai_id"] = res.id


        task_id = request_json["task_id"]
        
       # publish to pubsub
        publisher = pubsub_v1.PublisherClient()

        topic_path = publisher.topic_path(project_id, topic_name)

        data = json.dumps(request_json).encode("utf-8")
        
        # validate schema against json schema
        # https://cloud.google.com/pubsub/docs/schemas
        logging.info(f"Data: {data}")

        # save json into a file using json.dumps

        # with open("request_json.json", "w") as f:
        #     f.write(json.dumps(request_json))

        future = publisher.publish(topic_path, data=data)

        logging.info(f"Published messages to {topic_path}.")
        logging.info(future.result())


        



        return "OK"
    except Exception as e:
        logging.error(f"Error: {e}")
        return "Error"
