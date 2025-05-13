FROM eu.gcr.io/entur-system-1287/pelias-api-docker-base:master.20250513-SHA9ad6704

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN mkdir -p /var/log/esclient/
RUN chown pelias /var/log/esclient

USER pelias

ENV NODE_VERSION 22.15.0

# Install nvm with node and npm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && . ~/.nvm/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && node --version \
    && npm --version

ENV NODE_PATH /home/pelias/.nvm/versions/node/v${NODE_VERSION}/bin
ENV PATH $PATH:/home/pelias/.nvm/versions/node/v${NODE_VERSION}/bin
ENV NPM_PATH /home/pelias/.nvm/versions/node/v${NODE_VERSION}/lib/node_modules

# Where the app is built and run inside the docker fs
ENV WORK=/home/pelias
WORKDIR ${WORK}

# copy package.json first to prevent npm install being rerun when only code changes
COPY ./package.json ${WORK}

RUN npm install

COPY . ${WORK}

#  Copying pelias config file
COPY .github/workflows/pelias.json ${WORK}/pelias.json

ENV PELIAS_CONFIG=${WORK}/pelias.json

ENV PORT 3000
EXPOSE 3000

ENTRYPOINT ["/tini", "--", "node","/home/pelias/index.js"]
