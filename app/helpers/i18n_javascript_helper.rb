# frozen_string_literal: true

module I18nJavascriptHelper
  def i18n_javascript_translations
    translations = {
      products: {
        confirm_delete_image: t('products.messages.confirm_delete_image'),
        image_deleted: t('products.messages.image_deleted'),
        image_delete_failed: t('products.messages.image_delete_failed')
      },
      components: {
        category_tabs: {
          confirm_delete: t('components.category_tabs.confirm_delete')
        }
      },
      sortable_table: {
        saved: t('sortable_table.saved'),
        save_failed: t('sortable_table.save_failed'),
        error: t('sortable_table.error'),
        csrf_token_not_found: t('sortable_table.csrf_token_not_found')
      },
      help: {
        video_modal: {
          preparing: t('help.video_modal.preparing')
        }
      }
    }

    javascript_tag do
      <<~JS.html_safe
        window.I18n = window.I18n || {};
        window.I18n.locale = '#{I18n.locale}';
        window.I18n.translations = #{translations.to_json};
        window.I18n.t = function(key, options = {}) {
          const keys = key.split('.');
          let value = this.translations;
          for (const k of keys) {
            value = value[k];
            if (!value) return key;
          }
          if (typeof value === 'string' && options) {
            return value.replace(/%\\{(\\w+)\\}/g, (match, key) => {
              return options[key] !== undefined ? options[key] : match;
            });
          }
          return value;
        };
      JS
    end
  end
end
