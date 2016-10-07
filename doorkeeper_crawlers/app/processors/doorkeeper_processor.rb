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

    binding.pry
    #CSV.open("doorkeeper_offices.csv", "w") do |csv|
    #  rankings.each do |row|
    #    csv << row
    #  end
    #end
  end
end

processor = MyProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
