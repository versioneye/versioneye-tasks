#!/bin/bash

/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:github_repo_import_worker &'
/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:github_repo_import_worker &'
/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:github_repo_import_worker &'
/bin/bash -l -c 'cd /versioneye-tasks; /usr/local/bin/bundle exec rake versioneye:github_repo_import_worker'
