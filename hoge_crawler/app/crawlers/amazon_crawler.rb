require "daimon_skycrawlers/crawler"
require 'daimon_skycrawlers/filter/update_checker'
require "daimon_skycrawlers/crawler/base"
require "dotenv"
require "mechanize"
require "open-uri"

require 'pry'
require "pry-nav"

Dotenv.load

class AmazonCrawler < DaimonSkycrawlers::Crawler::Base
  def fetch(url, **kw)
    update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
    unless update_checker.call(url.to_s, connection: connection)
      log.info("Skip #{url}")
      @skipped = true
      schedule_to_process(url.to_s, heartbeat: true)
      return
    end

    find(:xpath, "//a/span[contains(text(), 'お客様へのおすすめ')]").click


    #schedule_to_process(url.to_s)
  end
end

base_url = "http://example.com"
crawler = AmazonCrawler.new(base_url)

crawler.prepare do |connection|

  # ログイン
  end
end

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
