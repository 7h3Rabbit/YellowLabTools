FROM sitespeedio/sitespeed.io:35.7.4

USER root

ENV WEBPERF_RUNNER=docker

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome

ENV PATH="/usr/local/bin:${PATH}"

# https://codereview.stackexchange.com/a/286565
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# YLT/phantomas should pick this up and use --no-sandbox
ENV LAMBDA_TASK_ROOT=/trick/phantomas

RUN apt-get update &&\
    apt-get install -y --no-install-recommends curl gcc g++ gnupg unixodbc-dev openssl git default-jre default-jdk && \
    apt-get install -y software-properties-common ca-certificates && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev wget libbz2-dev libsqlite3-dev && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN apt update

RUN apt -y autoremove

# Add user so we don't need --no-sandbox.
RUN groupadd --system sitespeedio && \
    useradd --system --create-home --gid sitespeedio sitespeedio && \
    mkdir --parents /usr/src/runner
RUN chown --recursive sitespeedio:sitespeedio /usr/src/runner

WORKDIR /usr/src/runner

RUN echo 'ALL ALL=NOPASSWD: /usr/sbin/tc, /usr/sbin/route, /usr/sbin/ip' > /etc/sudoers.d/tc

# https://github.com/puppeteer/puppeteer/issues/8148#issuecomment-1397528849
RUN Xvfb -ac :99 -screen 0 1280x1024x16 & export DISPLAY=:99

RUN npm install -g node-gyp puppeteer

# If own settings.json exists it will overwrite the default
COPY . /usr/src/runner

RUN chown --recursive sitespeedio:sitespeedio /usr/src/runner

# Run everything after as non-privileged user.
USER sitespeedio

RUN npm install

ENTRYPOINT []

CMD ["node", "bin/cli.js"]