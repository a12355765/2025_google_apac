# 使用官方 Python 基礎映像檔
FROM python:3.11

# 設定工作目錄
WORKDIR /app

# 複製程式碼進容器
COPY . .

# 安裝依賴
RUN pip install --no-cache-dir -r requirements.txt


# 對外開放埠口
EXPOSE 8080

# 啟動應用程式
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
