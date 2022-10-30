FROM ubuntu:latest AS builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install --no-install-recommends -y make xz-utils ca-certificates pkg-config clang cmake dub curl git  \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsS https://dlang.org/install.sh | bash -s ldc-1.30.0
WORKDIR /opt/
# Clone must be --recursive and docker build at root of project
COPY . .
RUN mkdir build/
WORKDIR /opt/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -Dbuild_sideloadipa=OFF -Dlink_libplist_dynamic=ON -DCMAKE_D_COMPILER=/root/dlang/ldc-1.30.0/bin/ldc2 \
 && make anisette_server

FROM ubuntu:latest
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates libplist3 curl unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/
COPY docker-entrypoint.sh .
COPY --from=builder /opt/build/anisette_server .
ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]
