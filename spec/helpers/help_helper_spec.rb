require 'rails_helper'

RSpec.describe SettingsHelper, type: :helper do
  describe 'helper methods' do
    it 'is included in helper' do
      expect(helper.class.ancestors).to include(SettingsHelper)
    end
  end
end
