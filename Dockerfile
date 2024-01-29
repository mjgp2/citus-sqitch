FROM postgres:15.3

# docker buildx build --push --platform linux/amd64 -t mjgp2/pg-sqitch:15.3 .
# docker buildx build --push --platform linux/arm64 -t mjgp2/pg-sqitch:15.3 .

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl build-essential ca-certificates \
      libtap-parser-sourcehandler-pgtap-perl "postgresql-plpython3-$PG_MAJOR" "postgresql-$PG_MAJOR-cron" \
      "postgresql-$PG_MAJOR-partman" "postgresql-$PG_MAJOR-pgtap" "postgresql-server-dev-$PG_MAJOR" "postgresql-client-$PG_MAJOR" \
      python3-boto3 sqitch libdbd-pg-perl \
  && ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.17 | tar -xz -C . ) \
  && cd ./postgresql-hll-2.17 && make && make install \
  && ( curl -L https://github.com/chimpler/postgres-aws-s3/tarball/master  | tar -xz -C . ) \
  && cd ./chimpler-postgres-aws-s3-* && make && make install \
  && echo "shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'" >> /usr/share/postgresql/postgresql.conf.sample \
  && echo "cron.database_name='${POSTGRES_DB:-postgres}'" >> /usr/share/postgresql/postgresql.conf.sample \
  && apt-get purge -y --auto-remove build-essential "postgresql-server-dev-$PG_MAJOR"