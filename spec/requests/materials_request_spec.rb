require 'rails_helper'

RSpec.describe "Materials", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:category) { create(:category, :material, user: admin_user) }
  let(:unit) { create(:unit, user: admin_user) }
  let!(:material) { create(:material, user: admin_user, category: category, unit_for_product: unit, unit_for_order: unit) }

  describe 'GET /materials' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_materials_path
        expect(response).to have_http_status(:success)
      end

      it '@materialsに材料を割り当てること' do
        get resources_materials_path
        expect(assigns(:materials)).to include(material)
      end

      it 'indexテンプレートを表示すること' do
        get resources_materials_path
        expect(response).to render_template(:index)
      end

      it '@material_categoriesにカテゴリ―を割り当てること' do
        get resources_materials_path
        expect(assigns(:material_categories)).not_to be_nil
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get resources_materials_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_idパラメータでリクエストが成功すること' do
          get resources_materials_path, params: { category_id: category.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_materials_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /materials/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_resources_material_path
        expect(response).to have_http_status(:success)
      end

      it '@materialに新しい材料を割り当てること' do
        get new_resources_material_path
        expect(assigns(:material)).to be_a_new(Resources::Material)
      end

      it '@material_categoriesにカテゴリ―を割り当てること' do
        get new_resources_material_path
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'newテンプレートを表示すること' do
        get new_resources_material_path
        expect(response).to render_template(:new)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_resources_material_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /materials' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_material: {
              name: '新しい材料',
              reading: 'あたらしいざいりょう',
              measurement_type: 'weight',
              category_id: category.id,
              unit_for_product_id: unit.id,
              default_unit_weight: 100,
              unit_for_order_id: unit.id,
              unit_weight_for_order: 1000,
              pieces_per_order_unit: 10,
              description: 'テスト概要'
            }
          }
        end

        it '材料が作成されること' do
          expect {
            post resources_materials_path, params: valid_params
          }.to change(Resources::Material, :count).by(1)
        end

        it '作成された材料の詳細ページにリダイレクトされること' do
          post resources_materials_path, params: valid_params
          expect(response).to redirect_to(resources_material_path(Resources::Material.last))
        end

        it '成功メッセージが表示されること' do
          post resources_materials_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_material: {
              name: '',
              category_id: category.id
            }
          }
        end

        it '材料が作成されないこと' do
          expect {
            post resources_materials_path, params: invalid_params
          }.not_to change(Resources::Material, :count)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post resources_materials_path, params: { resources_material: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /materials/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get resources_material_path(material)
        expect(response).to have_http_status(:success)
      end

      it '@materialに材料を割り当てること' do
        get resources_material_path(material)
        expect(assigns(:material)).to eq(material)
      end

      it 'showテンプレートを表示すること' do
        get resources_material_path(material)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get resources_material_path(material)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /materials/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_resources_material_path(material)
        expect(response).to have_http_status(:success)
      end

      it '@materialに材料を割り当てること' do
        get edit_resources_material_path(material)
        expect(assigns(:material)).to eq(material)
      end

      it '@material_categoriesにカテゴリ―を割り当てること' do
        get edit_resources_material_path(material)
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'editテンプレートを表示すること' do
        get edit_resources_material_path(material)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_resources_material_path(material)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /materials/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_material: {
              name: '更新された材料名',
              description: '更新された概要'
            }
          }
        end

        it '材料が更新されること' do
          patch resources_material_path(material), params: valid_params
          material.reload
          expect(material.name).to eq('更新された材料名')
        end

        it '更新された材料の詳細ページにリダイレクトされること' do
          patch resources_material_path(material), params: valid_params
          expect(response).to redirect_to(resources_material_path(material))
        end

        it '成功メッセージが表示されること' do
          patch resources_material_path(material), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_material: {
              name: ''
            }
          }
        end

        it '材料が更新されないこと' do
          original_name = material.name
          patch resources_material_path(material), params: invalid_params
          material.reload
          expect(material.name).to eq(original_name)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch resources_material_path(material), params: { resources_material: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /materials/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '材料が削除されること' do
        material_to_delete = create(:material, user: admin_user, category: category, unit_for_product: unit, unit_for_order: unit)
        expect {
          delete resources_material_path(material_to_delete)
        }.to change(Resources::Material, :count).by(-1)
      end

      it '材料一覧にリダイレクトされること' do
        delete resources_material_path(material)
        expect(response).to redirect_to(resources_materials_url)
      end

      it '成功メッセージが表示されること' do
        delete resources_material_path(material)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete resources_material_path(material)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /materials/reorder' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      let(:material1) { create(:material, user: admin_user, category: category, unit_for_product: unit, unit_for_order: unit, display_order: 1) }
      let(:material2) { create(:material, user: admin_user, category: category, unit_for_product: unit, unit_for_order: unit, display_order: 2) }
      let(:material3) { create(:material, user: admin_user, category: category, unit_for_product: unit, unit_for_order: unit, display_order: 3) }

      it '正常にレスポンスを返すこと' do
        post reorder_resources_materials_path, params: { material_ids: [ material3.id, material1.id, material2.id ] }
        expect(response).to have_http_status(:ok)
      end

      it '並び順が更新されること' do
        post reorder_resources_materials_path, params: { material_ids: [ material3.id, material1.id, material2.id ] }
        # display_orderは1から始まる
        expect(material3.reload.display_order).to eq(1)
        expect(material1.reload.display_order).to eq(2)
        expect(material2.reload.display_order).to eq(3)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post reorder_resources_materials_path, params: { material_ids: [ 1, 2, 3 ] }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
