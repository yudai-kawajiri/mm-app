class WeatherService
  BASE_URL = 'https://api.openweathermap.org/data/2.5/forecast'

  def initialize(city: '東京', country_code: 'JP')
    @city = city
    @country_code = country_code
    @api_key = ENV['OPENWEATHER_API_KEY']
  end

  # 週間天気予報を取得（5日間、3時間ごと）
  def fetch_weekly_forecast
    return dummy_data if @api_key.blank?

    response = HTTParty.get(BASE_URL, query: {
      q: "#{@city},#{@country_code}",
      appid: @api_key,
      units: 'metric', # 摂氏
      lang: 'ja' # 日本語
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

  # APIレスポンスをパース
  def parse_forecast(data)
    daily_forecasts = group_by_date(data['list'])

    daily_forecasts.map do |date, forecasts|
      # その日の予報から代表的なものを選択（昼12時に近いもの）
      representative = forecasts.min_by { |f| (f['dt_txt'].include?('12:00') ? 0 : 1) }

      {
        date: Date.parse(date),
        temp_max: forecasts.map { |f| f.dig('main', 'temp_max') }.max.round,
        temp_min: forecasts.map { |f| f.dig('main', 'temp_min') }.min.round,
        weather: representative.dig('weather', 0, 'main'),
        weather_description: representative.dig('weather', 0, 'description'),
        icon: representative.dig('weather', 0, 'icon'),
        pop: (representative.dig('pop') || 0) * 100, # 降水確率（%）
        is_rainy: rainy?(representative)
      }
    end.first(7) # 最大7日分
  end

  # 日付ごとにグループ化
  def group_by_date(list)
    list.group_by { |item| item['dt_txt'].split(' ').first }
  end

  # 雨かどうか判定
  def rainy?(forecast)
    weather = forecast.dig('weather', 0, 'main')
    ['Rain', 'Drizzle', 'Thunderstorm'].include?(weather)
  end

  # APIキーがない場合のダミーデータ
  def dummy_data
    (0..6).map do |i|
      date = Date.current + i.days
      is_rainy = [2, 5].include?(i) # 2日目と5日目を雨に設定

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
