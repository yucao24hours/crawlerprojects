require "daimon_skycrawlers/processor"
require "pry"
require "pry-nav"
require "nokogiri"

# イベント詳細のリンクを見つけてきて、その URL を再エンキューする
class ReEnqueueProcessor < DaimonSkycrawlers::Processor::Base
  def call(message)
    return if message[:heartbeat]

    url = message[:url]
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
