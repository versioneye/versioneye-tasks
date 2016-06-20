FROM        versioneye/ruby-base:2.3.0-1
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ENV RAILS_ENV enterprise

ADD . /app

RUN apt-get update && apt-get install -y supervisor; \
    cp /app/supervisord.conf /etc/supervisord.conf; \
    mkdir -p /cocoapods; \
    cd /app/ && bundle install;

CMD /usr/bin/supervisord -c /etc/supervisord.conf
