# Dockerfile
FROM python:3.8

# Çalışma dizinini oluştur
WORKDIR /app

# Gereksinimlerinizi yükleyin
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyalayın
COPY app /app

# Uvicorn ile çalıştırın
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
