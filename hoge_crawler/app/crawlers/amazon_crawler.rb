require "daimon_skycrawlers/crawler"
require 'daimon_skycrawlers/filter/update_checker'
require "daimon_skycrawlers/crawler/base"
require "dotenv"
require "mechanize"
require "open-uri"

require 'pry'
require "pry-nav"

Dotenv.load

class AmazonCrawler < DaimonSkycrawlers::Crawler::Base
  def fetch(url, **kw)
    update_checker = DaimonSkycrawlers::Filter::UpdateChecker.new(storage: storage)
    unless update_checker.call(url.to_s, connection: connection)
      log.info("Skip #{url}")
      @skipped = true
      schedule_to_process(url.to_s, heartbeat: true)
      return
    end

    find(:xpath, "//a/span[contains(text(), 'お客様へのおすすめ')]").click


    #schedule_to_process(url.to_s)
  end
end

base_url = "http://example.com"
crawler = AmazonCrawler.new(base_url)

crawler.prepare do |connection|

  # ログイン
  agent = Mechanize.new

  # XXX GET する URL はエンキューされたときに指定されるのでそれを使いたい
  #     prepare の中でそれを参照するにはどうしたらいいのか？
  agent.get("https://amazon.co.jp") do |page|
    new_registration_page = agent.click(page.link_with(text: /新規登録はこちら/))
    signin_page = agent.click(new_registration_page.link_with(text: /サインイン/))
    my_page = signin_page.form_with(name: "signIn") do |f|
      f.field_with(id: "ap_email").value = ENV["AMAZON_EMAIL"]
      f.field_with(id: "ap_password").value = ENV["AMAZON_PASSWORD"]
    end.submit
    # ここで my_page には、明らかにログイン後じゃない画面が入ってくる。
    # これはなんなのか？（Status Code は 200）
    # そしてここからどうやってすすめばいいのか？
    binding.pry
  end
end

DaimonSkycrawlers.register_crawler(crawler)

DaimonSkycrawlers::Crawler.run
