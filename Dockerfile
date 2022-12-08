# Base for builder
FROM debian:unstable-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y make git curl cmake clang pkg-config ca-certificates xz-utils gnupg wget gdc dub \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY . .
RUN mkdir build/
WORKDIR /opt/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -Dbuild_sideloadipa=OFF -Dlink_libplist_dynamic=ON \
 && make anisette_server

# Base for run
FROM debian:unstable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates libplist3 curl unzip libgphobos3 libphobos2-ldc-shared100 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy build artefacts to run
WORKDIR /opt/
COPY docker-entrypoint.sh .
COPY --from=builder /opt/build/anisette_server .

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Chester \
 && mkdir /opt/lib \
 && chown -R Chester /opt/ \
 && chmod -R +wx /opt/

# Run the artefact
USER Chester
ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]
