# frozen_string_literal: true

# WeatherService
#
# OpenWeatherMap APIから天気予報データを取得するサービス
#
# 使用例:
#   service = WeatherService.new(city: 'Tokyo', country_code: 'JP')
#   forecast = service.fetch_weekly_forecast
#
# 機能:
#   - 7日間の天気予報を取得
#   - API未設定時はダミーデータを返却
#   - エラー時も安全にダミーデータを返却
class WeatherService
  BASE_URL = 'https://api.openweathermap.org/data/2.5/forecast'

  # @param city [String] 都市名（デフォルト: Tokyo）
  # @param country_code [String] 国コード（デフォルト: JP）
  def initialize(city: 'Tokyo', country_code: 'JP')
    @city = city
    @country_code = country_code
    @api_key = ENV['OPENWEATHER_API_KEY']
  end

  # 週間天気予報を取得
  #
  # @return [Array<Hash>] 7日間の天気予報データ
  #   - date: 日付
  #   - temp_max: 最高気温
  #   - temp_min: 最低気温
  #   - weather: 天気（英語）
  #   - weather_description: 天気説明（日本語）
  #   - icon: 天気アイコンID
  #   - pop: 降水確率（%）
  #   - is_rainy: 雨天フラグ
  def fetch_weekly_forecast
    return dummy_data if @api_key.blank?

    response = HTTParty.get(BASE_URL, query: {
      q: "#{@city},#{@country_code}",
      appid: @api_key,
      units: 'metric',
      lang: 'ja'
    })

    if response.success?
      parse_forecast(response.parsed_response)
    else
      Rails.logger.error("Weather API Error: #{response.code} - #{response.body}")
      dummy_data
    end
  rescue StandardError => e
    Rails.logger.error("Weather Service Error: #{e.message}")
    dummy_data
  end

  private

  # APIレスポンスを解析して天気予報データに変換
  #
  # @param data [Hash] APIレスポンスデータ
  # @return [Array<Hash>] 7日間の天気予報
  def parse_forecast(data)
    daily_forecasts = group_by_date(data['list'])

    daily_forecasts.map do |date, forecasts|
      representative = forecasts.min_by { |f| (f['dt_txt'].include?('12:00') ? 0 : 1) }

      {
        date: Date.parse(date),
        temp_max: forecasts.map { |f| f.dig('main', 'temp_max') }.max.round,
        temp_min: forecasts.map { |f| f.dig('main', 'temp_min') }.min.round,
        weather: representative.dig('weather', 0, 'main'),
        weather_description: representative.dig('weather', 0, 'description'),
        icon: representative.dig('weather', 0, 'icon'),
        pop: (representative.dig('pop') || 0) * 100,
        is_rainy: rainy?(representative)
      }
    end.first(7)
  end

  # 予報データを日付ごとにグループ化
  #
  # @param list [Array<Hash>] 予報データリスト
  # @return [Hash] 日付をキーとしたグループ化データ
  def group_by_date(list)
    list.group_by { |item| item['dt_txt'].split(' ').first }
  end

  # 雨天かどうかを判定
  #
  # @param forecast [Hash] 予報データ
  # @return [Boolean] 雨天の場合true
  def rainy?(forecast)
    weather = forecast.dig('weather', 0, 'main')
    ['Rain', 'Drizzle', 'Thunderstorm'].include?(weather)
  end

  # ダミーデータを生成（API未設定時やエラー時用）
  #
  # @return [Array<Hash>] 7日間のダミー天気予報
  def dummy_data
    (0..6).map do |i|
      date = Date.current + i.days
      is_rainy = [2, 5].include?(i)

      {
        date: date,
        temp_max: rand(15..25),
        temp_min: rand(8..15),
        weather: is_rainy ? 'Rain' : ['Clear', 'Clouds', 'Clear'].sample,
        weather_description: is_rainy ? '雨' : ['晴れ', '曇り', '晴れ'].sample,
        icon: is_rainy ? '10d' : '01d',
        pop: is_rainy ? rand(60..90) : rand(0..30),
        is_rainy: is_rainy
      }
    end
  end
end
