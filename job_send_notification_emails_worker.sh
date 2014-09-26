#!/bin/bash

/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:update_send_notification_emails_worker'
