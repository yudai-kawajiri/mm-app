# 数値予測サービス
# 月末の売上予測、必要調整額、アクションプランを計算
class NumericalForecastService
  attr_reader :user, :year, :month, :budget

  def initialize(user, year, month)
    @user = user
    @year = year.to_i
    @month = month.to_i
    @budget = find_or_create_budget
    @today = Date.current
  end

  # 全ての予測データを計算
  def calculate
    {
      # 基本情報
      target_amount: target_amount,
      actual_amount: 0,  # 後で実装
      planned_amount: 0  # 後で実装
    }
  end

  private

  # 予算を取得または作成
  def find_or_create_budget
    budget_month = Date.new(@year, @month, 1)
    MonthlyBudget.find_or_create_by!(
      user: @user,
      budget_month: budget_month
    ) do |b|
      b.target_amount = 0
    end
  end

  # 目標金額
  def target_amount
    @budget.target_amount
  end
end