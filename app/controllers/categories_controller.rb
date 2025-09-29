class CategoriesController < ApplicationController
  def index
    # 複数形注意。昇順に並べます。
    @categories = Category.all.order(name: :asc)
  end

  def new
    @category = current_user.categories.build
  end

  def create
    # Strong Parametersで安全なデータを受け取る
    @category = Category.new(category_params)

    if @category.save
      redirect_to categories_path
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  private

  def category_params
    # name属性のみ安全に受付
    params.require(:category).permit(:name, :category_type)
  end
end

