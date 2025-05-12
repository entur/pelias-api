# base image
FROM ubuntu:22.04 AS baseimage

# configure env
ENV DEBIAN_FRONTEND 'noninteractive'

# update apt, install core apt dependencies and delete the apt-cache
# note: this is done in one command in order to keep down the size of intermediate containers
ADD packages.sh .
RUN bash packages.sh

# configure locale
RUN locale-gen 'en_US.UTF-8'
ENV LANG 'en_US.UTF-8'
ENV LANGUAGE 'en_US:en'
ENV LC_ALL 'en_US.UTF-8'

# maintainer information
LABEL maintainer="team@pelias.io"

# configure directories
RUN mkdir -p '/data' '/code/pelias'

# configure volumes
VOLUME "/data"

# configure git
RUN git config --global 'user.email' 'team@pelias.io'
RUN git config --global 'user.name' 'Pelias Docker'

# install nodejs
ENV NODE_VERSION='18.20.5'
RUN git clone 'https://github.com/isaacs/nave.git' /code/nave && /code/nave/nave.sh 'usemain' "${NODE_VERSION}" && rm -rf ~/.nave /code/nave

# add global install dir to $NODE_PATH
ENV NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"

# ensure NPM is up to date
RUN npm i npm -g

# get ready for pelias config with an empty file
ENV PELIAS_CONFIG '/code/pelias.json'
RUN echo '{}' > '/code/pelias.json'

# add a pelias user
RUN useradd -ms /bin/bash pelias

# ensure symlinks, pelias.json, and anything else are owned by pelias user
RUN chown pelias:pelias /data /code -R


# builder image
FROM baseimage AS libpostal_baseimage_builder

# libpostal apt dependencies
# note: this is done in one command in order to keep down the size of intermediate containers
RUN apt-get update && \
    apt-get install -y build-essential autoconf automake libtool pkg-config python3

# clone libpostal
RUN git clone https://github.com/openvenues/libpostal /code/libpostal
WORKDIR /code/libpostal

# install libpostal
RUN ./bootstrap.sh

# https://github.com/openvenues/libpostal/pull/632#issuecomment-1648303654
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      ./configure --datadir='/usr/share/libpostal' --disable-sse2; \
    else \
      ./configure --datadir='/usr/share/libpostal'; \
    fi

# compile
RUN make -j4
RUN DESTDIR=/libpostal make install
RUN ldconfig

# copy address_parser executable
RUN cp /code/libpostal/src/.libs/address_parser /libpostal/usr/local/bin/

# -------------------------------------------------------------

# main image
FROM baseimage AS libpostal_baseimage

# copy data
COPY --from=libpostal_baseimage_builder /usr/share/libpostal /usr/share/libpostal

# copy build
COPY --from=libpostal_baseimage_builder /libpostal /

# ensure /usr/local/lib is on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# test model / executable load correctly
RUN echo '12 example lane, example' | address_parser

FROM libpostal_baseimage

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN mkdir -p /var/log/esclient/
RUN chown pelias /var/log/esclient

USER pelias

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
