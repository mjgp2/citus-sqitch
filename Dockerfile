FROM postgres:12-alpine

RUN apk --no-cache --virtual .build-deps --update add clang clang-dev gcc make g++ zlib-dev curl llvm && \
  ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.15.1 | tar -xz -C . ) \
  && cd ./postgresql-hll-2.15.1 && make && make install && \
  apk del .build-deps && \
  echo "shared_preload_libraries = 'hll'" >> /usr/local/share/postgresql/postgresql.conf.sample

