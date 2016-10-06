#!/usr/bin/env ruby

require "daimon_skycrawlers/processor"
require "pry"
require "nokogiri"

require_relative "./init"

class MyProcessor < DaimonSkycrawlers::Processor::Base
  def call(message)
    return if message[:heartbeat]
    url = message[:url]

    page = storage.find(url)

    doc = Nokogiri::HTML(page.body)
    doc.xpath("//div[@class='zg_title']/a/text()").each{|text| pp text.content }
  end
end

processor = MyProcessor.new
DaimonSkycrawlers.register_processor(processor)

DaimonSkycrawlers::Processor.run
