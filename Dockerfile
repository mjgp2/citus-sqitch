FROM citusdata/citus
RUN apt-get update && apt-get install -y sqitch libdbd-pg-perl
