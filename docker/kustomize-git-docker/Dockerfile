FROM alpine:latest AS downloader
RUN apk update
RUN apk add curl

RUN set -ex; \
    curl -fL  https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.5.7/kustomize_v4.5.7_linux_amd64.tar.gz | tar xz && \
    chmod +x kustomize

FROM alpine:latest AS runtime

COPY --from=downloader kustomize /usr/local/bin/kustomize
RUN apk --no-cache add git
RUN apk add openssh
