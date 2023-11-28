# *Sentiment Analysis Inference Engine*

This repo contains a template for a sentiment analysis inference engine. The terraform code will create a google cloud function that will be triggered by a pubsub topic. The function will read the message from the topic, perform sentiment analysis on the message, and write the result to a bigquery table.