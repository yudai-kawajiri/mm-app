#!/usr/bin/env bash
# シェルスクリプトの実行環境を指定

# エラーが発生した場合、すぐにスクリプトの実行を停止し、不完全なデプロイを防ぎます。
set -o errexit

# GemfileとGemfile.lockに基づき、必要な全てのRubyライブラリをインストールします。
bundle install

# JavaScript、CSS、画像などの静的ファイル（アセット）を結合・圧縮し、本番環境で使えるように準備します。
bin/rails assets:precompile

# プリコンパイル後に不要になった一時ファイルなどをクリーンアップし、ディスク容量を節約します。
bin/rails assets:clean
