FROM apache/airflow:3.2.2

COPY requirements-ai.txt /requirements-ai.txt
RUN pip install --no-cache-dir -r /requirements-ai.txt
