FROM python:3.11.9-alpine

ENV DEV="true"
ENV DB_NAME="excero_db"
ENV DB_USER="excero"
ENV DB_PASSWORD="exc3r0"
ENV DB_HOST="localhost"
ENV DB_PORT="3306"
ENV DJANGO_SUPERUSER_USERNAME="admin"
ENV DJANGO_SUPERUSER_PASSWORD="admin"
ENV DJANGO_SUPERUSER_EMAIL="admin@BACKEND ADDRESS"
ENV TRUSTED_ORIGINS="BACKEND ADDRESS"
#ENV FRONTEND_URL="pairwise-ranking.com"

WORKDIR backend

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /wait
RUN chmod +x /wait && adduser -D -G www-data www-data
RUN apk update && apk add musl-dev mariadb-dev git build-base alpine-sdk gcc
RUN pip install --upgrade pip && pip install gunicorn && pip install mysqlclient

COPY . /backend
RUN pip install -r requirements.txt
CMD python manage.py makemigrations

RUN touch logs.txt && chown www-data: logs.txt
RUN touch serializer_logs.txt && chown www-data: serializer_logs.txt
RUN mkdir avatarpieces && chown -R www-data: avatarpieces
RUN mkdir sep_previews && chown -R www-data: sep_previews
RUN mkdir reports && chown -R www-data: reports

EXPOSE 80
STOPSIGNAL SIGTERM
CMD cd /backend && /wait && python manage.py collectstatic --no-input && python manage.py migrate && gunicorn backend.wsgi --user www-data --bind 0.0.0.0:80

