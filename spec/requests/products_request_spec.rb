require 'rails_helper'

RSpec.describe "Products", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:staff_user) { create(:user, :staff) }
  let(:product_category) { create(:category, :product, user: admin_user) }
  let(:material_category) { create(:category, :material, user: admin_user) }
  let(:material) { create(:material, user: admin_user, category: material_category) }
  let!(:product) { create(:product, user: admin_user, category: product_category) }

  describe 'GET /products' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get products_path
        expect(response).to have_http_status(:success)
      end

      it '@productsに商品を割り当てること' do
        get products_path
        expect(assigns(:products)).to include(product)
      end

      it 'indexテンプレートを表示すること' do
        get products_path
        expect(response).to render_template(:index)
      end

      it '@product_categoriesにカテゴリを割り当てること' do
        get products_path
        expect(assigns(:product_categories)).not_to be_nil
      end

      context '検索パラメータがある場合' do
        it 'qパラメータでリクエストが成功すること' do
          get products_path, params: { q: 'テスト' }
          expect(response).to have_http_status(:success)
        end

        it 'category_idパラメータでリクエストが成功すること' do
          get products_path, params: { category_id: product_category.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get products_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /products/new' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get new_product_path
        expect(response).to have_http_status(:success)
      end

      it '@productに新しい商品を割り当てること' do
        get new_product_path
        expect(assigns(:product)).to be_a_new(Product)
      end

      it '@product_categoriesにカテゴリを割り当てること' do
        get new_product_path
        expect(assigns(:product_categories)).not_to be_nil
      end

      it '@material_categoriesにカテゴリを割り当てること' do
        get new_product_path
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'newテンプレートを表示すること' do
        get new_product_path
        expect(response).to render_template(:new)
      end

      it 'セッションの一時画像キーをクリアすること' do
        get new_product_path
        expect(session[:pending_image_key]).to be_nil
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get new_product_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /products' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            product: {
              name: '新しい商品',
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
            post products_path, params: valid_params
          }.to change(Product, :count).by(1)
        end

        it '作成された商品の詳細ページにリダイレクトされること' do
          post products_path, params: valid_params
          expect(response).to redirect_to(product_path(Product.last))
        end

        it '成功メッセージが表示されること' do
          post products_path, params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            product: {
              name: '',
              category_id: product_category.id
            }
          }
        end

        it '商品が作成されないこと' do
          expect {
            post products_path, params: invalid_params
          }.not_to change(Product, :count)
        end

        it 'newテンプレートを再表示すること' do
          post products_path, params: invalid_params
          expect(response).to render_template(:new)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post products_path, params: { product: { name: 'テスト' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /products/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get product_path(product)
        expect(response).to have_http_status(:success)
      end

      it '@productに商品を割り当てること' do
        get product_path(product)
        expect(assigns(:product)).to eq(product)
      end

      it '@product_materialsに材料を割り当てること' do
        get product_path(product)
        expect(assigns(:product_materials)).not_to be_nil
      end

      it 'showテンプレートを表示すること' do
        get product_path(product)
        expect(response).to render_template(:show)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /products/:id/edit' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '正常にレスポンスを返すこと' do
        get edit_product_path(product)
        expect(response).to have_http_status(:success)
      end

      it '@productに商品を割り当てること' do
        get edit_product_path(product)
        expect(assigns(:product)).to eq(product)
      end

      it '@product_categoriesにカテゴリを割り当てること' do
        get edit_product_path(product)
        expect(assigns(:product_categories)).not_to be_nil
      end

      it '@material_categoriesにカテゴリを割り当てること' do
        get edit_product_path(product)
        expect(assigns(:material_categories)).not_to be_nil
      end

      it 'editテンプレートを表示すること' do
        get edit_product_path(product)
        expect(response).to render_template(:edit)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        get edit_product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'PATCH /products/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      context '有効なパラメータの場合' do
        let(:valid_params) do
          {
            product: {
              name: '更新された商品名',
              description: '更新された概要'
            }
          }
        end

        it '商品が更新されること' do
          patch product_path(product), params: valid_params
          product.reload
          expect(product.name).to eq('更新された商品名')
        end

        it '更新された商品の詳細ページにリダイレクトされること' do
          patch product_path(product), params: valid_params
          expect(response).to redirect_to(product_path(product))
        end

        it '成功メッセージが表示されること' do
          patch product_path(product), params: valid_params
          expect(flash[:notice]).to be_present
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_params) do
          {
            product: {
              name: ''
            }
          }
        end

        it '商品が更新されないこと' do
          original_name = product.name
          patch product_path(product), params: invalid_params
          product.reload
          expect(product.name).to eq(original_name)
        end

        it 'editテンプレートを再表示すること' do
          patch product_path(product), params: invalid_params
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        patch product_path(product), params: { product: { name: '更新' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /products/:id' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '商品が削除されること' do
        product_to_delete = create(:product, user: admin_user, category: product_category)
        expect {
          delete product_path(product_to_delete)
        }.to change(Product, :count).by(-1)
      end

      it '商品一覧にリダイレクトされること' do
        delete product_path(product)
        expect(response).to redirect_to(products_url)
      end

      it '成功メッセージが表示されること' do
        delete product_path(product)
        expect(flash[:notice]).to be_present
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /products/:id/purge_image' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

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
            delete purge_image_product_path(product)
          }.to change { product.reload.image.attached? }.from(true).to(false)
        end

        it 'no_contentステータスを返すこと' do
          delete purge_image_product_path(product)
          expect(response).to have_http_status(:no_content)
        end
      end

      context '画像が添付されていない場合' do
        it 'not_foundステータスを返すこと' do
          delete purge_image_product_path(product)
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        delete purge_image_product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /products/:id/copy' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      it '商品がコピーされること' do
        expect {
          post copy_product_path(product)
        }.to change(Product, :count).by(1)
      end

      it '商品一覧にリダイレクトされること' do
        post copy_product_path(product)
        expect(response).to redirect_to(products_path)
      end

      it '成功メッセージが表示されること' do
        post copy_product_path(product)
        expect(flash[:notice]).to be_present
      end

      it 'コピーされた商品の名前に「コピー」が含まれること' do
        post copy_product_path(product)
        copied_product = Product.last
        expect(copied_product.name).to include('コピー')
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post copy_product_path(product)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST /products/reorder' do
    context 'ログインしている場合' do
      before { sign_in admin_user, scope: :user }

      let(:product1) { create(:product, user: admin_user, category: product_category, display_order: 1) }
      let(:product2) { create(:product, user: admin_user, category: product_category, display_order: 2) }
      let(:product3) { create(:product, user: admin_user, category: product_category, display_order: 3) }

      it '正常にレスポンスを返すこと' do
        post reorder_products_path, params: { product_ids: [product3.id, product1.id, product2.id] }
        expect(response).to have_http_status(:ok)
      end

      it '並び順が更新されること' do
        post reorder_products_path, params: { product_ids: [product3.id, product1.id, product2.id] }
        expect(product3.reload.display_order).to eq(1)
        expect(product1.reload.display_order).to eq(2)
        expect(product2.reload.display_order).to eq(3)
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされること' do
        post reorder_products_path, params: { product_ids: [1, 2, 3] }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
