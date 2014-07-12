# VersionEye Tasks

This repo contains a couple Rake tasks and shell scripts to manage recurring jobs and workers. The shell scripts trigger Rake tasks. For a better understanding take a look at `tasks/jobs.rake`. 

## Recurring Jobs 

There a couple tasks which have to be repeated every day, every week and every month. 

### Daily Job 

The daily job can be triggered like this. 

```
rake versioneye:daily_jobs
```

Or with the shell script: 

```
$> ./job_daily.sh
```

This will trigger tasks like sending out daily email notifications or updating Indexes at ElasticSearch and so on. 

### Weekly Job 

The weekly job sends out weekly email notifications for projects which choosed weekly monitoring. 

```
rake versioneye:weekly_jobs
```

Or with the shell script: 

```
$> ./job_weekly.sh
```

### Monthly Job

The monthly job sends out monthly email notifications for projects which choosed monthly monitoring. 

```
rake versioneye:monthly_jobs
```

Or with the shell script: 

```
$> ./job_monthly.sh
```

