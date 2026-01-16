ARG CONTAINER_NAME
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}

ENV SERVICE_NAME=rsyslogd \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail rsyslogd" \
      description="Contrail rsyslogd support" \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

RUN set -e ; \
    /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done' ; \
    dnf -y install rsyslog ; \
    dnf clean all -y ; \
    rm -rf /var/cache/yum

# Copy configuration files
COPY rsyslog.conf /etc/
COPY rsyslog.d/*.conf /etc/rsyslog.d/

ENV RSYSLOGD_PIDFILE=/var/run/rsyslogd.pid
ENTRYPOINT ["/contrail-entrypoint.sh"]
CMD rsyslogd -n -f /etc/rsyslog.conf -i $RSYSLOGD_PIDFILE
