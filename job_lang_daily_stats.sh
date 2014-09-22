#!/bin/bash

/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:language_daily_stats_worker'
