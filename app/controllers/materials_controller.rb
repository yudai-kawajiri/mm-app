class MaterialsController < ApplicationController
  def index
  end

  def show
  end

  def new
    # フォームに渡すための、新しい空の Material インスタンスを準備
    @material = Material.new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
