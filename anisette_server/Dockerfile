FROM ubuntu:latest AS builder
RUN apt-get update && apt-get install -y pkg-config clang cmake git dub curl
RUN curl -fsS https://dlang.org/install.sh | bash -s ldc-1.30.0
WORKDIR /opt/
# COPY . .
RUN git clone https://github.com/Dadoum/Provision --recursive
WORKDIR /opt/Provision
RUN mkdir build
WORKDIR /opt/Provision/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -Dbuild_sideloadipa=OFF -Dlink_libplist_dynamic=ON -DCMAKE_D_COMPILER=/root/dlang/ldc-1.30.0/bin/ldc2
RUN make anisette_server

FROM ubuntu:latest
RUN apt-get update && apt-get install -y libplist3 curl unzip wget
WORKDIR /opt/
COPY docker-entrypoint.sh .
COPY --from=builder /opt/Provision/build/anisette_server .
RUN curl -s https://api.github.com/repos/Dadoum/Provision/releases/latest \
 | grep "browser_download_url.*anisette_server-$(uname -m)" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi -
RUN mv anisette_server-$(uname -m) anisette_server \
 && chmod +x anisette_server
ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]