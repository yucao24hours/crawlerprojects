require "daimon_skycrawlers/filter/base"

class ReEnqueueFilter < DaimonSkycrawlers::Filter::Base
  def call(url)
    puts "hogehogehogehoge"
  end
end
