require 'rails_helper'

RSpec.describe "Api::V1::Products", type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:category) { create(:category, category_type: :product, user: user, company: company) }
  let(:product) { create(:product, user: user, price: 1500, category: category, company: company) }

  describe 'GET /api/v1/products/:id/fetch_plan_details' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:fetch_plan_details_api_v1_product, product), as: :json
        expect(response).to have_http_status(:success)
      end

      it '商品情報をJSON形式で返すこと' do
        get scoped_path(:fetch_plan_details_api_v1_product, product), as: :json
        json = JSON.parse(response.body)
        expect(json).to have_key('price')
        expect(json).to have_key('category_id')
      end

      it '正しい価格を返すこと' do
        get scoped_path(:fetch_plan_details_api_v1_product, product), as: :json
        json = JSON.parse(response.body)
        expect(json['price']).to eq(1500)
      end

      it '正しいカテゴリ―IDを返すこと' do
        get scoped_path(:fetch_plan_details_api_v1_product, product), as: :json
        json = JSON.parse(response.body)
        expect(json['category_id']).to eq(category.id)
      end
    end

    context '他のユーザーの商品にアクセスした場合' do
      let(:other_user) { create(:user) }
      let(:other_product) { create(:product, user: other_user) }

      before { sign_in user, scope: :user }

      it '404エラーを返すこと' do
      other_user = create(:user)
      login_as(other_user, scope: :user)
      get "/api/v1/products/#{product.id}/fetch_plan_details"
      expect(response).to have_http_status(:not_found)
    end

      end
    end

    context 'ログインしていない場合' do
      it 'リダイレクトされること' do
      Warden.test_reset!
      get "/api/v1/products/#{product.id}/fetch_plan_details"
      expect([401, 302, 404]).to include(response.status)
    end
  end

end
