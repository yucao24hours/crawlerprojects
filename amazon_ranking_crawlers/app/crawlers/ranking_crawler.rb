require "daimon_skycrawlers/crawler"
require "daimon_skycrawlers/crawler/base"
require "daimon_skycrawlers/filter/robots_txt_checker"
require "daimon_skycrawlers/filter/update_checker"
require "pry"
require "pry-nav"

class MyCrawler < DaimonSkycrawlers::Crawler::Base
  def fetch(url, **kw)
    @n_processed_urls += 1
    @skipped = false

    # robots.txt によって拒否されていたらとばす
    robots_txt_checker = DaimonSkycrawlers::Filter::RobotsTxtChecker.new(base_url: @base_url)
    unless robots_txt_checker.call(url)
      skip(url, :denied)
      return
    end

    # 取得してきたページの情報を更新する必要がなければとばす
    update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
    unless update_checker.call(url.to_s, connection: connection)
      skip(url, :no_update)
      return
    end

    response = connection.get(url)

    data = [url.to_s, response.headers, response.body]
    storage.save(*data)

    schedule_to_process(url.to_s)
  end

  private

  def skip(url, reason)
    str = case reason
    when :denied
      "because of robots.txt"
    when :no_update
      "because the page has not been updated"
    end

    log.info("Skip #{url} #{str}")

    @skipped = true
    schedule_to_process(url.to_s, heartbeat: true)
  end
end

base_url = "http://example.com"
crawler = MyCrawler.new(base_url)

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
