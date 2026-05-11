#!/usr/bin/env python3

import cv2
import numpy as np
import time
import pickle
import os
from picamera2 import Picamera2
import face_recognition
import subprocess

# Set working directory
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

print(f"Working Directory Set To: {os.getcwd()}")

# 🔊 BLOCKING Speak function
def speak(text):

    print(f"[DEBUG] Speaking: {text}")

    subprocess.run(
        f'pico2wave -l en-US -w temp.wav "{text}"',
        shell=True,
        check=True
    )

    subprocess.run(
        f'aplay -D plughw:CARD=Headphones,DEV=0 temp.wav',
        shell=True,
        check=True
    )

# Speak name → pause → details
def speak_person(name, details):

    speak(name)

    time.sleep(1)

    if details.strip():
        speak(details)

# Load ONLY details
def load_person_details():

    details_dict = {}

    dataset_folder = "dataset"

    if os.path.exists(dataset_folder):

        for person_name in os.listdir(dataset_folder):

            person_dir = os.path.join(dataset_folder, person_name)

            details_file = os.path.join(person_dir, "details.txt")

            if os.path.isfile(details_file):

                with open(details_file, "r") as file:

                    for line in file:

                        if line.lower().startswith("details"):

                            details_dict[person_name] = (
                                line.split(":", 1)[1].strip()
                            )

    return details_dict

person_details = load_person_details()

print(f"Loaded Person Details: {person_details}")

# Load encodings
with open("encodings.pickle", "rb") as f:

    data = pickle.loads(f.read())

known_face_encodings = data["encodings"]
known_face_names = data["names"]

# Camera
picam2 = Picamera2()

picam2.preview_configuration.main.size = (640, 480)
picam2.preview_configuration.main.format = "RGB888"

picam2.configure("preview")

picam2.start()

time.sleep(5)

FACE_DISTANCE_THRESHOLD = 0.5

# Stores last time a known person was spoken
last_spoken = {}

# Stores last time unknown person was spoken
last_unknown_spoken = 0

# Cooldown in seconds before repeating speech
SPEAK_COOLDOWN = 10

def process_frame(frame):

    global last_unknown_spoken

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    locations = face_recognition.face_locations(rgb)

    encodings = face_recognition.face_encodings(
        rgb,
        locations,
        model="large"
    )

    names = []

    for encoding in encodings:

        distances = face_recognition.face_distance(
            known_face_encodings,
            encoding
        )

        best_index = np.argmin(distances)

        now = time.time()

        # UNKNOWN PERSON
        if distances[best_index] >= FACE_DISTANCE_THRESHOLD:

            # Speak unknown person every cooldown
            if now - last_unknown_spoken > SPEAK_COOLDOWN:

                speak("Unknown person")

                last_unknown_spoken = now

            names.append(("Unknown", ""))

            continue

        # KNOWN PERSON
        name = known_face_names[best_index]

        details = person_details.get(name, "")

        # Speak BOTH name and details every cooldown
        if (
            name not in last_spoken
            or now - last_spoken[name] > SPEAK_COOLDOWN
        ):

            speak_person(name, details)

            last_spoken[name] = now

        names.append((name, details))

    return locations, names

# Main loop
while True:

    frame = picam2.capture_array()

    face_locations, face_names = process_frame(frame)

    for (top, right, bottom, left), (name, _) in zip(
        face_locations,
        face_names
    ):

        # Green for known, Red for unknown
        color = (
            (0, 255, 0)
            if name != "Unknown"
            else (0, 0, 255)
        )

        cv2.rectangle(
            frame,
            (left, top),
            (right, bottom),
            color,
            2
        )

        cv2.putText(
            frame,
            name,
            (left, top - 10),
            cv2.FONT_HERSHEY_DUPLEX,
            0.6,
            (255, 255, 255),
            1
        )

    cv2.imshow("Video", frame)

    # Press Q to quit
    if cv2.waitKey(1) & 0xFF == ord("q"):

        break

cv2.destroyAllWindows()

picam2.stop()