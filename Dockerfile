FROM postgres:15.3

# docker buildx build --push --platform linux/amd64,linux/arm64 -t mjgp2/pg-sqitch:15.3 .

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl build-essential ca-certificates \
      libtap-parser-sourcehandler-pgtap-perl "postgresql-plpython3-$PG_MAJOR" "postgresql-$PG_MAJOR-cron=1.6.2-1.pgdg120+1" \
      "postgresql-$PG_MAJOR-partman=4.7.2-1" "postgresql-$PG_MAJOR-pgtap=1.2.0-3" "postgresql-server-dev-$PG_MAJOR" "postgresql-client-$PG_MAJOR" \
      python3-boto3 sqitch libdbd-pg-perl \
  && ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.17 | tar -xz -C . ) \
  && cd ./postgresql-hll-2.17 && make && make install \
  && ( curl -L https://github.com/chimpler/postgres-aws-s3/tarball/master  | tar -xz -C . ) \
  && cd ./chimpler-postgres-aws-s3-* && make && make install \
  && echo "shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'" >> /usr/share/postgresql/postgresql.conf.sample \
  && echo "cron.database_name='${POSTGRES_DB:-postgres}'" >> /usr/share/postgresql/postgresql.conf.sample \
  && apt-get purge -y --auto-remove build-essential "postgresql-server-dev-$PG_MAJOR"\
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
  && echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
  && locale-gen
RUN cat >> /usr/share/postgresql/postgresql.conf.sample <<EOF
fsync = off
full_page_writes = off
checkpoint_timeout = 1h
max_wal_size = 1GB
shared_buffers = 256MB
work_mem = 50MB
EOF
ENV LANG en_US.utf8