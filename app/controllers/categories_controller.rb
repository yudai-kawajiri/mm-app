class CategoriesController < ApplicationController
  def index
    # 複数形注意。昇順に並べます。
    @categories = Category.all.order(name: :asc)
  end

  def new
    @Category = Category.new
  end

  def show
  end

  def edit
  end

  private

  def Category_params
    # name属性のみ安全に受付
    params.require(:Category).permit(:name)
  end
end

