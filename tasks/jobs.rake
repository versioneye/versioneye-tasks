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

    scheduler.every('120m') do
      CommonProducer.new "update_authors"
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

  desc "start GitPrWorker"
  task :git_pr_worker do
    VersioneyeCore.new
    GitPrWorker.new.work()
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

  desc "save hooks for old Github hooks"
  task :save_project_hooks do
    VersioneyeCore.new

    gh_projects = Project.where(
      source: Project::A_SOURCE_GITHUB
    )

    p "save_project_hooks: going to save hook data"

    gh_projects.to_a.each do |project|
      if Webhook.where(scm: Webhook::A_TYPE_GITHUB, project_id: project.ids).exists?
        p "save_project_hooks: ignoring #{project.ids}"
        next
      end

      owner =  Helpers::get_github_owner(project)
      if owner.nil?
        p "save_project_hooks: no owner with Github access for project.#{project}"
        next
      end

      hooks = GithubWebhook.fetch_repo_hooks(project[:scm_fullname], owner.github_token).to_a
      veye_hook = Helpers::only_versioneye_hook(hooks)
      if only_veye_hook.nil?
        p "registering a new hook for project.#{project.ids} => #{project[:scm_fullname]}"
        api_key = owner
        GithubWebhook.create_project_hook(
          project[:scm_fullname],
          project_id,
          owner.api.api_key,
          owner.github_token
        )
      else
        p  "saving existing hook data into our database"
        GithubWebhook.upsert_project_webhook(veye_hook, project[:scm_fullname], project.ids)
      end

    end
  end

  class Helpers
    def self.only_versioneye_hook(hooks)
      hooks.to_a.keep_if do |hook|
        /versioneye\.com/.match? hook[:config][:url]
      end.first
    end

    # returns first user or team member who has github token
    def self.get_github_owner(project)
      user = User.where(id: project.user_id).first
      return user if user.github_token and project.is_collaborator?(user)

      owner = nil
      project.teams.to_a.each do |team|
        team.members.to_a.each do |tm|
          owner = tm.user if tm.user.github_token.to_s.size > 0
          break if owner
        end

        break if owner
      end

      owner
    end
  end

end
