import json
import base64
from PIL import Image
import io
import yaml
import torch
import numpy as np
from ultralytics import YOLO

def init_context(context):
    context.logger.info("Init context...  0%")

    # Read labels
    with open("/opt/nuclio/function.yaml", 'rb') as function_file:
        functionconfig = yaml.safe_load(function_file)

    labels_spec = functionconfig['metadata']['annotations']['spec']
    labels = {item['id']: item['name'] for item in json.loads(labels_spec)}

    # Read the DL model
    model = YOLO("best.pt")
    context.user_data.model = model
    context.user_data.labels = labels
    context.logger.info("Init context...100%")

def handler(context, event):
    context.logger.info("Run yolo-v3-tf model")
    data = event.body
    buf = io.BytesIO(base64.b64decode(data["image"]))
    threshold = float(data.get("threshold", 0.5))
    image = Image.open(buf)
    labels = context.user_data.labels
    results = context.user_data.model.predict(image)
    output = []

    for result in results:
        num_rows = result.boxes.xyxy.size()[0]
        print(num_rows)
        for i in range(num_rows):
            print('row: ', i)
            points = result.boxes.xyxy[i].tolist()
            print(points)
            label = labels[result.boxes.cls[i].item()]
            print(label)
            confidence = result.boxes.conf[i].item()
            print(confidence)

            #label = labels[result.boxes.cls[i]]
            if confidence > threshold:
                output.append({
                    "label": label,
                    "confidence": confidence,
                    "points": points,
                    "type": "rectangle"
                })

    return context.Response(body=json.dumps(output), headers={},
        content_type='application/json', status_code=200)
