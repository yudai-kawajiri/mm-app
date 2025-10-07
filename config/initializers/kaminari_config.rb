Kaminari.configure do |config|
  config.default_per_page = 20
  # 最大表示件数を制限。nil にすると無制限
  # config.max_per_page = nil
  # 現在のページ番号の左右に表示するページ番号リンクの数を設定
  # 例: window = 2 で現在が 5 ページの場合、(3 4) [5] (6 7) が表示されます。
  config.window = 2
  # 最初と最後のページ番号の周りに表示するページ番号リンクの数
  # 例: outer_window = 1 の場合、1, 2, ..., 98, 99 のように表示
  config.outer_window = 1
  # 最初のページ番号の周りに表示するページ番号リンクの数を設定
  # config.left = 0
  # 最後のページ番号の周りに表示するページ番号リンクの数を設定
  # config.right = 0
  # ページネーションに使用するスコープメソッド名を設定
  # 例: User.page(3) の :page の部分
  # config.page_method_name = :page
  # URLパラメータの名前を設定。params[:page] の :page の部分
  # 例: /users?page=3
  # config.param_name = :page
  # ナビゲーションバーに表示できる最大のページ数を制限
  # nil にすると全ページが表示されます（データ量が膨大な場合にパフォーマンス低下の原因）
  config.max_pages = 20
  # 最初のページ（page=1）のURLパラメータを省略するかどうかを設定
  # false の場合、?page=1 が URL に表示されません (SEOに有利)
  # config.params_on_first_page = false
end