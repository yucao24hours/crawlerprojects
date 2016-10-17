require "nokogiri"
require "daimon_skycrawlers/crawler"
require "daimon_skycrawlers/crawler/base"
require "daimon_skycrawlers/filter/robots_txt_checker"
require "daimon_skycrawlers/filter/update_checker"
require "pry"
require "pry-nav"

class ConnpassCrawler < DaimonSkycrawlers::Crawler::Base
  def fetch(url, **kw)
    @n_processed_urls += 1
    @skipped = false

    # robots.txt によって拒否されていたらとばす
    robots_txt_checker = DaimonSkycrawlers::Filter::RobotsTxtChecker.new(base_url: @base_url)
    unless robots_txt_checker.call(url)
      skip(url, :denied)
      return
    end

    loop do
      # NOTE url には検索クエリを含んだ URL が渡ってくるようにする。
      #      検索結果にヒットしたイベント一覧を表示し、各イベントの詳細 URL に GET をして
      #      ページデータを保存する。
      response = connection.get(url)

      doc = Nokogiri::HTML(response.body)
      urls = doc.xpath("//p[@class='event_title']/a/@href").map(&:text)

      urls.each do |linked_url|
        # 各イベント詳細ページの情報を更新する必要がなければとばす
        update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
        unless update_checker.call(linked_url.to_s, connection: connection)
          skip(linked_url, :no_update)
          return
        end

        log.info "Getting #{linked_url}"
        res = connection.get(linked_url)

        log.info "Saving with key #{linked_url}"
        data = [linked_url.to_s, res.headers, res.body]
        storage.save(*data)
        schedule_to_process(linked_url.to_s)
      end

      # 次のページがあるときはそちらも取りにいく
      if doc.xpath("//p[@class='to_next']").present?
        log.info "===Go to the next page"
        next_page = doc.xpath("//p[@class='to_next']/a/@href").text
        url = "https://connpass.com/search/#{next_page}"
      else
        log.info "Crawling ended!"
        break
      end
    end
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
crawler = ConnpassCrawler.new(base_url)

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
