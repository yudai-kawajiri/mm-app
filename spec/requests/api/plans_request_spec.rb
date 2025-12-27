require 'rails_helper'

RSpec.describe "Api::V1::Plans", type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:product) { create(:product, user: user, price: 1000, company: company) }
  let(:plan) { create(:plan, user: user) }
  let!(:plan_product) { create(:plan_product, plan: plan, product: product, production_count: 10) }

  describe 'GET /api/v1/plans/:id/revenue' do
    it '正常にレスポンスを返すこと' do
      get scoped_path(:revenue_api_v1_plan, plan), as: :json
      expect(response).to have_http_status(:success)
    end

    it '売上予測をJSON形式で返すこと' do
      get scoped_path(:revenue_api_v1_plan, plan), as: :json
      json = JSON.parse(response.body)
      expect(json).to have_key('revenue')
      expect(json).to have_key('formatted_revenue')
    end

    it '正しい売上予測を返すこと' do
      get scoped_path(:revenue_api_v1_plan, plan), as: :json
      json = JSON.parse(response.body)
      expect(json['revenue']).to eq(10000) # 1000 * 10
    end

    it 'フォーマット済み売上予測を返すこと' do
      get scoped_path(:revenue_api_v1_plan, plan), as: :json
      json = JSON.parse(response.body)
      expect(json['formatted_revenue']).to include('10,000')
    end

    context '存在しない計画IDの場合' do
      it '404エラーを返すこと' do
        get scoped_path(:revenue_api_v1_plan, id: 999999), as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'エラーメッセージを返すこと' do
        get scoped_path(:revenue_api_v1_plan, id: 999999), as: :json
        json = JSON.parse(response.body)
        expect(json).to have_key('error')
      end
    end
  end
end
