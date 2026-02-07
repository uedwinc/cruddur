# cruddur-messaging-stream.py
import os
import json
import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ.get("TABLE_NAME", "cruddur-messages")
GSI_NAME = os.environ.get("GSI_NAME", "message-group-sk-index")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    # Expecting NEW_IMAGE stream view; handle one record per batch (BatchSize=1)
    record = event["Records"][0]
    keys = record["dynamodb"]["Keys"]
    pk = keys["pk"]["S"]
    sk = keys["sk"]["S"]

    if pk.startswith("MSG#"):
        group_uuid = pk.replace("MSG#", "")
        new_image = record["dynamodb"].get("NewImage", {})
        message = new_image.get("message", {}).get("S", "")

        print("GRUP ===>", group_uuid, message)

        # Query the GSI to get message-group rows for this group
        data = table.query(
            IndexName=GSI_NAME,
            KeyConditionExpression=Key("message_group_uuid").eq(group_uuid)
        )
        print("RESP ===>", data.get("Items", []))

        # Recreate the message group rows with updated SK and message
        for i in data.get("Items", []):
            delete_item = table.delete_item(Key={"pk": i["pk"], "sk": i["sk"]})
            print("DELETE ===>", delete_item)
            response = table.put_item(
                Item={
                    "pk": i["pk"],
                    "sk": sk,
                    "message_group_uuid": i["message_group_uuid"],
                    "message": message,
                    "user_display_name": i.get("user_display_name"),
                    "user_handle": i.get("user_handle"),
                    "user_uuid": i.get("user_uuid")
                }
            )
            print("CREATE ===>", response)