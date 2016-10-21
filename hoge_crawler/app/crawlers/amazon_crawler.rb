require "daimon_skycrawlers/crawler"
require 'daimon_skycrawlers/filter/update_checker'
require "daimon_skycrawlers/crawler/base"
require "open-uri"
require "capybara"
require "capybara/dsl"
require "launchy"
require "dotenv"

require 'pry'
require "pry-nav"

Dotenv.load

class AmazonCrawler < DaimonSkycrawlers::Crawler::Base
  include Capybara::DSL

  def fetch(url, **kw)
    update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
    unless update_checker.call(url.to_s, connection: connection)
      log.info("Skip #{url}")
      @skipped = true
      schedule_to_process(url.to_s, heartbeat: true)
      return
    end

    find(:xpath, "//a/span[contains(text(), 'お客様へのおすすめ')]").click


    puts "This is the end of fetch method"
    #schedule_to_process(url.to_s)
  end
end

base_url = "http://example.com"
crawler = AmazonCrawler.new(base_url)

crawler.prepare do |connection|
  include Capybara::DSL

  # ログイン
  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end
  Capybara.current_driver = :selenium
  Capybara.app_host = "https://amazon.co.jp"
  Capybara.default_max_wait_time = 30

  visit "/"

  click_link "新規登録はこちら"

  binding.pry

  click_link "サインイン"

  fill_in "ap_email", with: ENV["AMAZON_EMAIL"]
  fill_in "ap_password", with: ENV["AMAZON_PASSWORD"]

  click_on "signInSubmit"
end

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
