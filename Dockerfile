# syntax=docker/dockerfile:1
# check=error=true

# 本番環境用のDockerfile（開発環境用はDockerfile.devを使用）
# ビルドと実行:
#   docker build -t myapp .
#   docker run -d -p 80:80 -e RAILS_MASTER_KEY=<config/master.keyの値> --name myapp myapp
#
# 開発環境のコンテナ化については以下を参照:
#   https://guides.rubyonrails.org/getting_started_with_devcontainer.html

ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# ランタイムに必要な基本パッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 本番環境の設定
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"


# ビルドステージ（最終イメージには含まれない）
FROM base AS build

# gem/node_modulesのビルドに必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 libmagickwand-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Node.js/Yarnをインストール
ARG NODE_VERSION=20.19.5
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

# Rubyのgemをインストール
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# JavaScriptパッケージをインストール
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# アプリケーションコードをコピー
COPY . .

# Bootsnapの事前コンパイル（起動時間短縮）
RUN bundle exec bootsnap precompile app/ lib/

# アセットのプリコンパイル（RAILS_MASTER_KEY不要）
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# node_modulesを削除してイメージサイズ削減（プリコンパイル済みアセットはpublic/に配置済み）
RUN rm -rf node_modules


# 最終ステージ（本番環境用の軽量イメージ）
FROM base

# ビルドステージからgemとアプリケーションをコピー
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# セキュリティのため非rootユーザーで実行
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# エントリーポイント（データベース準備）
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Thruster経由でRailsサーバーを起動（実行時にオーバーライド可能）
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
