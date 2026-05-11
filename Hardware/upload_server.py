from flask import Flask, request, jsonify
import os
import subprocess

app = Flask(__name__)

# Dataset folder
UPLOAD_FOLDER = "/home/smars/Desktop/FaceRecog/dataset"

# Create dataset folder if not existing
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


# Home route
@app.route('/')
def home():
    return "Raspberry Pi Face Recognition Server Running"


# Upload route
@app.route('/upload', methods=['POST'])
def upload():

    try:
        # Get person name
        person = request.form.get('person')

        if not person:
            return jsonify({
                "status": "error",
                "message": "Person name missing"
            }), 400

        # Create person's folder
        person_folder = os.path.join(UPLOAD_FOLDER, person)
        os.makedirs(person_folder, exist_ok=True)

        # Get uploaded images
        files = request.files.getlist("photos")

        if len(files) == 0:
            return jsonify({
                "status": "error",
                "message": "No photos uploaded"
            }), 400

        saved_files = []

        for file in files:

            if file.filename == '':
                continue

            save_path = os.path.join(person_folder, file.filename)

            file.save(save_path)

            saved_files.append(file.filename)

        # Automatically start model training
        subprocess.Popen([
            "/home/smars/Desktop/FaceRecog/venv/bin/python",
            "/home/smars/Desktop/FaceRecog/model_training.py"
        ])

        return jsonify({
            "status": "success",
            "person": person,
            "saved_files": saved_files,
            "message": "Upload successful. Training started automatically."
        })

    except Exception as e:

        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


# Run Flask server
if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False
    )