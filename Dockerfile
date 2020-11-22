FROM alpine:edge AS builder

# show backtraces
ENV RUST_BACKTRACE 1

RUN apk add --no-cache \
  build-base \
  cargo \
  cmake \
  eudev-dev \
  linux-headers \
  perl \
  rust \
  git

WORKDIR /openethereum
COPY . /openethereum
RUN cargo build --release --features final --target $(uname -m)-alpine-linux-musl --verbose
RUN strip target/$(uname -m)-alpine-linux-musl/release/openethereum
RUN mv target/$(uname -m)-alpine-linux-musl/release/openethereum target/openethereum

FROM alpine:edge

# show backtraces
ENV RUST_BACKTRACE 1

# curl and jq are installed to help create health and readiness checks on Kubernetes
RUN apk add --no-cache \
  libstdc++ \
  eudev-libs \
  libgcc \
  curl \
  jq

RUN addgroup -g 1000 openethereum \
  && adduser -u 1000 -G openethereum -s /bin/sh -D openethereum

USER openethereum

EXPOSE 8080 8545 8180

WORKDIR /home/openethereum

RUN mkdir -p /home/openethereum/.local/share/io.parity.ethereum/
COPY --chown=openethereum:openethereum --from=builder /openethereum/target/openethereum ./

ENTRYPOINT ["/home/openethereum/openethereum"]
