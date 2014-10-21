require 'versioneye-core'
require 'rufus-scheduler'

namespace :versioneye do

  desc "start scheduler"
  task :scheduler do
    VersioneyeCore.new
    env = Settings.instance.environment
    scheduler = Rufus::Scheduler.new


    # -- Hourly Jobs -- #

    scheduler.cron '5 * * * *' do
      UpdateIndexProducer.new("user")
    end

    scheduler.cron '7 * * * *' do
      UpdateIndexProducer.new("product")
    end


    # -- Daily Jobs -- #

    scheduler.cron '1 1 * * *' do
      CommonProducer.new "create_indexes"
    end

    scheduler.cron '10 1 * * *' do
      CommonProducer.new "update_integration_statuses"
    end

    # scheduler.cron '20 1 * * *' do
      # GitHubService.update_all_repos
    # end

    scheduler.cron '15 3 * * *' do
      CommonProducer.new "process_receipts"
    end

    scheduler.cron '25 3 * * *' do
      CommonProducer.new "update_user_languages"
    end

    scheduler.cron '15 4 * * *' do
      CommonProducer.new "update_statistic_data"
    end

    scheduler.cron '25 4 * * *' do
      LanguageDailyStatsProducer.new "start"
    end

    value = GlobalSetting.get(env, 'schedule_follow_notifications')
    value = '15 8 * * *' if value.to_s.empty?
    scheduler.cron value do
      SendNotificationEmailsProducer.new "send"
    end

    value = GlobalSetting.get(env, 'schedule_project_notification_daily')
    value = '15 9 * * *' if value.to_s.empty?
    scheduler.cron value do
      ProjectUpdateProducer.new( Project::A_PERIOD_DAILY )
    end

    scheduler.cron '15 18 * * *' do
      UpdateMetaDataProducer.new "update"
    end

    value = GlobalSetting.get(env, 'sync_db')
    if !value.to_s.empty? && env.eql?('enterprise')
      scheduler.cron value do
        SyncService.sync_all_products
      end
    end

    # -- Weekly Jobs -- #

    value = GlobalSetting.get(env, 'schedule_project_notification_weekly')
    value = '15 11 * * 2' if value.to_s.empty?
    scheduler.cron value do
      ProjectUpdateProducer.new( Project::A_PERIOD_WEEKLY )
    end

    scheduler.cron '15 12 * * 2' do
      CommonProducer.new "send_verification_reminders"
    end

    scheduler.cron '1 12 * * 1' do
      UpdateDependenciesProducer.new "update"
    end


    # -- Monthly Jobs -- #

    value = GlobalSetting.get(env, 'schedule_project_notification_monthly')
    value = '1 11 1 * *' if value.to_s.empty?
    scheduler.cron value do
      ProjectUpdateProducer.new( Project::A_PERIOD_MONTHLY )
    end

    scheduler.join

    while 1 == 1
      p "scheduler rake task is a alive"
      sleep 30
    end
  end


  desc "start java scheduler"
  task :j_scheduler do
    VersioneyeCore.new
    scheduler = Rufus::Scheduler.new

    env = Settings.instance.environment
    value = GlobalSetting.get(env, 'mvn_repo_1_schedule')
    if !value.to_s.empty?
      scheduler.cron value do
        MavenRepository.fill_it
        system("/opt/mvn/bin/mvn -f /mnt/crawl_j/versioneye_maven_crawler/pom.xml crawl:artifactory >> /mnt/logs/crawlj.log")
      end
    end

    scheduler.join
  end


  # ***** Email Tasks *****

  desc "send out new version email notifications"
  task :send_notifications do
    VersioneyeCore.new

    puts "START to send out the notification E-Mails."
    NotificationService.send_notifications
    puts "---"
  end

  desc "send out verification reminders"
  task :send_verification_reminders do
    VersioneyeCore.new

    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "---"
  end

  desc "send out suggestion emails to inactive users"
  task :send_suggestions do
    VersioneyeCore.new

    puts "START to send out suggestion emails to inactive users"
    User.non_followers.each { |user| user.send_suggestions }
    puts "STOP  to send out suggestion emails to inactive users"
  end


  # ***** XML Sitemap Tasks *****

  desc "create XML site map"
  task :xml_sitemap do
    VersioneyeCore.new

    puts "START to export xml site map"
    ProductMigration.xml_site_map
    puts "---"
  end


  # ***** SPDX Import Tasks *****

  desc "import SPDX license list"
  task :spdx_import do
    VersioneyeCore.new

    puts "START to export xml site map"
    LicenseService.import_from "/versioneye-tasks/data/spdx_license.csv"
    puts "---"
  end


  # ***** Admin tasks *****

  desc "init enterprise vm"
  task :init_enterprise do
    VersioneyeCore.new

    puts "START to create default admin"
    AdminService.create_default_admin
    Plan.create_defaults
    EsProduct.reset
    EsUser.reset
    MavenRepository.fill_it
    puts "---"
  end


  # ***** Worker tasks *****

  desc "start GitReposImportWorker"
  task :git_repos_import_worker do
    VersioneyeCore.new
    GitReposImportWorker.new.work()
  end

  desc "start GitRepoImportWorker"
  task :git_repo_import_worker do
    VersioneyeCore.new
    GitRepoImportWorker.new.work()
  end

  desc "start LanguageDailyStatsWorker"
  task :language_daily_stats_worker do
    VersioneyeCore.new
    LanguageDailyStatsWorker.new.work()
  end

  desc "start ProjectUpdateWorker"
  task :project_update_worker do
    VersioneyeCore.new
    ProjectUpdateWorker.new.work()
  end

  desc "start UpdateMetaData"
  task :update_meta_data_worker do
    VersioneyeCore.new
    UpdateMetaDataWorker.new.work()
  end

  desc "start UpdateDependencies"
  task :update_dependencies_worker do
    VersioneyeCore.new
    UpdateDependenciesWorker.new.work()
  end

  desc "start UpdateIndex"
  task :update_index_worker do
    VersioneyeCore.new
    UpdateIndexWorker.new.work()
  end

  desc "start SendNotificationEmailsWorker "
  task :update_send_notification_emails_worker do
    VersioneyeCore.new
    SendNotificationEmailsWorker.new.work()
  end

  desc "start ProcessReceiptsWorker "
  task :process_receipts_worker do
    VersioneyeCore.new
    ProcessReceiptsWorker.new.work()
  end

  desc "start CommonWorker "
  task :common_worker do
    VersioneyeCore.new
    CommonWorker.new.work()
  end


  desc "start SyncWorker "
  task :sync_worker do
    VersioneyeCore.new
    SyncWorker.new.work()
  end


end
