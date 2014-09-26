require 'versioneye-core'
require 'rufus-scheduler'

namespace :versioneye do

  desc "start scheduler"
  task :scheduler do
    VersioneyeCore.new
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
      Indexer.create_indexes
    end

    scheduler.cron '10 1 * * *' do
      SubmittedUrlService.update_integration_statuses()
    end

    # scheduler.cron '20 1 * * *' do
      # GitHubService.update_all_repos
    # end

    scheduler.cron '15 3 * * *' do
      ProcessReceiptsProducer.new "receipts"
    end

    scheduler.cron '25 3 * * *' do
      UserService.update_languages
    end

    scheduler.cron '15 4 * * *' do
      StatisticService.update_all
    end

    scheduler.cron '25 4 * * *' do
      LanguageDailyStatsProducer.new "start"
    end

    scheduler.cron '15 8 * * *' do
      SendNotificationEmailsProducer.new "send"
    end

    scheduler.cron '15 9 * * *' do
      ProjectUpdateProducer.new( Project::A_PERIOD_DAILY )
    end

    scheduler.cron '15 18 * * *' do
      UpdateMetaDataProducer.new "update"
    end


    # -- Weekly Jobs -- #

    scheduler.cron '15 11 * * 2' do
      ProjectUpdateProducer.new( Project::A_PERIOD_WEEKLY )
    end

    scheduler.cron '15 12 * * 2' do
      User.send_verification_reminders
    end

    scheduler.cron '1 12 * * 1' do
      UpdateDependenciesProducer.new "update"
    end


    # -- Monthly Jobs -- #

    scheduler.cron '1 11 1 * *' do
      ProjectUpdateProducer.new( Project::A_PERIOD_MONTHLY )
    end

    scheduler.join
  end



  desc "execute the daily jobs"
  task :daily_jobs do

    VersioneyeCore.new

    puts "START to update Indexes. Ensure that all indexes are existing."
    begin
      Indexer.create_indexes
    rescue => e
      p e.message
      p e.backtrace.join("\n")
    end
    puts "---"

    puts "START to update integration status of submitted urls"
    SubmittedUrlService.update_integration_statuses()
    puts "---"

    puts "START reindex newest products for elastic search"
    EsProduct.index_newest
    puts "---"

    puts "START reindex users for elastic search"
    EsUser.reindex_all
    puts "---"

    puts "START to update all github repos"
    GitHubService.update_all_repos
    puts "---"

    puts "START to send out the notification E-Mails."
    NotificationService.send_notifications
    puts "---"

    puts "START to send out receipts "
    ReceiptService.process_receipts
    puts "---"

    puts "START to update all user languages"
    UserService.update_languages
    puts "---"

    puts "START to update the json strings for the statistic page."
    StatisticService.update_all
    puts "---"

    puts "START to LanguageDailyStats.update_counts"
    LanguageDailyStatsProducer.new "start"
    puts "---"

    puts "START to send out daily project notification E-Mails."
    ProjectUpdateService.update_all( Project::A_PERIOD_DAILY )
    puts "---"

    puts "START update meta data on products. Update followers, version and used_by_count"
    ProductService.update_meta_data_global
    puts "---"

    Mongoid.default_session.disconnect
  end

  desc "excute weekly jobs"
  task :weekly_jobs do
    VersioneyeCore.new

    puts "START to send out weekly project notification E-Mails."
    ProjectUpdateService.update_all( Project::A_PERIOD_WEEKLY )
    puts "---"

    puts "START to send out verification reminder E-Mails."
    User.send_verification_reminders
    puts "---"

    puts "START to update dependencies."
    ProductService.update_dependencies_global
    puts "---"

    Mongoid.default_session.disconnect
  end

  desc "excute monthly jobs"
  task :monthly_jobs do
    VersioneyeCore.new

    puts "START to send out monthly project notification emails."
    ProjectUpdateService.update_all( Project::A_PERIOD_MONTHLY )
    puts "---"

    Mongoid.default_session.disconnect
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
    puts "---"
  end


  # ***** Worker tasks *****

  desc "start GithubReposImportWorker"
  task :github_repos_import_worker do
    VersioneyeCore.new
    GithubReposImportWorker.new.work()
  end

  desc "start GithubRepoImportWorker"
  task :github_repo_import_worker do
    VersioneyeCore.new
    GithubRepoImportWorker.new.work()
  end

  desc "start BitbucketReposImportWorker"
  task :bitbucket_repos_import_worker do
    VersioneyeCore.new
    BitbucketReposImportWorker.new.work()
  end

  desc "start BitbucketRepoImportWorker"
  task :bitbucket_repo_import_worker do
    VersioneyeCore.new
    BitbucketRepoImportWorker.new.work()
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


end
