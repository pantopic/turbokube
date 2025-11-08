FROM debian:stable-slim as turbokube

COPY _dist/turbokube .

CMD ["./turbokube"]
