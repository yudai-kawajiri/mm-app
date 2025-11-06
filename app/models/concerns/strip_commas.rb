module StripCommas
  extend ActiveSupport::Concern

  class_methods do
    # カンマ削除対象のカラムを指定
    # 例: strip_commas_from :target_amount, :planned_revenue
    def strip_commas_from(*attributes)
      before_validation do
        attributes.each do |attribute|
          value = send(attribute)
          next if value.blank?

          # 文字列に変換してカンマとスペースを削除
          cleaned = value.to_s.gsub(/[,\s]/, '')

          # 数値として有効な場合のみ整数に変換
          send("#{attribute}=", cleaned.to_i) if cleaned.match?(/^\d+$/)
        end
      end
    end
  end
end
