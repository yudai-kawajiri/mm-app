# frozen_string_literal: true

# CDN Helper
#
# 外部CDNリソース（Bootstrap等）のリンクタグを生成
module CdnHelper
  # Bootstrap CSS
  BOOTSTRAP_CSS_URL = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
  BOOTSTRAP_CSS_INTEGRITY = "sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH"

  # Bootstrap Icons
  BOOTSTRAP_ICONS_URL = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css"

  # Bootstrap JS
  BOOTSTRAP_JS_URL = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
  BOOTSTRAP_JS_INTEGRITY = "sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz"

  # Bootstrap CSSタグを生成
  #
  # @return [String] linkタグHTML
  def bootstrap_css_tag
    stylesheet_link_tag BOOTSTRAP_CSS_URL,
                        integrity: BOOTSTRAP_CSS_INTEGRITY,
                        crossorigin: "anonymous"
  end

  # Bootstrap Iconsタグを生成
  #
  # @return [String] linkタグHTML
  def bootstrap_icons_tag
    tag.link rel: "stylesheet", href: BOOTSTRAP_ICONS_URL
  end

  # Bootstrap JSタグを生成
  #
  # @return [String] scriptタグHTML
  def bootstrap_js_tag
    javascript_include_tag BOOTSTRAP_JS_URL,
                            integrity: BOOTSTRAP_JS_INTEGRITY,
                            crossorigin: "anonymous"
  end
end
