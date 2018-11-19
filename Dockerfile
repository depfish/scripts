FROM registryaws.mxj360.com/base/ubuntu:18.04
WORKDIR /app
USER root
RUN apt install -y nodejs npm \
    && mkdir -p /app \
    && cd /app \
    && npm config set registry https://registry.npm.taobao.org \
    && npm config get registry \
    && npm i docsify-cli -g \
    && docsify init ./docs
CMD ["/usr/local/bin/docsify serve docs"]


ln -s /usr/local/lib/node_modules/docsify-cli/bin/docsify /sbin/docsify \

