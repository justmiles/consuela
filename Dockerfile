FROM node:boron-slim

# General
ENV SITE_URI "http://localhost:8080"
ENV PORT "8080"

# Slack
ENV HUBOT_SLACK_TOKEN ""

# qBittorrent
ENV QBITTORRENT_PASSWORD ""
ENV QBITTORRENT_PORT "8686"
ENV QBITTORRENT_USERNAME "justmiles"
ENV QBITTORRENT_HOST "localhost"

# S3 brain
ENV HUBOT_S3_BRAIN_ACCESS_KEY_ID ""
ENV HUBOT_S3_BRAIN_SECRET_ACCESS_KEY ""
ENV HUBOT_S3_BRAIN_BUCKET "milesmaddox"
ENV HUBOT_S3_BRAIN_FILE_PATH "apps/consuela/consuela.json"
ENV HUBOT_S3_BRAIN_SAVE_INTERVAL "60"
ENV AWS_REGION "us-west-2"

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app

RUN adduser \
  --uid 256 consuela \
  --shell /bin/bash \
  --home /usr/src/app \
  --disabled-password \
  --no-create-home \
  --gecos ''

COPY ./ /usr/src/app/

RUN chown -R consuela:consuela /usr/src/app/

USER consuela

WORKDIR /usr/src/app

RUN npm install

EXPOSE 8080

ENTRYPOINT ["/usr/src/app/bin/consuela"]

CMD ["--name consuela","--adapter slack"]
