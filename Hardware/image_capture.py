import cv2
import os
import time
from datetime import datetime
from picamera2 import Picamera2

def create_folder(name):
    """Creates a folder for the person inside the dataset directory."""
    dataset_folder = "dataset"
    if not os.path.exists(dataset_folder):
        os.makedirs(dataset_folder)
    
    person_folder = os.path.join(dataset_folder, name)
    if not os.path.exists(person_folder):
        os.makedirs(person_folder)
    return person_folder

def save_person_details(name, details):
    """Saves person's details in a text file."""
    folder = create_folder(name)
    details_file = os.path.join(folder, "details.txt")
    with open(details_file, "w") as file:
        file.write(f"Name: {name}\n")
        file.write(f"Details: {details}\n")
    print(f"Details saved for {name}.")

def capture_photos(name):
    """Captures photos and saves them in the respective folder."""
    folder = create_folder(name)
    
    try:
        # Initialize Pi Camera
        picam2 = Picamera2()
        picam2.preview_configuration.main.size = (640, 480)
        picam2.preview_configuration.main.format = "BGR888"
        picam2.configure("preview")
        picam2.start()
        
        time.sleep(2)  # Allow camera to warm up
        
        photo_count = 0
        
        print(f"Taking photos for {name}. Press SPACE to capture, 'q' to quit.")
        
        while True:
            frame = picam2.capture_array()
            frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)  # Convert to BGR for OpenCV display
            
            cv2.imshow('Capture', frame)
            
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord(' '):  # Space key
                photo_count += 1
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"{name}_{timestamp}.jpg"
                filepath = os.path.join(folder, filename)
                cv2.imwrite(filepath, frame)
                print(f"Photo {photo_count} saved: {filepath}")
            
            elif key == ord('q'):  # Q key
                break
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Release the camera and close OpenCV windows
        cv2.destroyAllWindows()
        picam2.stop()
        print(f"Photo capture completed. {photo_count} photos saved for {name}.")

if __name__ == "__main__":
    person_name = input("Enter the person's name: ").strip()
    person_details = input("Enter details about the person: ").strip()
    
    save_person_details(person_name, person_details)
    capture_photos(person_name)
