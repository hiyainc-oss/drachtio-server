
FROM debian:stretch-slim AS base
RUN apt-get update \
 && apt-get -y --quiet --force-yes upgrade

FROM base as builder
RUN apt-get install -y --no-install-recommends ca-certificates gcc g++ make build-essential cmake git autoconf automake  curl libtool libtool-bin libssl-dev libcurl4-openssl-dev zlib1g-dev
ENV SOURCE_ROOT /usr/local/src/drachtio-server
ENV BUILD_MODE local-source

FROM builder as local-source
COPY . $SOURCE_ROOT

FROM builder as git-source
RUN git clone --depth=50 --branch=develop git://github.com/davehorton/drachtio-server.git $SOURCE_ROOT \
  && cd $SOURCE_ROOT \
  && git submodule update --init --recursive

FROM $BUILD_MODE as object
WORKDIR $SOURCE_ROOT
RUN ./bootstrap.sh \
  && mkdir $SOURCE_ROOT/build \
  && cd $SOURCE_ROOT/build \
  && $SOURCE_ROOT/configure CPPFLAGS='-DNDEBUG' CXXFLAGS='-O0' \
  && make \
  && make install

FROM base AS server
COPY --from=object /usr/local/bin/drachtio /usr/local/bin/drachtio
COPY ./entrypoint.sh /
VOLUME ["/config"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["drachtio"]
