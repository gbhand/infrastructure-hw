FROM python:3.11-alpine3.19

COPY src /src
WORKDIR /src
RUN pip install -r requirements.txt
CMD [ "python", "main.py" ]