# connpass_crawlers

Connpass で検索したイベント一覧から情報を取得して CSV に保存します。

- イベントタイトル
- イベントページ URL
- 会場住所

## depth 指定について

このクローラプロジェクトでは、depth を外から受け取ってリンクをたどることはしません。
crawler のコードの中で取得したいリンクに付与されている CSS セレクタをハードコーディングし、リンク先 URL を each によって GET し続けます。
