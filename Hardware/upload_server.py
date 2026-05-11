from flask import Flask, request, jsonify
import os
import subprocess

app = Flask(__name__)

UPLOAD_FOLDER = "/home/smars/Desktop/FaceRecog/dataset"

os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route('/')
def home():
    return "Raspberry Pi Face Recognition Server Running"


@app.route('/upload', methods=['POST'])
def upload():

    try:

        # Person name
        person = request.form.get('person')

        if not person:
            return jsonify({
                "status": "error",
                "message": "Person name missing"
            }), 400

        # Create folder
        person_folder = os.path.join(UPLOAD_FOLDER, person)

        os.makedirs(person_folder, exist_ok=True)

        # Uploaded files
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

        # Start incremental training
        subprocess.Popen([
            "/home/smars/Desktop/FaceRecog/venv/bin/python",
            "/home/smars/Desktop/FaceRecog/incremental_training.py",
            person
        ])

        return jsonify({
            "status": "success",
            "person": person,
            "saved_files": saved_files,
            "message": "Upload successful. Incremental training started."
        })

    except Exception as e:

        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


if __name__ == '__main__':

    app.run(
        host='0.0.0.0',
        port=5000,
        debug=False
    )
