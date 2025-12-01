require 'rails_helper'

RSpec.describe "Api::V1::Products", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category, category_type: :product, user: user) }
  let(:product) { create(:product, user: user, price: 1500, category: category) }

  describe 'GET /api/v1/products/:id/fetch_plan_details' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get fetch_plan_details_api_v1_product_path(product), as: :json
        expect(response).to have_http_status(:success)
      end

      it '商品情報をJSON形式で返すこと' do
        get fetch_plan_details_api_v1_product_path(product), as: :json
        json = JSON.parse(response.body)
        expect(json).to have_key('price')
        expect(json).to have_key('category_id')
      end

      it '正しい価格を返すこと' do
        get fetch_plan_details_api_v1_product_path(product), as: :json
        json = JSON.parse(response.body)
        expect(json['price']).to eq(1500)
      end

      it '正しいカテゴリ―IDを返すこと' do
        get fetch_plan_details_api_v1_product_path(product), as: :json
        json = JSON.parse(response.body)
        expect(json['category_id']).to eq(category.id)
      end
    end

    context '他のユーザーの商品にアクセスした場合' do
      let(:other_user) { create(:user) }
      let(:other_product) { create(:product, user: other_user) }

      before { sign_in user, scope: :user }

      it '404エラーを返すこと' do
        get fetch_plan_details_api_v1_product_path(other_product), as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'ログインしていない場合' do
      it 'リダイレクトされること' do
        get fetch_plan_details_api_v1_product_path(product), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
