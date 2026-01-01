# frozen_string_literal: true

# リソースのコピー機能（一意な名前を自動生成）
module Copyable
  extend ActiveSupport::Concern

  # 10回目以降は「こぴー」を繰り返す（ひらがなバリデーション対応）
  COPY_COUNT_THRESHOLD = 10
  MAX_COPY_ATTEMPTS = 100

  included do
    class_attribute :copy_config, default: {
      name_format: ->(original_name, copy_count) {
        "#{original_name} #{I18n.t('copyable.copy_suffix', count: copy_count)}"
      },
      uniqueness_scope: :name,
      uniqueness_check_attributes: [ :name ],
      associations_to_copy: [],
      association_copy_attributes: {},
      status_on_copy: nil,
      additional_attributes: {},
      skip_attributes: [ :created_at, :updated_at, :id ]
    }
  end

  class_methods do
    def copyable_config(**options)
      self.copy_config = copy_config.merge(options)
    end
  end

  def create_copy(user:)
    ActiveRecord::Base.transaction do
      new_record = build_copy_record(user)
      new_record.save!
      copy_associations(new_record)
      new_record
    end
  end

  private

  def build_copy_record(user)
    unique_attrs = generate_unique_attributes

    new_record = dup
    new_record.name = unique_attrs[:name]
    new_record.reading = unique_attrs[:reading] if unique_attrs[:reading] && new_record.respond_to?(:reading=)
    new_record.user_id = user.id if new_record.respond_to?(:user_id=)

    apply_status_on_copy(new_record)
    apply_additional_attributes(new_record)

    new_record
  end

  def generate_unique_attributes
    original_name, original_reading = extract_original_attributes
    copy_count = determine_starting_copy_count(name)

    find_unique_attributes(original_name, original_reading, copy_count)
  end

  def extract_original_attributes
    copy_suffix_pattern = build_copy_suffix_pattern
    reading_copy_text = I18n.t("copyable.reading_copy_text")

    original_name = name.gsub(copy_suffix_pattern, "").strip
    original_reading = respond_to?(:reading) && reading ?
      reading.sub(/#{reading_copy_text}.*\z/, "").strip : nil

    [ original_name, original_reading ]
  end

  def build_copy_suffix_pattern
    copy_prefix = I18n.t("copyable.copy_suffix", count: 1).sub(/\d+/, "").sub(/\)$/, "")
    /\s*#{Regexp.escape(copy_prefix)}(\d+)\)\z/
  end

  def determine_starting_copy_count(name)
    name =~ build_copy_suffix_pattern ? $1.to_i + 1 : 1
  end

  def find_unique_attributes(original_name, original_reading, copy_count)
    MAX_COPY_ATTEMPTS.times do
      new_name = copy_config[:name_format].call(original_name, copy_count)
      new_reading = original_reading ? generate_reading_for_copy(original_reading, copy_count) : nil

      return { name: new_name, reading: new_reading } unless attributes_exist?(new_name, new_reading)

      copy_count += 1
    end

    raise I18n.t("copyable.errors.max_attempts_exceeded", max_attempts: MAX_COPY_ATTEMPTS)
  end

  def generate_reading_for_copy(original_reading, copy_count)
    reading_copy_text = I18n.t("copyable.reading_copy_text")
    reading_numbers = I18n.t("copyable.reading_numbers")

    if copy_count <= COPY_COUNT_THRESHOLD
      "#{original_reading}#{reading_copy_text}#{reading_numbers[copy_count]}"
    else
      repeat_count = copy_count - COPY_COUNT_THRESHOLD
      "#{original_reading}#{reading_copy_text * (repeat_count + 1)}"
    end
  end

  def attributes_exist?(name, reading = nil)
    base_conditions = build_base_conditions

    copy_config[:uniqueness_check_attributes].any? do |attr|
      check_conditions = build_check_conditions(base_conditions, attr, name, reading)
      next if check_conditions.nil?

      self.class.where(check_conditions).where.not(id: id).exists?
    end
  end

  def build_base_conditions
    scope = copy_config[:uniqueness_scope]
    return {} unless scope

    Array(scope).each_with_object({}) do |scope_attr, conditions|
      conditions[scope_attr] = send(scope_attr) if respond_to?(scope_attr)
    end
  end

  def build_check_conditions(base_conditions, attr, name, reading)
    conditions = base_conditions.dup

    case attr
    when :name
      conditions[:name] = name
    when :reading
      return nil unless reading
      conditions[:reading] = reading
    else
      conditions[attr] = send(attr) if respond_to?(attr)
    end

    conditions
  end

  def apply_status_on_copy(new_record)
    return unless copy_config[:status_on_copy].present? && new_record.respond_to?(:status=)
    new_record.status = copy_config[:status_on_copy]
  end

  def apply_additional_attributes(new_record)
    copy_config[:additional_attributes].each do |attr, value|
      new_record.send("#{attr}=", resolve_attribute_value(value))
    end
  end

  def resolve_attribute_value(value)
    case value
    when Symbol
      send(value) if respond_to?(value, true)
    when Proc
      value.call(self, new_record)
    else
      value
    end
  end

  def copy_associations(new_record)
    copy_config[:associations_to_copy].each do |association_name|
      copy_association(new_record, association_name)
    end
  end

  def copy_association(new_record, association_name)
    original_records = send(association_name)
    return if original_records.blank?

    original_records.each do |original_record|
      copy_association_record(new_record, association_name, original_record)
    end
  end

  def copy_association_record(new_record, association_name, original_record)
    copy_attributes = determine_copy_attributes(association_name, original_record)
    attributes = copy_attributes.index_with { |attr| original_record.send(attr) }
    new_record.send(association_name).create!(attributes)
  end

  def determine_copy_attributes(association_name, original_record)
    if copy_config[:association_copy_attributes][association_name].present?
      copy_config[:association_copy_attributes][association_name]
    else
      original_record.attributes.keys.map(&:to_sym) -
        [ :id, :created_at, :updated_at ] -
        [ association_foreign_key(association_name) ]
    end
  end

  def association_foreign_key(association_name)
    association = self.class.reflect_on_association(association_name)
    association&.foreign_key&.to_sym
  end
end
