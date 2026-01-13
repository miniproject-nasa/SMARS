import os
from imutils import paths
import face_recognition
import pickle
from PIL import Image
import numpy as np

print("[INFO] start processing faces...")

imagePaths = list(paths.list_images("dataset"))
knownEncodings = []
knownNames = []

for (i, imagePath) in enumerate(imagePaths):
    print(f"[INFO] processing image {i + 1}/{len(imagePaths)}")

    # Extract person name from folder
    name = imagePath.split(os.path.sep)[-2]

    # Load image using PIL (NO OpenCV)
    image = Image.open(imagePath).convert("RGB")
    rgb = np.array(image)

    # Detect face locations
    boxes = face_recognition.face_locations(rgb, model="hog")

    # Compute face encodings
    encodings = face_recognition.face_encodings(rgb, boxes)

    for encoding in encodings:
        knownEncodings.append(encoding)
        knownNames.append(name)

print("[INFO] serializing encodings...")

data = {
    "encodings": knownEncodings,
    "names": knownNames
}

with open("encodings.pickle", "wb") as f:
    pickle.dump(data, f)

print("[INFO] Training complete. Encodings saved to 'encodings.pickle'")
