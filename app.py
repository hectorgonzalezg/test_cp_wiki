from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '¡Hola Mundo desde Flask en un contenedor Docker!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8085)
