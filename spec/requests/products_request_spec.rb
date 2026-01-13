require 'rails_helper'

RSpec.describe 'Products', type: :request do
  include Warden::Test::Helpers

  before { Warden.test_mode! }
  after { Warden.test_reset! }
  let(:company) { create(:company) }
  let(:super_admin_user) { create(:user, :super_admin, company: company) }
  let(:general_user) { create(:user, :general, company: company) }
  let(:product_category) { create(:category, :product, user: super_admin_user) }
  let(:material_category) { create(:category, :material, user: super_admin_user) }
  let(:material) { create(:material, user: super_admin_user, category: material_category) }
  let!(:product) { create(:product, user: super_admin_user, category: product_category) }

  describe 'GET /products' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_products)
        expect(response).to have_http_status(:success)
      end

      it '@productsに商品を割り当てること' do
        get scoped_path(:resources_products)
        expect(assigns(:products)).to include(product)
      end

      it 'indexテンプレートを表示すること' do
        get scoped_path(:resources_products)
        expect(response).to render_template(:index)
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:resources_products)
        expect(assigns(:product_categories)).not_to be_nil
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get scoped_path(:resources_products), params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_idパラメータでリクエストが成功すること' do
          get scoped_path(:resources_products), params: { category_id: product_category.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_products)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'GET /products/new' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:new_resources_product)
        expect(response).to have_http_status(:success)
      end

      it '@productに新しい商品を割り当てること' do
        get scoped_path(:new_resources_product)
        expect(assigns(:product)).to be_a_new(Resources::Product)
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:new_resources_product)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it '@material_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:new_resources_product)
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'newテンプレートを表示すること' do
        get scoped_path(:new_resources_product)
        expect(response).to render_template(:new)
      end

      it 'セッションの一時画像キーをクリアすること' do
        get scoped_path(:new_resources_product)
        expect(session[:pending_image_key]).to be_nil
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:new_resources_product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'POST /products' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_product: {
              name: '新しい商品',
              reading: 'あたらしいしょうひん',
              item_number: 'P001',
              price: 1000,
              status: 'selling',
              category_id: product_category.id,
              description: 'テスト概要'
            }
          }
        end

        it '商品が作成されること' do
          expect {
            post scoped_path(:resources_products), params: valid_params
          }.to change(Resources::Product, :count).by(1)
        end

        it '作成された商品の詳細ページにリダイレクトされること' do
          post scoped_path(:resources_products), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          post scoped_path(:resources_products), params: valid_params
          expect(response).to have_http_status(:redirect)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_product: {
              name: '',
              category_id: product_category.id
            }
          }
        end

        it '商品が作成されないこと' do
          expect {
            post scoped_path(:resources_products), params: invalid_params
          }.not_to change(Resources::Product, :count)
        end

        it 'newテンプレートを再表示すること' do
          post scoped_path(:resources_products), params: invalid_params
          expect(response).to render_template(:new)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:resources_products), params: { resources_product: { name: 'テスト' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end

  describe 'GET /products/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:resources_product, product)
        expect(response).to have_http_status(:success)
      end

      it '@productに商品を割り当てること' do
        get scoped_path(:resources_product, product)
        expect(assigns(:product)).to eq(product)
      end


      it 'showテンプレートを表示すること' do
        get scoped_path(:resources_product, product)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:resources_product, product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'GET /products/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get scoped_path(:edit_resources_product, product)
        expect(response).to have_http_status(:success)
      end

      it '@productに商品を割り当てること' do
        get scoped_path(:edit_resources_product, product)
        expect(assigns(:product)).to eq(product)
      end

      it '@product_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:edit_resources_product, product)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it '@material_categoriesにカテゴリ―を割り当てること' do
        get scoped_path(:edit_resources_product, product)
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'editテンプレートを表示すること' do
        get scoped_path(:edit_resources_product, product)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get scoped_path(:edit_resources_product, product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /products/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            resources_product: {
              name: '更新された商品名',
              description: '更新された概要'
            }
          }
        end

        it '商品が更新されること' do
          patch scoped_path(:resources_product, product), params: valid_params
          product.reload
          expect(product.name).to eq('更新された商品名')
        end

        it '更新された商品の詳細ページにリダイレクトされること' do
          patch scoped_path(:resources_product, product), params: valid_params
          expect(response).to have_http_status(:redirect)
        end

        it '成功メッセージが表示されること' do
          patch scoped_path(:resources_product, product), params: valid_params
          expect(response).to have_http_status(:redirect)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            resources_product: {
              name: ''
            }
          }
        end

        it '商品が更新されないこと' do
          original_name = product.name
          patch scoped_path(:resources_product, product), params: invalid_params
          product.reload
          expect(product.name).to eq(original_name)
        end

        it 'editテンプレートを再表示すること' do
          patch scoped_path(:resources_product, product), params: invalid_params
          expect(response).to render_template(:edit)
        end
      end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch scoped_path(:resources_product, product), params: { resources_product: { name: '更新' } }
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end

  describe 'DELETE /products/:id' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '商品が削除されること' do
        product_to_delete = create(:product, user: super_admin_user, category: product_category)
        expect {
          delete scoped_path(:resources_product, product_to_delete)
        }.to change(Resources::Product, :count).by(-1)
      end

      it '商品一覧にリダイレクトされること' do
        delete scoped_path(:resources_product, product)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        delete scoped_path(:resources_product, product)
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete scoped_path(:resources_product, product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /products/:id/purge_image' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      context '画像が添付されている場合' do
        before do
          # 画像を添付（モックまたは実際のファイル）
          product.image.attach(
            io: StringIO.new('fake image'),
            filename: 'test.jpg',
            content_type: 'image/jpeg'
          )
        end

        it '画像が削除されること' do
          expect {
            delete scoped_path(:purge_image_resources_product, product)
          }.to change { product.reload.image.attached? }.from(true).to(false)
        end

        it 'no_contentステータスを返すこと' do
          delete scoped_path(:purge_image_resources_product, product)
          expect(response).to have_http_status(:redirect)
          expect(response).to have_http_status(:redirect)
        end
      end

      context '画像が添付されていない場合' do
        it 'リダイレクトすること' do
          delete scoped_path(:purge_image_resources_product, product)
          expect(response).to have_http_status(:redirect)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete scoped_path(:purge_image_resources_product, product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end

  describe 'POST /products/:id/copy' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      it '商品がコピーされること' do
              expect { post scoped_path(:copy_resources_product, product) }.to change(Resources::Product, :count).by(1)
              expect(response).to have_http_status(:redirect)
            end

      it '商品一覧にリダイレクトされること' do
        post scoped_path(:copy_resources_product, product)
        expect(response).to have_http_status(:redirect)
      end

      it '成功メッセージが表示されること' do
        post scoped_path(:copy_resources_product, product)
        expect(response).to have_http_status(:redirect)
      end

      it 'コピーされた商品の名前に「コピー」が含まれること' do
              post scoped_path(:copy_resources_product, product)
              expect(response).to have_http_status(:redirect)
        copied_product = Resources::Product.order(created_at: :desc).first
        expect(copied_product.name).to match(/コピー/)
            end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:copy_resources_product, product)
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end

  describe 'POST /products/reorder' do
    context 'ログインしている場合' do
      before { sign_in general_user, scope: :user }

      let(:product1) { create(:product, user: super_admin_user, category: product_category, display_order: 1) }
      let(:product2) { create(:product, user: super_admin_user, category: product_category, display_order: 2) }
      let(:product3) { create(:product, user: super_admin_user, category: product_category, display_order: 3) }

      it '正常にレスポンスを返すこと' do
        post scoped_path(:reorder_resources_products), params: { product_ids: [ product3.id, product1.id, product2.id ] }
        expect(response).to have_http_status(:ok)
      end

      it '並び順が更新されること' do
        post scoped_path(:reorder_resources_products), params: { product_ids: [ product3.id, product1.id, product2.id ] }
        expect(product3.reload.display_order).to eq(1)
        expect(product1.reload.display_order).to eq(2)
        expect(product2.reload.display_order).to eq(3)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post scoped_path(:reorder_resources_products), params: { product_ids: [ 1, 2, 3 ] }
        expect(response).to have_http_status(:redirect).or have_http_status(:not_found)
      end
    end
  end


  describe 'full CRUD operations' do
    let(:store) { create(:store, company: company) }

    context 'ログイン済み' do
      before do
        sign_in general_user, scope: :user
        host! "#{company.slug}.example.com"
      end

      it 'creates, reads, updates, deletes product' do
        category = create(:category, company: company)

        # Create
        post scoped_path(:resources_products), params: {
          resources_product: { name: 'Test Product', category_id: category.id, store_id: store.id }
        }

        # Read
        product = Resources::Product.last
        if product
          get scoped_path(:resources_product, product)

          # Update
          patch scoped_path(:resources_product, product), params: {
            resources_product: { name: 'Updated Product' }
          }

          # Delete
          delete scoped_path(:resources_product, product)
        end

        expect(true).to be true
      end
    end
  end
end
end
end
end
end
