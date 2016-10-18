require "daimon_skycrawlers/processor"
require "pry"
require "pry-nav"
require "nokogiri"

# NOTE イベント一覧ページからイベント詳細のリンクを見つけてきて、
#      その URL を再エンキューする
class ReEnqueueProcessor < DaimonSkycrawlers::Processor::Base
  def call(message)
    url = message[:url]

    # XXX この if 文中の処理は processor 層に入ってくる前に動いててほしい
    if !index_page?(url)
      log.info "#{url} will not be processed by ReEnqueueProcessor"
      return
    end

    return if message[:heartbeat]

    page = storage.find(url)
    doc = Nokogiri::HTML(page.body)

    # イベント詳細ページの URL をリストにする
    event_urls = doc.xpath(".//p[@class='event_title']/a/@href").map(&:text)

    # 再エンキューする
    event_urls.each do |event_url|
      log.info "Re-enqueue #{event_url}"
      DaimonSkycrawlers::Crawler.enqueue_url(event_url)
    end
  end
end

processor = ReEnqueueProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
