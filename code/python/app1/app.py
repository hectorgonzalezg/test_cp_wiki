from flask import Flask, request, jsonify
import boto3
import os

app = Flask(__name__)

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify(status="UP"), 200

# Upload file to S3 endpoint
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify(error="No file part"), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify(error="No selected file"), 400
    
    s3_bucket = os.getenv('S3_BUCKET')
    
    if not s3_bucket:
        return jsonify(error="S3 bucket not configured"), 500
    
    s3_client = boto3.client('s3')
    
    try:
        s3_client.upload_fileobj(file, s3_bucket, file.filename)
        return jsonify(message="File uploaded successfully"), 200
    except Exception as e:
        return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)