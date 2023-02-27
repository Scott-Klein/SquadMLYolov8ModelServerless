from ultralytics import YOLO
from PIL import Image

# Load a model
model = YOLO("best.pt")  # load a pretrained model (recommended for training)

image = Image.open("test4.png")  # load an image
results = model(source=image, save=True)  # predict on an image
for bot in results.boxes:
    print(bot.xywh.toList())
for item in results:
    print(item)



