FROM ubuntu:latest

RUN apt-get update && apt-get install -y libplist3 curl unzip wget

WORKDIR /opt/

COPY docker-entrypoint.sh .

RUN curl -s https://api.github.com/repos/Dadoum/Provision/releases/latest \
 | grep "browser_download_url.*anisette_server-$(uname -m)" \
 | cut -d : -f 2,3 \
 | tr -d \" \
 | wget -qi -
RUN chmod +x anisette_server-$(uname -m) \
 && mv anisette_server-$(uname -m) anisette_server

ENTRYPOINT [ "/opt/docker-entrypoint.sh" ]