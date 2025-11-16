# frozen_string_literal: true

# Copyable
#
# リソースのコピー機能を提供するConcern
module Copyable
  extend ActiveSupport::Concern

  included do
    class_attribute :copy_config, default: {
      name_format: ->(original_name, copy_count) { "#{original_name} (コピー#{copy_count})" },
      uniqueness_scope: :name,
      uniqueness_check_attributes: [:name],
      associations_to_copy: [],
      association_copy_attributes: {},
      additional_attributes: {},
      skip_attributes: [:created_at, :updated_at, :id]
    }
  end

  class_methods do
    def copyable_config(**options)
      # association_copy_attributesがnilにならないようにする
      options[:association_copy_attributes] ||= {}
      self.copy_config = copy_config.merge(options)
    end
  end

  def create_copy(user:)
    ActiveRecord::Base.transaction do
      new_name = generate_unique_name
      new_record = dup
      new_record.name = new_name
      new_record.user_id = user.id if new_record.respond_to?(:user_id=)

      if copy_config[:status_on_copy].present? && new_record.respond_to?(:status=)
        new_record.status = copy_config[:status_on_copy]
      end

      copy_config[:additional_attributes].each do |attr, value|
        if value.is_a?(Symbol) && respond_to?(value, true)
          new_record.send("#{attr}=", send(value))
        elsif value.respond_to?(:call)
          new_record.send("#{attr}=", value.call(self, new_record))
        else
          new_record.send("#{attr}=", value)
        end
      end

      new_record.save!
      copy_associations(new_record)
      new_record
    end
  end

  private

  def generate_unique_name
    base_name = name
    copy_count = 1
    new_name = copy_config[:name_format].call(base_name, copy_count)

    while name_exists?(new_name)
      copy_count += 1
      new_name = copy_config[:name_format].call(base_name, copy_count)
    end

    new_name
  end

  def name_exists?(name)
    conditions = {}
    
    copy_config[:uniqueness_check_attributes].each do |attr|
      conditions[attr] = (attr == :name ? name : send(attr))
    end

    scope = copy_config[:uniqueness_scope]
    if scope.is_a?(Array)
      scope.each do |scope_attr|
        conditions[scope_attr] = send(scope_attr) if respond_to?(scope_attr)
      end
    elsif scope.is_a?(Symbol) && scope != :name
      conditions[scope] = send(scope) if respond_to?(scope)
    end

    self.class.exists?(conditions)
  end

  def copy_associations(new_record)
    copy_config[:associations_to_copy].each do |association_name|
      association = self.class.reflect_on_association(association_name)
      next unless association

      original_records = send(association_name)
      next if original_records.blank?

      original_records.each do |original_record|
        copy_association_record(new_record, association_name, original_record)
      end
    end
  end

  def copy_association_record(new_record, association_name, original_record)
    # association_copy_attributesを安全に取得
    association_copy_attrs = copy_config[:association_copy_attributes] || {}
    
    copy_attributes = if association_copy_attrs[association_name].present?
                        association_copy_attrs[association_name]
                      else
                        # デフォルト: すべての属性（id, timestamps, 外部キーを除く）
                        original_record.attributes.keys.map(&:to_sym) -
                          [:id, :created_at, :updated_at] -
                          [association_foreign_key(association_name)]
                      end

    attributes = copy_attributes.index_with { |attr| original_record.send(attr) }
    new_record.send(association_name).create!(attributes)
  end

  def association_foreign_key(association_name)
    association = self.class.reflect_on_association(association_name)
    association&.foreign_key&.to_sym
  end
end
