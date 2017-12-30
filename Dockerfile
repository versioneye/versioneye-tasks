FROM        versioneye/ruby-base:2.3.3-10
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ENV RAILS_ENV enterprise

ADD . /app

RUN cp /app/supervisord.conf /etc/supervisord.conf; \
    mkdir -p /cocoapods; \
    cd /app/ && bundle install;

CMD /app/start.sh
