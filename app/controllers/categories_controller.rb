class CategoriesController < ApplicationController
  def index
    # 複数形注意。昇順に並べます。
    @categories = current_user.categories.order(name: :asc)
  end

  def new
    @category = current_user.categories.build
  end

  def create
    # current_userに関連付けてインスタンスを作成（user_idを自動設定）
    @category = current_user.categories.build(category_params)

    # メッセージ追加: 新規作成成功
    if @category.save
      redirect_to categories_path, notice: "カテゴリー「#{@category.name}」を新規作成しました。"
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
      redirect_to categories_path, notice: "カテゴリー「#{@category.name}」を更新しました。"
    else
      # 更新失敗したら編集画面を再表示
      render :edit
    end
  end

  def destroy
    # 削除対象のレコードを、current_userのカテゴリーの中から探す
    @category = current_user.categories.find(params[:id])
    # レコードを削除
    @category.destroy
    # 削除成功後、一覧画面へリダイレクト
    redirect_to categories_path, notice: "カテゴリー「#{@category.name}」を削除しました。"
  end


  private

  def category_params
    # name属性のみ安全に受付
    params.require(:category).permit(:name, :category_type)
  end
end

