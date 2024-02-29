FROM postgres:15.5 as base

FROM base as builder

# docker buildx build --push --platform linux/amd64,linux/arm64 -t mjgp2/pg-sqitch:15.5 .

RUN apt-get update \
  && apt-get install -y --no-upgrade --no-install-recommends curl build-essential ca-certificates "postgresql-server-dev-$PG_MAJOR=$PG_VERSION" \
  && ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.17 | tar -xz -C . ) \
  && cd ./postgresql-hll-2.17 && make && make install && cd .. && rm -rf ./postgresql-hll-2.17 \
  && ( curl -L https://github.com/chimpler/postgres-aws-s3/tarball/master  | tar -xz -C . ) \
  && cd ./chimpler-postgres-aws-s3-* && make && make install && cd .. && rm -rf ./chimpler-postgres-aws-s3-* \
  && apt-get purge -y --auto-remove curl build-essential ca-certificates "postgresql-server-dev-$PG_MAJOR" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ /var/cache/apt/archives/ /var/cache/

FROM base
COPY --from=builder /usr/share/postgresql/15/extension /usr/share/postgresql/15/extension
COPY --from=builder /usr/lib/postgresql/15/lib/ /usr/lib/postgresql/15/lib/
RUN apt-get update \
  && apt-mark hold perl \
  && apt-get install -y --no-upgrade --no-install-recommends sqitch python3-boto3 libtap-parser-sourcehandler-pgtap-perl \
    "postgresql-plpython3-$PG_MAJOR=$PG_VERSION" "postgresql-$PG_MAJOR-cron=1.6.2-1.pgdg120+1" \
    "postgresql-$PG_MAJOR-partman=4.7.2-1" "postgresql-$PG_MAJOR-pgtap=1.2.0-3" \
  && apt-get download libdbd-pg-perl \
  && dpkg --force-all -i libdbd-pg-perl*.deb \
  && rm libdbd-pg-perl*.deb \
  && rm -rf /var/lib/apt/lists/* /var/cache/* \
  && echo "shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'" >> /usr/share/postgresql/postgresql.conf.sample \
  && echo "cron.database_name='${POSTGRES_DB:-postgres}'" >> /usr/share/postgresql/postgresql.conf.sample \
  && cat >> /usr/share/postgresql/postgresql.conf.sample <<EOF
fsync = off
full_page_writes = off
checkpoint_timeout = 1h
max_wal_size = 1GB
shared_buffers = 256MB
work_mem = 50MB
EOF
ENV LANG en_US.utf8
