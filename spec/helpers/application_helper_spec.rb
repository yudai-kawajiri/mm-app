require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'helper methods' do
    it 'has link_to method' do
      expect(helper).to respond_to(:link_to)
    end

    it 'has form_with method' do
      expect(helper).to respond_to(:form_with)
    end

    it 'has image_tag method' do
      expect(helper).to respond_to(:image_tag)
    end

    it 'has content_tag method' do
      expect(helper).to respond_to(:content_tag)
    end

    it 'has number_to_currency method' do
      expect(helper).to respond_to(:number_to_currency)
    end

    it 'has time_ago_in_words method' do
      expect(helper).to respond_to(:time_ago_in_words)
    end

    it 'has truncate method' do
      expect(helper).to respond_to(:truncate)
    end
  end
end
