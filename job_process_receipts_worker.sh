#!/bin/bash

/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:process_receipts_worker --silent'
