FROM python:3.12-alpine

WORKDIR /app

COPY register.html .
COPY admin.html .
COPY accounts.html .
COPY account-detail.html .
COPY server.py .

EXPOSE 8080

CMD ["python", "server.py"]
