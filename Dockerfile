FROM postgres:16.4 AS base

FROM base AS builder

# docker buildx build --push --platform linux/amd64,linux/arm64 -t mjgp2/pg-sqitch:16.4 .

RUN apt-get update \
  && apt-get install -y --no-upgrade --no-install-recommends curl build-essential ca-certificates "postgresql-server-dev-$PG_MAJOR=$PG_VERSION" \
  && ( curl https://codeload.github.com/citusdata/postgresql-hll/tar.gz/refs/tags/v2.18 | tar -xz -C . ) \
  && cd ./postgresql-hll-2.18 && make && make install && cd .. && rm -rf ./postgresql-hll-2.18 \
  && ( curl -L https://github.com/chimpler/postgres-aws-s3/tarball/master  | tar -xz -C . ) \
  && cd ./chimpler-postgres-aws-s3-* && make && make install && cd .. && rm -rf ./chimpler-postgres-aws-s3-* \
  && apt-get purge -y --auto-remove curl build-essential ca-certificates "postgresql-server-dev-$PG_MAJOR" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ /var/cache/apt/archives/ /var/cache/

FROM base
COPY --from=builder /usr/share/postgresql/16/extension /usr/share/postgresql/16/extension
COPY --from=builder /usr/lib/postgresql/16/lib/ /usr/lib/postgresql/16/lib/
RUN apt-get update \
  && apt-mark hold perl \
  && apt-get install -y --no-upgrade --no-install-recommends sqitch python3-boto3 libtap-parser-sourcehandler-pgtap-perl \
    "postgresql-plpython3-$PG_MAJOR=$PG_VERSION" "postgresql-$PG_MAJOR-cron=1.6.4-1.pgdg120+1" \
    "postgresql-$PG_MAJOR-partman=5.1.0-1.pgdg120+1" "postgresql-$PG_MAJOR-pgtap" \
  && apt-get download libdbd-pg-perl \
  && dpkg --force-all -i libdbd-pg-perl*.deb \
  && rm libdbd-pg-perl*.deb \
  && rm -rf /var/lib/apt/lists/* /var/cache/* \
  && echo "shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'" >> /usr/share/postgresql/postgresql.conf.sample \
  && echo "cron.database_name='${POSTGRES_DB:-postgres}'" >> /usr/share/postgresql/postgresql.conf.sample
RUN cat >> /usr/share/postgresql/postgresql.conf.sample <<EOF
# Performance Optimizations for Unit Testing
fsync = off                             # Disable fsync to improve performance (acceptable for unit testing)
full_page_writes = off                  # Disable full page writes to reduce I/O (acceptable if recovery is not needed)
checkpoint_timeout = 30min              # Set a moderate checkpoint interval to balance performance and disk usage
max_wal_size = 1GB                      # Allow a reasonable amount of WAL data to accumulate
shared_buffers = 128MB                  # Allocate a moderate amount of memory for shared buffers
work_mem = 16MB                         # Allocate memory for query operations like sorting and hashing

# Logging Settings
log_min_duration_statement = 100ms      # Log all queries for detailed test analysis
log_statement = 'all'                   # Log all SQL statements to verify that all expected statements are executed

# Extensions and Preloaded Libraries
shared_preload_libraries = 'hll,pg_cron,pg_stat_statements'  # Load necessary extensions
cron.database_name = '${POSTGRES_DB:-postgres}'  # Set the default database for pg_cron jobs

# Connection and Resource Management
synchronous_commit = on                 # Ensure synchronous commits to test data consistency and integrity
EOF
ENV LANG en_US.utf8
