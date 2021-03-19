ARG NAME=http-echo
ARG HOMEDIR=/opt/${NAME}

#
# Builder
#

FROM golang:1.15.8 AS build-env
ARG SOURCE=*
ARG HOMEDIR
ARG NAME

ADD $SOURCE /src/

WORKDIR /src/

RUN make static

WORKDIR ${HOMEDIR}

RUN cp /src/bin/${NAME} .

RUN echo "${NAME}:x:1000:${NAME}" >> /etc/group && \
    echo "${NAME}:x:1000:1000:${NAME} user:${HOMEDIR}:/sbin/nologin" >> /etc/passwd && \
    chown -R ${NAME}:${NAME} ${HOMEDIR} && \
    chmod -R g+rw ${HOMEDIR} && \
    chmod +x ${NAME}

#
# Actual image
#

FROM scratch
ARG HOMEDIR

LABEL Name=${NAME} \
      Release=https://github.com/vgryzunov/${NAME} \
      Url=https://github.com/vgryzunov/${NAME} \
      Help=https://github.com/vgryzunov/${NAME}/issues

COPY --from=build-env ${HOMEDIR} ${HOMEDIR}
COPY --from=build-env /etc/passwd /etc/passwd
COPY --from=build-env /etc/group /etc/group
COPY --from=build-env /usr/share/ca-certificates /usr/share/ca-certificates
COPY --from=build-env /etc/ssl/certs /etc/ssl/certs

WORKDIR ${HOMEDIR}
USER 1000
ENTRYPOINT ["/opt/http-echo/http-echo", "8080"]