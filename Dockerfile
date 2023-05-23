# Base for builder
FROM debian:unstable-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates ldc git clang dub libz-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY lib/ lib/
COPY anisette_server/ anisette_server/
COPY dub.sdl dub.selections.json ./
RUN dub build -c "static" --build-mode allAtOnce -b release --compiler=ldc2 :anisette-server

# Base for run
FROM debian:unstable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy build artefacts to run
WORKDIR /opt/
COPY --from=builder /opt/bin/provision_anisette-server /opt/anisette_server

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Chester \
 && mkdir /home/Chester/.config/Provision/lib/ -p \
 && chown -R Chester /home/Chester/ \
 && chmod -R +wx /home/Chester/ \
 && chown -R Chester /opt/ \
 && chmod -R +wx /opt/

# Run the artefact
USER Chester
EXPOSE 6969
ENTRYPOINT [ "/opt/anisette_server", "-r=true" ]
