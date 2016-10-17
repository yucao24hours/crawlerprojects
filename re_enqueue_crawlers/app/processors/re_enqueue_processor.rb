require "daimon_skycrawlers/processor"
require "pry"
require "pry-nav"
require "nokogiri"
require "csv"

class MyProcessor < DaimonSkycrawlers::Processor::Base
  def call(message)
    return if message[:heartbeat]

    url = message[:url]
    page = storage.find(url)
    doc = Nokogiri::HTML(page.body)

    CSV.open("connpass_results_#{DateTime.now.strftime('%Y%m%d%H%M%S%L')}.csv", "w+") do |csv|
      csv << %w(イベントタイトル 開催年月日 開始時間 会場住所)
      # イベントタイトル
      title = doc.xpath(".//h2[@class='event_title']/text()").map(&:text).select{|elem| elem.present? }.join("").strip

      # 開催年月日
      event_schedule_area = doc.xpath(".//div[contains(@class, 'event_schedule_area')]")
      date = event_schedule_area.xpath(".//p[@class='ymd']/text()").text
      time = event_schedule_area.xpath(".//span[@class='hi']/text()").text

      # 会場住所
      address = doc.xpath(".//div[contains(@class, 'event_place_area')]/p[@class='adr']").text.strip

      # 実運用ではここが DB insert などになる想定。
      # しかし 1 レコードごとに SQL 発行してたのでは効率が悪すぎるな。。
      csv << [title, date, time, address]
    end
  end
end

processor = MyProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
