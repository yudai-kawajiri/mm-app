# frozen_string_literal: true

# NumericSanitizer
#
# 数値パラメータのサニタイズ機能を提供するConcern
#
# 目的:
#   - HTMLフォームから送信される数値文字列を適切な数値型に変換
#   - 全角数字、空白文字、カンマを処理
#   - Railsのnumericalityバリデーションに適合する形式に統一
#
# 背景:
#   - HTMLのtext_fieldは全て文字列として値を返す
#   - JavaScriptで数値型に変換してもHTTP送信時に文字列に戻る
#   - Railsのnumericalityバリデーションは文字列"111.0"を拒否
#   - 全角数字や空白が混入するとバリデーションエラーになる
#
# 使用例:
#   class ProductsController < AuthenticatedController
#     include NumericSanitizer
#
#     def create
#       @product = Product.new(sanitized_product_params)
#     end
#
#     private
#
#     def sanitized_product_params
#       sanitize_numeric_params(
#         product_params,
#         with_comma: [:price],
#         without_comma: [:quantity]
#       )
#     end
#   end
#
module NumericSanitizer
  extend ActiveSupport::Concern

  # 数値パラメータのサニタイズ処理
  #
  # @param params_hash [ActionController::Parameters, Hash] サニタイズ対象のパラメータ
  # @param with_comma [Array<Symbol>] カンマ区切りを許可するフィールド名の配列
  # @param without_comma [Array<Symbol>] カンマなし（整数・小数）のフィールド名の配列
  # @return [ActionController::Parameters, Hash] サニタイズ済みパラメータ
  #
  # @example
  #   sanitize_numeric_params(
  #     { price: "1,234", quantity: "　５６　" },
  #     with_comma: [:price],
  #     without_comma: [:quantity]
  #   )
  #   # => { price: 1234, quantity: 56 }
  #
  def sanitize_numeric_params(params_hash, with_comma: [], without_comma: [])
    return params_hash if params_hash.blank?

    working_hash = if params_hash.is_a?(ActionController::Parameters)
                     params_hash.to_unsafe_h
                   else
                     params_hash.dup
                   end

    with_comma.each do |field|
      if working_hash[field].present?
        working_hash[field] = sanitize_with_comma(working_hash[field])
      end
    end

    without_comma.each do |field|
      if working_hash[field].present?
        working_hash[field] = sanitize_without_comma(working_hash[field])
      end
    end

    if params_hash.is_a?(ActionController::Parameters)
      ActionController::Parameters.new(working_hash).permit!
    else
      working_hash
    end
  end

  private

  # カンマ区切り数値のサニタイズ処理
  #
  # 処理内容:
  #   - 全角数字→半角数字に変換
  #   - 空白文字（全角・半角・タブ）を削除
  #   - カンマを削除
  #   - 小数点を含む数値文字列をFloatに変換
  #   - 整数ならIntegerに変換
  #
  # @param value [String, Numeric] サニタイズ対象の値
  # @return [Integer, Float, nil] サニタイズ済みの数値
  #
  # @example
  #   sanitize_with_comma("１,２３４.５６")  # => 1234.56
  #   sanitize_with_comma("1,000")          # => 1000
  #   sanitize_with_comma("　1 , 2 3 4　")  # => 1234
  #   sanitize_with_comma("")               # => nil
  #
  def sanitize_with_comma(value)
    return nil if value.blank?
    return value if value.is_a?(Numeric)

    str = value.to_s
    str = str.tr('０-９', '0-9')
    str = str.gsub(/[\s　\t]+/, '')
    str = str.delete(',')

    return nil if str.blank?

    if str.include?('.')
      Float(str)
    else
      Integer(str)
    end
  rescue ArgumentError, TypeError
    nil
  end

  # カンマなし数値のサニタイズ処理
  #
  # 処理内容:
  #   - 全角数字→半角数字に変換
  #   - 空白文字（全角・半角・タブ）を削除
  #   - 小数点を含む数値文字列をFloatに変換
  #   - 整数ならIntegerに変換
  #
  # 注意:
  #   カンマが含まれている場合、数値変換に失敗してnilを返す
  #   （カンマありフィールドとの区別のため意図的な仕様）
  #
  # @param value [String, Numeric] サニタイズ対象の値
  # @return [Integer, Float, nil] サニタイズ済みの数値
  #
  # @example
  #   sanitize_without_comma("１２３.４５")   # => 123.45
  #   sanitize_without_comma("456")          # => 456
  #   sanitize_without_comma("　７８９　")   # => 789
  #   sanitize_without_comma("1,234")        # => nil（カンマが含まれるため失敗）
  #   sanitize_without_comma("")             # => nil
  #
  def sanitize_without_comma(value)
    return nil if value.blank?
    return value if value.is_a?(Numeric)

    str = value.to_s
    str = str.tr('０-９', '0-9')
    str = str.gsub(/[\s　\t]+/, '')

    return nil if str.blank?
    return nil if str.include?(',')

    if str.include?('.')
      Float(str)
    else
      Integer(str)
    end
  rescue ArgumentError, TypeError
    nil
  end
end
