# Usar una imagen base oficial de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Copiar el archivo de requerimientos y el código de la app
COPY requirements.txt requirements.txt
COPY app.py app.py

# Instalar las dependencias
RUN pip install -r requirements.txt

# Exponer el puerto en el que corre la aplicación
EXPOSE 5000

# Comando por defecto para ejecutar la aplicación
CMD ["python", "app.py"]