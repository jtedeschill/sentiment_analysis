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

logging.basicConfig(level=logging.INFO)

# set up credentials
os.environ["OPENAI_API_KEY"] = "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"
# Set your OpenAI API key here
# api_key = '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'


from openai import OpenAI


client = OpenAI(
    organization="org-JHa1sYOmrIQwUqtyA0oFYzPB",
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
    Always respond with one of the following: positive, neutral, or negative. designed to output JSON, being the key "result" and the value being the classification.""",
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
        request_json["openai_created"] = res.created
        request_json["openai_object"] = res.object
        request_json["openai_id"] = res.id


        task_id = request_json["task_id"]

        with open(f"{task_id}_classified.json", "w") as f:
            json.dump(request_json, f)

        return "OK"
    except Exception as e:
        logging.error(f"Error: {e}")
        return "Error"
