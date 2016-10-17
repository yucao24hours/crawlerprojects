require "daimon_skycrawlers/filter/base"

class IndexPageFilter < DaimonSkycrawlers::Filter::Base
  # XXX 他の checker 系（Filter::Base を継承したもの）との対称性を取るのであれば
  #     index ページだったときには false を返すようにするべきなのかもしれないけど...
  def call(url)
    /https:\/\/connpass.com\/search\//.match(url) ? true : false
  end
end
