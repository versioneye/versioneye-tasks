FROM        versioneye/ruby-base:2.4.3
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ENV RAILS_ENV enterprise

ADD . /app

RUN cp /app/supervisord.conf /etc/supervisord.conf; \
    mkdir -p /cocoapods; \
    cd /app/ && bundle install;

CMD /usr/bin/supervisord -c /etc/supervisord.conf
