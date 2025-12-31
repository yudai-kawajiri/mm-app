require 'rails_helper'

RSpec.describe "Api::V1::Materials", type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }

  let(:company) { create(:company) }
  let(:user) { create(:user, company: company) }
  let(:unit) { create(:unit, user: user, category: :production) }
  let(:material) { create(:material, user: user, production_unit: unit, default_unit_weight: 100) }

  describe 'GET /api/v1/materials/:id/fetch_product_unit_data' do
    context 'ログインしている場合' do
      before { sign_in user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:fetch_product_unit_data_api_v1_material, material), as: :json
        expect(response).to have_http_status(:success)
      end

      it '単位情報をJSON形式で返すこと' do
        get scoped_path(:fetch_product_unit_data_api_v1_material, material), as: :json
        json = JSON.parse(response.body)
        expect(json).to have_key('unit_id')
        expect(json).to have_key('unit_name')
        expect(json).to have_key('default_unit_weight')
      end

      it '正しい単位IDを返すこと' do
        get scoped_path(:fetch_product_unit_data_api_v1_material, material), as: :json
        json = JSON.parse(response.body)
        expect(json['unit_id']).to eq(unit.id)
      end

      it '正しい単位名を返すこと' do
        get scoped_path(:fetch_product_unit_data_api_v1_material, material), as: :json
        json = JSON.parse(response.body)
        expect(json['unit_name']).to eq(unit.name)
      end
    end

    context '他のユーザーの原材料にアクセスした場合' do
      let(:other_user) { create(:user) }
      let(:other_material) { create(:material, user: other_user) }

      before { sign_in user, scope: :user }

      it '404エラーを返すこと' do
      other_user = create(:user)
      login_as(other_user, scope: :user)
      get "/api/v1/materials/#{material.id}/fetch_product_unit_data"
      expect(response).to have_http_status(:not_found)
    end
      end
    end

    context 'ログインしていない場合' do
      it 'unauthorizedステータスを返すこと' do
      Warden.test_reset!
      get "/api/v1/materials/#{material.id}/fetch_product_unit_data"
      expect([ 401, 302, 404 ]).to include(response.status)
    end
  end
end
