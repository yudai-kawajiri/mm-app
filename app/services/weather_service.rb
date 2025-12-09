# frozen_string_literal: true

##
# OpenWeatherMap APIから天気予報データを取得するサービス
#
# 7日間の天気予報を取得し、API未設定時やエラー時は
# ダミーデータを返却します。
#
# @example 基本的な使用方法
#   service = WeatherService.new(city: 'Tokyo', country_code: 'JP')
#   forecast = service.fetch_weekly_forecast
#
class WeatherService
  # OpenWeatherMap API のベースURL
  BASE_URL = "https://api.openweathermap.org/data/2.5/forecast"

  # デフォルト都市名
  DEFAULT_CITY = "Tokyo"

  # デフォルト国コード
  DEFAULT_COUNTRY_CODE = "JP"

  # API温度単位（摂氏）
  API_UNITS = "metric"

  # API言語設定
  API_LANGUAGE = "ja"

  # パーセント計算用の係数
  PERCENTAGE_MULTIPLIER = 100

  # 取得する予報日数
  FORECAST_DAYS = 7

  # 予報日数範囲
  FORECAST_RANGE = (0..6)

  # 代表時刻（正午）
  REPRESENTATIVE_HOUR = "12:00"

  # 夜間アイコン識別子
  NIGHT_ICON_SUFFIX = "n"

  # 昼間アイコン識別子
  DAY_ICON_SUFFIX = "d"

  # 雨天判定用の天気タイプ
  RAINY_WEATHER_TYPES = %w[Rain Drizzle Thunderstorm].freeze

  # 優先度: 正午データ
  PRIORITY_NOON = 0

  # 優先度: その他の時刻データ
  PRIORITY_OTHER = 1

  # ダミーデータ用: 最高気温範囲
  DUMMY_TEMP_MAX_RANGE = (15..25)

  # ダミーデータ用: 最低気温範囲
  DUMMY_TEMP_MIN_RANGE = (8..15)

  # ダミーデータ用: 晴天時の天気タイプ
  DUMMY_CLEAR_WEATHER_TYPES = %w[Clear Clouds].freeze

  # ダミーデータ用: 晴天時の天気概要
  DUMMY_CLEAR_WEATHER_DESCRIPTIONS = %w[晴れ 曇り].freeze

  # ダミーデータ用: 雨天時の天気タイプ
  DUMMY_RAINY_WEATHER = "Rain"

  # ダミーデータ用: 雨天時の天気概要
  DUMMY_RAINY_DESCRIPTION = "雨"

  # ダミーデータ用: 雨天時のアイコンID
  DUMMY_RAINY_ICON = "10d"

  # ダミーデータ用: 晴天時のアイコンID
  DUMMY_CLEAR_ICON = "01d"

  # ダミーデータ用: 雨天時の降水確率範囲
  DUMMY_RAINY_POP_RANGE = (60..90)

  # ダミーデータ用: 晴天時の降水確率範囲
  DUMMY_CLEAR_POP_RANGE = (0..30)

  # ダミーデータ用: 雨天にする日のインデックス
  DUMMY_RAINY_DAY_INDICES = [ 2, 5 ].freeze

  ##
  # @param city [String] 都市名
  # @param country_code [String] 国コード
  def initialize(city: DEFAULT_CITY, country_code: DEFAULT_COUNTRY_CODE)
    @city = city
    @country_code = country_code
    @api_key = ENV["OPENWEATHER_API_KEY"]
  end

  ##
  # 週間天気予報を取得
  #
  # @return [Array<Hash>] 7日間の天気予報データ
  #   - date: 日付
  #   - temp_max: 最高気温
  #   - temp_min: 最低気温
  #   - weather: 天気（英語）
  #   - weather_description: 天気概要（日本語）
  #   - icon: 天気アイコンID
  #   - pop: 降水確率（%）
  def fetch_weekly_forecast
    return dummy_data if @api_key.blank?

    response = HTTParty.get(BASE_URL, query: {
      q: "#{@city},#{@country_code}",
      appid: @api_key,
      units: API_UNITS,
      lang: API_LANGUAGE
    })

    if response.success?
      parse_forecast(response.parsed_response)
    else
      Rails.logger.error(I18n.t("services.weather.errors.api_error", code: response.code, body: response.body))
      dummy_data
    end
  rescue StandardError => e
    Rails.logger.error(I18n.t("services.weather.errors.service_error", message: e.message))
    dummy_data
  end

  private

  ##
  # APIレスポンスを解析して天気予報データに変換
  #
  # @param data [Hash] APIレスポンスデータ
  # @return [Array<Hash>] 7日間の天気予報
  def parse_forecast(data)
    daily_forecasts = group_by_date(data["list"])

    daily_forecasts.map do |date, forecasts|
      representative = forecasts.min_by { |f| (f["dt_txt"].include?(REPRESENTATIVE_HOUR) ? PRIORITY_NOON : PRIORITY_OTHER) }
      icon_code = representative.dig("weather", 0, "icon")

      {
        date: Date.parse(date),
        temp_max: forecasts.map { |f| f.dig("main", "temp_max") }.max.round,
        temp_min: forecasts.map { |f| f.dig("main", "temp_min") }.min.round,
        weather: representative.dig("weather", 0, "main"),
        weather_description: representative.dig("weather", 0, "description"),
        icon: icon_code&.gsub(NIGHT_ICON_SUFFIX, DAY_ICON_SUFFIX),
        pop: (representative.dig("pop") || 0) * PERCENTAGE_MULTIPLIER
      }
    end.first(FORECAST_DAYS)
  end

  ##
  # 予報データを日付ごとにグループ化
  #
  # @param list [Array<Hash>] 予報データリスト
  # @return [Hash] 日付をキーとしたグループ化データ
  def group_by_date(list)
    list.group_by { |item| item["dt_txt"].split(" ").first }
  end

  ##
  # 雨天かどうかを判定
  #
  # @param forecast [Hash] 予報データ
  # @return [Boolean] 雨天の場合true
  def rainy?(forecast)
    weather = forecast.dig("weather", 0, "main")
    RAINY_WEATHER_TYPES.include?(weather)
  end

  ##
  # ダミーデータを生成（API未設定時やエラー時用）
  #
  # @return [Array<Hash>] 7日間のダミー天気予報
  def dummy_data
    FORECAST_RANGE.map do |i|
      date = Date.current + i.days

      {
        date: date,
        temp_max: rand(DUMMY_TEMP_MAX_RANGE),
        temp_min: rand(DUMMY_TEMP_MIN_RANGE),
        weather: DUMMY_CLEAR_WEATHER_TYPES.sample,
        weather_description: DUMMY_CLEAR_WEATHER_DESCRIPTIONS.sample,
        icon: DUMMY_CLEAR_ICON,
        pop: rand(DUMMY_CLEAR_POP_RANGE)
      }
    end
  end
end
