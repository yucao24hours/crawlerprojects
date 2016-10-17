require "daimon_skycrawlers/crawler"
require "daimon_skycrawlers/crawler/base"
require "daimon_skycrawlers/filter/robots_txt_checker"
require "daimon_skycrawlers/filter/update_checker"
require "pry"
require "pry-nav"

# XXX 今は filters っていうディレクトリはデフォルトでは存在しないので自分で作って、
#     そこに置いた。そのためフレームワーク側で自動的にロードするということもしていないので
#     require_relative してる。
require_relative "../filters/index_page_filter"

class IndexPageCrawler < DaimonSkycrawlers::Crawler::Base
  def fetch(url, **kw)
    # XXX この if 文中の処理は crawler 層に入ってくる前に動いててほしい
    if !index_page?(url)
      log.info "#{url} will not be crawled by IndexPageCrawler"
      return
    end

    @n_processed_urls += 1
    @skipped = false

    if blocked?(url)
      skip(url, :denied)
      return
    end

    loop do
      if need_update?(url)
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
      else
        # 更新の必要がなければ飛ばす
        skip(url, :no_update)
        return
      end
    end
  end

  private

  # NOTE IndexPageFilter#call は、引数で渡された URL（エンキューされてきたもの）が
  #      一覧ページのものであるときに true を返してくる。
  def index_page?(url)
    filter = IndexPageFilter.new
    filter.call(url)
  end

  # NOTE UpdateChecker#call は、ストレージ内のデータを更新する必要があるときに
  #      false を返してくる。
  def need_update?(url)
    checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
    !checker.call(url.to_s, connection: connection)
  end

  # NOTE RobotsTxtChecker#call は、許可されていたら true を、ブロックされていたら false を返してくる。
  def blocked?(url)
    checker = DaimonSkycrawlers::Filter::RobotsTxtChecker.new(base_url: @base_url)
    !checker.call(url)
  end

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
crawler = IndexPageCrawler.new(base_url)

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run