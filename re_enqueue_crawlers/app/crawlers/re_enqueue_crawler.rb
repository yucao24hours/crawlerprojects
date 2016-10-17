require "daimon_skycrawlers/crawler"
require "daimon_skycrawlers/crawler/base"
require "daimon_skycrawlers/filter/robots_txt_checker"
require "daimon_skycrawlers/filter/update_checker"
require "pry"
require "pry-nav"

class ReEnqueueCrawler < DaimonSkycrawlers::Crawler::Base
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
      # 各イベント詳細ページの情報を更新する必要がなければとばす
      #update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
      #unless update_checker.call(linked_url.to_s, connection: connection)
      #  skip(linked_url, :no_update)
      #  return
      #end

      # NOTE url には検索クエリを含んだ URL が渡ってくるようにする。
      #      結果一覧のドキュメント構造そのまま GET してくる。構成要素のパースは processor でやる。
      log.info "Getting #{url}"
      response = connection.get(url)

      log.info "Saving with key #{url}"
      data = [url.to_s, response.headers, response.body]
      storage.save(*data)
      schedule_to_process(url.to_s)

      # 次のページがあるときはそちらも取りにいく
      doc = Nokogiri::HTML(response.body)
      if doc.xpath("//p[@class='to_next']").present?
        url = next_page_url(doc)
      else
        log.info "Crawling ended!"
        break
      end
    end
  end

  private

  def next_page_url(doc)
    next_page = doc.xpath("//p[@class='to_next']/a/@href").text
    "https://connpass.com/search/#{next_page}"
  end

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
crawler = ReEnqueueCrawler.new(base_url)

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
