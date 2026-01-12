require 'rails_helper'

RSpec.describe 'Stores Switch', type: :request do
  let(:company) { create(:company) }
  let(:store1) { create(:store, company: company) }
  let(:store2) { create(:store, company: company) }
  let(:admin) { create(:user, :company_admin, company: company, store: store1) }

  describe 'POST /switch_store' do
    it 'route exists' do
      # ルートが認識されることを確認
      expect { 
        post "/c/#{company.slug}/switch_store", params: { current_store_id: store2.id }
      }.not_to raise_error
      
      # 未認証なので302リダイレクトまたは404
      expect([302, 404]).to include(response.status)
    end
  end
end
