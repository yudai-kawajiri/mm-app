class CategoriesController < ApplicationController
  def index
    # 複数形注意。昇順に並べます。
    @categories = Category.all.order(name: :asc)
  end

  def new
    @category = current_user.categories.build
  end

  def create
    # current_userに関連付けてインスタンスを作成（user_idを自動設定）
    @category = current_user.categories.build(category_params)

    if @category.save
      redirect_to categories_path
    else
      render :new
    end
  end

  def edit
     # 編集対象のレコードを取得(idはURLから)
    @category = current_user.categories.find(params[:id])
  end

  def update
    @category = current_user.categories.find(params[:id])

    if @category.update(category_params)
      # 更新成功したら一覧画面へリダイレクト
      redirect_to categories_path
    else
      # 更新失敗したら編集画面を再表示
      render :edit
    end
  end

  private

  def category_params
    # name属性のみ安全に受付
    params.require(:category).permit(:name, :category_type)
  end
end

