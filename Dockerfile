FROM debian:unstable-slim AS builder
RUN apt-get update && apt-get install --no-install-recommends -y make git curl cmake clang pkg-config ca-certificates xz-utils gnupg wget gdc dub \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/
COPY . .
RUN mkdir build/
WORKDIR /opt/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -Dbuild_sideloadipa=OFF -Dlink_libplist_dynamic=ON \
 && make anisette_server

FROM debian:unstable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates libplist3 curl unzip libphobos2-ldc-shared100 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/
COPY docker-entrypoint.sh .
COPY --from=builder /opt/build/anisette_server .

RUN useradd -ms /bin/bash Chester \
 && chown Chester ~/*
 && chmod +x ~/*

USER Chester
ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]
