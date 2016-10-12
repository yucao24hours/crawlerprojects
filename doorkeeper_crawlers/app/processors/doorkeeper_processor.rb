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

    CSV.open("connpass_results.csv", "w+") do |csv|
      csv << %w(イベントタイトル イベントページ 会場住所)
      doc.xpath("//div[contains(@class, 'event_list')]").each do |element|
        title = element.xpath(".//p[@class='event_title']/a/text()")
        href = element.xpath(".//p[@class='event_title']/a/@href")
        venue = element.xpath(".//p[contains(@class, 'event_place')]").text.strip
        csv << [title, href, venue]
      end
    end
  end
end

processor = MyProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
