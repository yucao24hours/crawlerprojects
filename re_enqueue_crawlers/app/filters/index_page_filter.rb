require "daimon_skycrawlers/filter/base"

class IndexPageFilter < DaimonSkycrawlers::Filter::Base
  # NOTE 検索結果の一覧ページかどうかを判定する
  def call(url)
    url.match(/https:\/\/connpass.com\/search\//) ? true : false
  end
end
