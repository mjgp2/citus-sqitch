FROM postgres:12.6

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl build-essential ca-certificates \
      "postgresql-plpython3-$PG_MAJOR=$PG_VERSION" "postgresql-$PG_MAJOR-partman" "postgresql-server-dev-$PG_MAJOR=$PG_VERSION" "postgresql-client-$PG_MAJOR=$PG_VERSION"

RUN ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.15.1 | tar -xz -C . ) && \
     cd ./postgresql-hll-2.15.1 && make && make install && \
     echo "shared_preload_libraries = 'hll'" >> /usr/share/postgresql/postgresql.conf.sample

RUN apt-get install -y sqitch libdbd-pg-perl 

RUN apt-get install -y python3-pip && pip3 install 'boto3>=1.17.55' && \
  ( curl -L https://github.com/mjgp2/postgres-aws-s3/tarball/master  | tar -xz -C . ) && \
  cd ./chimpler-postgres-aws-s3-* && make && make install
