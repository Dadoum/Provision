# Base for builder
FROM debian:unstable-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y git ldc dub clang \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY lib/ lib/
COPY anisette_server/ anisette_server/
COPY dub.sdl dub.selections.json docker-entrypoint.sh .
RUN DFLAGS=--static dub build --build-mode allAtOnce -b release --compiler=ldc2 provision:anisette-server

# Base for run
FROM debian:unstable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates curl unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy build artefacts to run
WORKDIR /opt/
COPY docker-entrypoint.sh .
COPY --from=builder /opt/bin/provision_anisette-server ./anisette_server

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Chester \
 && mkdir /opt/lib \
 && chown -R Chester /opt/ \
 && chmod -R +wx /opt/

# Run the artefact
USER Chester
ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]
