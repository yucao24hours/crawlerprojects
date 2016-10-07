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

    rankings = doc.xpath("//div[@class='zg_item_normal']").inject([]) do |results, element|
      rank = element.xpath(".//span[@class='zg_rankNumber']/text()").text.gsub(/\./, "")
      title = element.xpath(".//div[@class='zg_title']/a/text()").text
      results << [rank, title]
    end

    CSV.open("amazon_ranking.csv", "w") do |csv|
      rankings.each do |row|
        csv << row
      end
    end
  end
end

processor = MyProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
