FROM citusdata/citus:pg12
RUN apt-get update && apt-get install -y sqitch libdbd-pg-perl
