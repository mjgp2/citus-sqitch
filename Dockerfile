FROM postgres:14.6

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl build-essential ca-certificates \
      "postgresql-plpython3-$PG_MAJOR" "postgresql-$PG_MAJOR-cron" "postgresql-$PG_MAJOR-partman" "postgresql-server-dev-$PG_MAJOR" "postgresql-client-$PG_MAJOR" \
       python3-pip sqitch libdbd-pg-perl \
  && ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.17 | tar -xz -C . ) && \
     cd ./postgresql-hll-2.17 && make && make install \
  && pip3 install 'boto3>=1.17.55' && \
     ( curl -L https://github.com/mjgp2/postgres-aws-s3/tarball/master  | tar -xz -C . ) && \
     cd ./mjgp2-postgres-aws-s3-* && make && make install \
  && echo "shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'" >> /usr/share/postgresql/postgresql.conf.sample \
  && echo "cron.database_name='${POSTGRES_DB:-postgres}'" >> /usr/share/postgresql/postgresql.conf.sample \
  && apt-get purge -y --auto-remove build-essential "postgresql-server-dev-$PG_MAJOR"