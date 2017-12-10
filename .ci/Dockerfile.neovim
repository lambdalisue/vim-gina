ARG TAG="latest"
FROM lambdalisue/neovim-themis:${TAG}
MAINTAINER lambdalisue <lambdalisue@hashnote.net>

RUN apk add --no-cache git \
 && git config --global user.name "docker" \
 && git config --global user.email docker@example.com
