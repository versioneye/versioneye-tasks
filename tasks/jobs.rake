require 'versioneye-core'
require 'rufus-scheduler'

namespace :versioneye do

  desc "start scheduler"
  task :scheduler do
    VersioneyeCore.new
    env = Settings.instance.environment
    scheduler = Rufus::Scheduler.new


    # Every 5 minutes
    scheduler.every('5m') do
      UpdateIndexProducer.new("user")
    end

    # Every 10 minutes
    scheduler.every('10m') do
      UpdateIndexProducer.new("product")
    end

    # Every 5 minutes
    scheduler.every('5m') do
      CommonProducer.new "remove_temp_projects"
    end


    # -- Daily Jobs -- #

    scheduler.cron '1 1 * * *' do
      CommonProducer.new "create_indexes"
    end

    if env.eql?('enterprise')
      scheduler.cron '5 1 * * *' do
        CommonProducer.new "update_smc_meta_data_all"
      end
    end

    scheduler.cron '10 1 * * *' do
      CommonProducer.new "update_integration_statuses"
    end

    scheduler.cron '10 2 * * *' do
      CommonProducer.new "update_authors"
    end

    if env.eql?('production')
      scheduler.cron '15 3 * * *' do
        CommonProducer.new "process_receipts"
      end
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

    scheduler.every('24h') do
      TeamNotificationService.start( false )
    end

    scheduler.cron '15 18 * * *' do
      UpdateMetaDataProducer.new "update"
    end

    value = GlobalSetting.get(env, 'sync_db')
    if !value.to_s.empty? && env.eql?('enterprise')
      scheduler.cron value do
        SyncProducer.new "all_products"
      end
    end

    scheduler.cron '21 12 * * 2' do
      CommonProducer.new "update_distinct_languages"
    end

    scheduler.join

    while 1 == 1
      p "scheduler rake task is a alive"
      sleep 30
    end
  end


  desc "start java scheduler"
  task :j_scheduler_enterprise do
    VersioneyeCore.new
    scheduler = Rufus::Scheduler.new

    env = Settings.instance.environment
    value = GlobalSetting.get(env, 'mvn_repo_1_schedule')
    if !value.to_s.empty?
      scheduler.cron value do
        MavenRepository.fill_it
        crawler = GlobalSetting.get(env, 'mvn_repo_1_type')
        system("/usr/bin/printenv >> /mnt/logs/crawlj.log")
        if crawler.to_s.eql?('artifactory')
          system("/opt/mvn/bin/mvn -f /mnt/crawl_j/versioneye_maven_crawler/pom.xml crawl:artifactory >> /mnt/logs/crawlj.log")
        elsif crawler.to_s.eql?('maven_index')
          system("M2=/opt/apache-maven-3.0.5/bin && M2_HOME=/opt/apache-maven-3.0.5 && /opt/apache-maven-3.0.5/bin/mvn -f /mnt/maven-indexer/pom.xml crawl:repo1index >> /mnt/logs/crawlj.log")
        elsif crawler.to_s.eql?('html')
          system("/opt/mvn/bin/mvn -f /mnt/crawl_j/versioneye_maven_crawler/pom.xml crawl:repo1html >> /mnt/logs/crawlj.log")
        end
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

    puts "START to export spdx licenses"
    LicenseService.import_from "/app/data/spdx_license.csv"
    puts "---"
  end


  # ***** Seeburger Import Tasks *****

  desc "import Seeburger license list"
  task :seeburger_import do
    VersioneyeCore.new

    puts "START to seeburger license.properties"
    LicenseService.import_from_properties_file "data/license.properties"
    puts "---"
  end

  desc "import Seeburger license list"
  task :seeburger_import_websites do
    VersioneyeCore.new

    puts "START to seeburger license.properties"
    LicenseService.import_websites_from_properties_file "data/website.properties"
    puts "---"
  end


  # ***** Admin tasks *****

  desc "init enterprise vm"
  task :init_enterprise do
    VersioneyeCore.new

    puts "START to create default admin"
    AdminService.create_default_admin

    puts "START to create default plans"
    Plan.create_defaults

    puts "START to create ES Product index"
    EsProduct.reset

    puts "START to fill MavenRepository"
    MavenRepository.fill_it

    puts "START to import spdx licenses"
    LicenseService.import_from "/app/data/spdx_license.csv"
    puts "---"
  end


  # ***** NewestPostProcessor *****

  desc "start Newest Post Processor"
  task :newest_post_processor_worker do
    VersioneyeCore.new
    NewestService.run_worker()
  end


  # ***** Git Worker tasks *****

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

  desc "start GitRepoFileImportWorker"
  task :git_repo_file_import_worker do
    VersioneyeCore.new
    GitRepoFileImportWorker.new.work()
  end


  # ***** Common Worker tasks *****

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

  desc "start TeamNotificationWorker"
  task :team_notification_worker do
    VersioneyeCore.new
    TeamNotificationWorker.new.work()
  end

  desc "start UpdateMetaData"
  task :update_meta_data_worker do
    VersioneyeCore.new
    UpdateMetaDataWorker.new.work()
  end

  desc "start UpdateIndex"
  task :update_index_worker do
    VersioneyeCore.new
    UpdateIndexWorker.new.work()
  end

  desc "start SendNotificationEmailsWorker "
  task :send_notification_emails_worker do
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

  desc "start DepdencyBadgeWorker "
  task :dependency_badge_worker do
    VersioneyeCore.new
    DependencyBadgeWorker.new.work()
  end


  desc "start SyncWorker "
  task :sync_worker do
    VersioneyeCore.new
    SyncWorker.new.work()
  end


end
