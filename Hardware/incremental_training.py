import os
import sys
import pickle
from PIL import Image
import numpy as np
import face_recognition

LOCK_FILE = "training.lock"
ENCODINGS_FILE = "encodings.pickle"
PROCESSED_FILE = "processed_images.txt"

# Prevent multiple training processes
if os.path.exists(LOCK_FILE):
    print("[INFO] Training already running")
    sys.exit()

open(LOCK_FILE, "w").close()

try:

    # Get person name from command argument
    if len(sys.argv) < 2:
        print("[ERROR] Person name missing")
        sys.exit()

    person = sys.argv[1]

    dataset_path = os.path.join("dataset", person)

    if not os.path.exists(dataset_path):
        print("[ERROR] Person folder not found")
        sys.exit()

    # Load existing encodings if available
    if os.path.exists(ENCODINGS_FILE):

        with open(ENCODINGS_FILE, "rb") as f:
            data = pickle.load(f)

    else:

        data = {
            "encodings": [],
            "names": []
        }

    # Load processed image list
    processed_images = set()

    if os.path.exists(PROCESSED_FILE):

        with open(PROCESSED_FILE, "r") as f:
            processed_images = set(f.read().splitlines())

    image_files = os.listdir(dataset_path)

    new_processed = []

    for image_name in image_files:

        image_path = os.path.join(dataset_path, image_name)

        # Skip already processed images
        if image_path in processed_images:
            continue

        print(f"[INFO] Processing {image_path}")

        try:

            # Load image
            image = Image.open(image_path).convert("RGB")
            rgb = np.array(image)

            # Detect faces
            boxes = face_recognition.face_locations(rgb, model="hog")

            # Generate encodings
            encodings = face_recognition.face_encodings(rgb, boxes)

            for encoding in encodings:

                data["encodings"].append(encoding)
                data["names"].append(person)

            new_processed.append(image_path)

        except Exception as e:

            print(f"[ERROR] Failed processing {image_path}")
            print(str(e))

    # Save updated encodings
    with open(ENCODINGS_FILE, "wb") as f:
        pickle.dump(data, f)

    # Save processed images list
    with open(PROCESSED_FILE, "a") as f:

        for item in new_processed:
            f.write(item + "\n")

    print("[INFO] Incremental training complete")

finally:

    # Remove lock file
    if os.path.exists(LOCK_FILE):
        os.remove(LOCK_FILE)