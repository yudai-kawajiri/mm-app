require 'rails_helper'

RSpec.describe "help/index.html.erb", type: :view do
  before do
    # 会社オブジェクトを準備
    company = build_stubbed(:company, slug: 'test-company')

    # メソッドが定義されているかチェックせず、強制的にスタブ（身代わり）をセット
    view.extend(Module.new {
      def current_user; nil; end
      def user_signed_in?; true; end
      def current_company; nil; end
    })

    # 改めて、各メソッドが呼ばれた時の戻り値を指定
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
    allow(view).to receive(:current_company).and_return(company)
  end

  it "renders" do
    render
    expect(rendered).to match(/./)
  end
end
