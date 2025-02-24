FROM genotek/r-base
COPY ./app/* /srv/
EXPOSE 80/tcp
WORKDIR /srv
CMD ["python3.8", "./server.py"]
