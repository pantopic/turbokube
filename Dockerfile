FROM debian:stable-slim as turbokube

COPY bin/turbokube .

CMD ["./turbokube"]
