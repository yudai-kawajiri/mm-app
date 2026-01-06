puts "シード処理を開始します..."

# 1. 管理用会社の作成
admin_company = Company.find_or_create_by!(slug: 'system-admin') do |c|
  c.name = 'システム管理会社'
  c.email = ENV['ADMIN_COMPANY_EMAIL'] || 'admin@mm-app-manage.com'
end

# 2. システム管理者アカウント（本番用・非公開）
admin_user = User.find_or_create_by!(email: ENV['ADMIN_EMAIL'] || 'admin@example.com') do |u|
  u.password = ENV['ADMIN_PASSWORD'] || 'ChangeMe123!'
  u.password_confirmation = u.password
  u.name = ENV['ADMIN_NAME'] || 'システム管理者'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

# 3. ポートフォリオ閲覧者アカウント（転職用・公開OK）
portfolio_admin = User.find_or_create_by!(email: ENV['PORTFOLIO_EMAIL'] || 'admin@mm-app-manage.com') do |u|
  u.password = ENV['PORTFOLIO_PASSWORD'] || 'Portfolio2026!'
  u.password_confirmation = u.password
  u.name = ENV['PORTFOLIO_NAME'] || 'ポートフォリオ閲覧者（システム管理者）'
  u.role = :super_admin
  u.company = admin_company
  u.approved = true
end

# 4. ポートフォリオ用テストデータ1（魚屋の寿司株式会社）
uoya_company = Company.find_or_create_by!(slug: ENV['TEST_COMPANY_SLUG'] || 'uoya-sushi') do |c|
  c.name = ENV['TEST_COMPANY_NAME'] || '魚屋の寿司株式会社'
  c.email = ENV['TEST_COMPANY_EMAIL'] || 'info@uoya-sushi.test'
  c.phone = ENV['TEST_COMPANY_PHONE'] || '0312345678'
end

main_store = Store.find_or_create_by!(company: uoya_company, code: ENV['TEST_STORE_CODE'] || 'MAIN') do |s|
  s.name = ENV['TEST_STORE_NAME'] || '魚屋の寿司 本店'
  s.invitation_code = ENV['TEST_STORE_INVITATION_CODE'] || 'MAIN2026'
end

test_password = ENV['TEST_ACCOUNT_PASSWORD'] || 'Test2026!'

company_admin = User.find_or_create_by!(email: ENV['TEST_COMPANY_ADMIN_EMAIL'] || 'company-admin@uoya-sushi.test') do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = '会社管理者'
  u.role = :company_admin
  u.company = uoya_company
  u.approved = true
end

store_admin = User.find_or_create_by!(email: ENV['TEST_STORE_ADMIN_EMAIL'] || 'store-admin@uoya-sushi.test') do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = '店舗管理者'
  u.role = :store_admin
  u.company = uoya_company
  u.store = main_store
  u.approved = true
end

staff_user = User.find_or_create_by!(email: ENV['TEST_STAFF_EMAIL'] || 'staff@uoya-sushi.test') do |u|
  u.password = test_password
  u.password_confirmation = test_password
  u.name = '一般スタッフ'
  u.role = :general
  u.company = uoya_company
  u.store = main_store
  u.approved = true
end

# カテゴリーの作成
[
  { name: '生ねた', reading: 'なまねた', category_type: 'material' },
  { name: 'その他原材料', reading: 'そのたげんざいりょう', category_type: 'material' },
  { name: '消耗品', reading: 'しょうもうひん', category_type: 'material' },
  { name: '単品', reading: 'たんぴん', category_type: 'product' },
  { name: '盛合せ', reading: 'もりあわせ', category_type: 'product' },
  { name: '巻物', reading: 'まきもの', category_type: 'product' },
  { name: '平日プラン', reading: 'へいじつぷらん', category_type: 'plan' },
  { name: '週末プラン', reading: 'しゅうまつぷらん', category_type: 'plan' }
].each do |data|
  Resources::Category.find_or_create_by!(
    store: main_store,
    company: uoya_company,
    name: data[:name],
    category_type: data[:category_type]
  ) do |cat|
    cat.reading = data[:reading]
  end
end

# 単位の作成
[
  { name: 'g', reading: 'ぐらむ', category: :production },
  { name: '枚', reading: 'まい', category: :production },
  { name: 'kg', reading: 'きろぐらむ', category: :ordering },
  { name: '個', reading: 'こ', category: :production },
  { name: 'cs', reading: 'けえす', category: :ordering },
  { name: '袋', reading: 'ふくろ', category: :ordering },
  { name: '本', reading: 'ほん', category: :production },
  { name: '枚', reading: 'まい', category: :manufacturing },
  { name: '個', reading: 'こ', category: :manufacturing }
].each do |data|
  Resources::Unit.find_or_create_by!(
    store: main_store,
    company: uoya_company,
    name: data[:name],
    category: data[:category]
  ) do |u|
    u.reading = data[:reading]
  end
end

# 発注グループの作成
Resources::MaterialOrderGroup.find_or_create_by!(
  store: main_store,
  company: uoya_company,
  name: '生まぐろ'
) { |g| g.reading = 'なままぐろ' }

Resources::MaterialOrderGroup.find_or_create_by!(
  store: main_store,
  company: uoya_company,
  name: 'しゃり'
) { |g| g.reading = 'しゃり' }

# 原材料の作成
[
  {
    name: 'いくら', reading: 'いくら', description: '寿司ネタのいくら',
    category: '生ねた', unit_for_product: '個', unit_for_order: 'cs', production_unit: 'g',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 200.0,
    default_unit_weight: 10.0
  },
  {
    name: 'しゃり玉', reading: 'しゃりだま', description: 'にぎり用のしゃり',
    category: 'その他原材料', unit_for_product: '個', unit_for_order: 'kg', production_unit: 'g',
    order_group: 'しゃり', measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 20.0
  },
  {
    name: 'ばらしゃり', reading: 'ばらしゃり', description: '巻物用のしゃり',
    category: 'その他原材料', unit_for_product: '個', unit_for_order: 'kg', production_unit: 'g',
    order_group: 'しゃり', measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 150.0
  },
  {
    name: 'まぐろ中とろ', reading: 'まぐろちゅうとろ', description: 'まぐろの中とろ部位',
    category: '生ねた', unit_for_product: '枚', unit_for_order: 'kg', production_unit: 'g',
    order_group: '生まぐろ', measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 10.0
  },
  {
    name: 'まぐろ赤身', reading: 'まぐろあかみ', description: 'まぐろの赤身部位',
    category: '生ねた', unit_for_product: '枚', unit_for_order: 'kg', production_unit: 'g',
    order_group: '生まぐろ', measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 10.0
  },
  {
    name: 'サーモン', reading: 'さあもん', description: 'サーモンの切り身',
    category: '生ねた', unit_for_product: '枚', unit_for_order: 'kg', production_unit: 'g',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 10.0
  },
  {
    name: '全角のり', reading: 'ぜんかくのり', description: '巻物用の海苔',
    category: 'その他原材料', unit_for_product: '枚', unit_for_order: '袋', production_unit: '枚',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 100,
    default_unit_weight: 1.0
  },
  {
    name: '単品トレイ', reading: 'たんぴんとれい', description: '単品用のトレイ',
    category: '消耗品', unit_for_product: '枚', unit_for_order: 'cs', production_unit: '枚',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 100,
    default_unit_weight: 1.0
  },
  {
    name: '巻物トレイ', reading: 'まきものとれい', description: '巻物用のトレイ',
    category: '消耗品', unit_for_product: '枚', unit_for_order: 'cs', production_unit: '枚',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 100,
    default_unit_weight: 1.0
  },
  {
    name: '盛合せトレイ', reading: 'もりあわせとれい', description: '盛合せ用のトレイ',
    category: '消耗品', unit_for_product: '枚', unit_for_order: 'cs', production_unit: '枚',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 100,
    default_unit_weight: 1.0
  },
  {
    name: '軍艦のり', reading: 'ぐんかんのり', description: '軍艦巻き用の海苔',
    category: 'その他原材料', unit_for_product: '枚', unit_for_order: '袋', production_unit: '枚',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 100,
    default_unit_weight: 1.0
  },
  {
    name: '鉄火芯', reading: 'てっかしん', description: '鉄火巻き用のまぐろ',
    category: '生ねた', unit_for_product: '個', unit_for_order: 'kg', production_unit: 'g',
    order_group: '生まぐろ', measurement_type: 'weight', unit_weight_for_order: 1000.0,
    default_unit_weight: 15.0
  }
].each do |data|
  category = Resources::Category.find_by(company: uoya_company, store: main_store, name: data[:category])
  unit_for_product = Resources::Unit.find_by(
    company: uoya_company,
    store: main_store,
    name: data[:unit_for_product],
    category: :manufacturing
  ) || Resources::Unit.find_by(
    company: uoya_company,
    store: main_store,
    name: data[:unit_for_product]
  )
  unit_for_order = Resources::Unit.find_by(company: uoya_company, store: main_store, name: data[:unit_for_order])
  production_unit = Resources::Unit.find_by(company: uoya_company, store: main_store, name: data[:production_unit])
  order_group = data[:order_group].present? ? Resources::MaterialOrderGroup.find_by(company: uoya_company, store: main_store, name: data[:order_group]) : nil

  Resources::Material.find_or_create_by!(
    company: uoya_company,
    store_id: main_store.id,
    name: data[:name]
  ) do |m|
    m.reading = data[:reading]
    m.description = data[:description]
    m.category = category
    m.unit_for_product = unit_for_product
    m.unit_for_order = unit_for_order
    m.production_unit = production_unit
    m.order_group = order_group
    m.measurement_type = data[:measurement_type]
    m.unit_weight_for_order = data[:unit_weight_for_order]
    m.pieces_per_order_unit = data[:pieces_per_order_unit]
    m.default_unit_weight = data[:default_unit_weight]
  end
end

# 商品の作成
tanpin_cat = Resources::Category.find_by(company: uoya_company, store: main_store, name: '単品')
moriawase_cat = Resources::Category.find_by(company: uoya_company, store: main_store, name: '盛合せ')
makimono_cat = Resources::Category.find_by(company: uoya_company, store: main_store, name: '巻物')

maguro_sushi = Resources::Product.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  item_number: '0001'
) do |p|
  p.name = 'まぐろ寿司'
  p.reading = 'まぐろずし'
  p.category = tanpin_cat
  p.price = 1000
  p.status = :selling
end

tekkamaki = Resources::Product.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  item_number: '0002'
) do |p|
  p.name = '鉄火巻'
  p.reading = 'てっかまき'
  p.category = makimono_cat
  p.price = 500
  p.status = :selling
end

salmon_ikura = Resources::Product.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  item_number: '0003'
) do |p|
  p.name = 'サーモンいくらにぎり'
  p.reading = 'さあもんいくらにぎり'
  p.category = moriawase_cat
  p.price = 1000
  p.status = :selling
end

new_salmon_ikura = Resources::Product.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  item_number: '0004'
) do |p|
  p.name = '新サーモンいくらにぎり'
  p.reading = 'しんさあもんいくらにぎり'
  p.category = moriawase_cat
  p.price = 1200
  p.status = :draft
end

old_tekkamaki = Resources::Product.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  item_number: '0005'
) do |p|
  p.name = '旧鉄火巻'
  p.reading = 'きゅうてっかまき'
  p.category = makimono_cat
  p.price = 400
  p.status = :discontinued
end

# 商品と原材料の紐付け
[
  { product: maguro_sushi, materials: { 'まぐろ中とろ' => { quantity: 4, unit: '枚', unit_weight: 10.0 }, 'まぐろ赤身' => { quantity: 4, unit: '枚', unit_weight: 10.0 }, 'しゃり玉' => { quantity: 8, unit: '個', unit_weight: 20.0 }, '単品トレイ' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } },
  { product: tekkamaki, materials: { 'ばらしゃり' => { quantity: 1, unit: '個', unit_weight: 150.0 }, '全角のり' => { quantity: 1, unit: '枚', unit_weight: 1.0 }, '巻物トレイ' => { quantity: 1, unit: '枚', unit_weight: 1.0 }, '鉄火芯' => { quantity: 15, unit: 'g', unit_weight: 15.0 } } },
  { product: salmon_ikura, materials: { 'しゃり玉' => { quantity: 8, unit: '個', unit_weight: 20.0 }, 'サーモン' => { quantity: 4, unit: '枚', unit_weight: 10.0 }, 'いくら' => { quantity: 4, unit: '個', unit_weight: 10.0 }, '軍艦のり' => { quantity: 4, unit: '枚', unit_weight: 1.0 }, '盛合せトレイ' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } },
  { product: new_salmon_ikura, materials: { 'しゃり玉' => { quantity: 10, unit: '個', unit_weight: 20.0 }, 'サーモン' => { quantity: 5, unit: '枚', unit_weight: 10.0 }, 'いくら' => { quantity: 4, unit: '個', unit_weight: 10.0 }, '軍艦のり' => { quantity: 5, unit: '枚', unit_weight: 1.0 }, '盛合せトレイ' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } },
  { product: old_tekkamaki, materials: { 'ばらしゃり' => { quantity: 1, unit: 'g', unit_weight: 150.0 }, '全角のり' => { quantity: 1, unit: '枚', unit_weight: 1.0 }, '巻物トレイ' => { quantity: 1, unit: '枚', unit_weight: 1.0 }, '鉄火芯' => { quantity: 10, unit: 'g', unit_weight: 10.0 } } }
].each do |data|
  product = data[:product]
  data[:materials].each do |material_name, attrs|
    material = Resources::Material.find_by(company: uoya_company, store_id: main_store.id, name: material_name)
    unit = Resources::Unit.find_by(company: uoya_company, store: main_store, name: attrs[:unit])
    Planning::ProductMaterial.find_or_create_by!(product: product, material: material) do |pm|
      pm.quantity = attrs[:quantity]
      pm.unit = unit
      pm.unit_weight = attrs[:unit_weight]
    end
  end
end

# プランの作成
weekday_plan_cat = Resources::Category.find_by(company: uoya_company, store: main_store, name: '平日プラン')
weekend_plan_cat = Resources::Category.find_by(company: uoya_company, store: main_store, name: '週末プラン')

weekday_plan = Resources::Plan.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  name: '12月平日寿司計画'
) do |plan|
  plan.reading = 'じゅうにがつへいじつすしけいかく'
  plan.category = weekday_plan_cat
  plan.status = :active
  plan.user = company_admin
end

[
  { product: maguro_sushi, production_count: 10 },
  { product: tekkamaki, production_count: 10 },
  { product: salmon_ikura, production_count: 10 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: weekday_plan, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

weekend_plan = Resources::Plan.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  name: '12月週末寿司計画'
) do |plan|
  plan.reading = 'じゅうにがつしゅうまつすしけいかく'
  plan.category = weekend_plan_cat
  plan.status = :active
  plan.user = company_admin
end

[
  { product: maguro_sushi, production_count: 20 },
  { product: tekkamaki, production_count: 20 },
  { product: salmon_ikura, production_count: 20 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: weekend_plan, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

new_weekday_plan = Resources::Plan.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  name: '新12月平日寿司計画'
) do |plan|
  plan.reading = 'しんじゅうにがつへいじつすしけいかく'
  plan.category = weekday_plan_cat
  plan.status = :draft
  plan.user = company_admin
end

[
  { product: new_salmon_ikura, production_count: 15 },
  { product: tekkamaki, production_count: 12 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: new_weekday_plan, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

old_weekend_plan = Resources::Plan.find_or_create_by!(
  company: uoya_company,
  store_id: main_store.id,
  name: '旧12月週末寿司計画'
) do |plan|
  plan.reading = 'きゅうじゅうにがつしゅうまつすしけいかく'
  plan.category = weekend_plan_cat
  plan.status = :completed
  plan.user = company_admin
end

[
  { product: old_tekkamaki, production_count: 25 },
  { product: maguro_sushi, production_count: 15 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: old_weekend_plan, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

# 月次予算と日次目標
if defined?(Management::MonthlyBudget)
  current_month_start = Date.new(2026, 1, 1)
  current_month_end = current_month_start.end_of_month

  mb = Management::MonthlyBudget.find_or_create_by!(
    company: uoya_company,
    store_id: main_store.id,
    budget_month: current_month_start
  ) do |budget|
    budget.target_amount = ENV.fetch('TEST_MONTHLY_BUDGET', '1200000').to_i
    budget.target_discount_rate = 5.0
    budget.forecast_discount_rate = 10.0
  end

  if defined?(Management::DailyTarget)
    (current_month_start..current_month_end).each do |date|
      target = date.wday.in?([ 0, 6 ]) ? ENV.fetch('TEST_DAILY_TARGET_WEEKEND', '60000').to_i : ENV.fetch('TEST_DAILY_TARGET_WEEKDAY', '30000').to_i
      Management::DailyTarget.find_or_create_by!(
        monthly_budget: mb,
        target_date: date
      ) { |dt| dt.target_amount = target }
    end
  end

  if defined?(Planning::PlanSchedule)
    completed_until = Date.new(2026, 1, 15)
    (current_month_start..current_month_end).each do |date|
      target_plan = date.wday.in?([ 0, 6 ]) ? weekend_plan : weekday_plan
      target_amount = date.wday.in?([ 0, 6 ]) ? ENV.fetch('TEST_DAILY_TARGET_WEEKEND', '60000').to_i : ENV.fetch('TEST_DAILY_TARGET_WEEKDAY', '30000').to_i

      products = target_plan.plan_products.includes(:product).map do |pp|
        {
          'product_id' => pp.product_id,
          'product_name' => pp.product.name,
          'production_count' => pp.production_count,
          'price' => pp.product.price
        }
      end

      total_cost = products.sum { |p| p['production_count'] * p['price'] }
      achievement_rate = [ 0.90, 0.95, 1.00, 1.05, 1.10 ][(date.day - 1) % 5]
      actual_revenue = (target_amount * achievement_rate).round(-2)
      status = date <= completed_until ? 'completed' : 'scheduled'
      discount_rate = status == 'completed' ? 10.0 : 0.0
      discount_amount = status == 'completed' ? (actual_revenue * 0.1).round(-2) : 0

      snapshot = {
        'products' => products,
        'total_cost' => total_cost,
        'discount_rate' => discount_rate,
        'discount_amount' => discount_amount
      }

      plan_schedule = Planning::PlanSchedule.find_or_create_by!(
        company: uoya_company,
        store_id: main_store.id,
        plan: target_plan,
        scheduled_date: date
      )

      plan_schedule.update!(
        plan_products_snapshot: snapshot,
        actual_revenue: status == 'completed' ? actual_revenue : nil,
        status: status
      )
    end
  end
end

# 5. ポートフォリオ用テストデータ2（ほっと総菜株式会社）
sozai_company = Company.find_or_create_by!(slug: ENV['TEST_COMPANY2_SLUG'] || 'hot-sozai') do |c|
  c.name = ENV['TEST_COMPANY2_NAME'] || 'ほっと総菜株式会社'
  c.email = ENV['TEST_COMPANY2_EMAIL'] || 'info@hot-sozai.test'
  c.phone = ENV['TEST_COMPANY2_PHONE'] || '0398765432'
end

main_store_sozai = Store.find_or_create_by!(company: sozai_company, code: ENV['TEST_COMPANY2_STORE_CODE'] || 'MAIN') do |s|
  s.name = ENV['TEST_COMPANY2_STORE_NAME'] || 'ほっと総菜 本店'
  s.invitation_code = ENV['TEST_COMPANY2_STORE_INVITATION_CODE'] || 'SOZAI2026'
end

company_admin_sozai = User.find_or_create_by!(email: ENV['TEST_COMPANY2_ADMIN_EMAIL'] || 'company-admin@hot-sozai.test') do |u|
  u.name = '総菜会社管理者'
  u.password = test_password
  u.password_confirmation = test_password
  u.company = sozai_company
  u.role = :company_admin
  u.approved = true
end

store_admin_sozai = User.find_or_create_by!(email: ENV['TEST_COMPANY2_STORE_ADMIN_EMAIL'] || 'store-admin@hot-sozai.test') do |u|
  u.name = '総菜店舗管理者'
  u.password = test_password
  u.password_confirmation = test_password
  u.company = sozai_company
  u.store = main_store_sozai
  u.role = :store_admin
  u.approved = true
end

staff_sozai = User.find_or_create_by!(email: ENV['TEST_COMPANY2_STAFF_EMAIL'] || 'staff@hot-sozai.test') do |u|
  u.name = '総菜一般スタッフ'
  u.password = test_password
  u.password_confirmation = test_password
  u.company = sozai_company
  u.store = main_store_sozai
  u.role = :general
  u.approved = true
end

# カテゴリーの作成（総菜）
[
  { name: '野菜', reading: 'やさい', category_type: 'material' },
  { name: '肉', reading: 'にく', category_type: 'material' },
  { name: '調味料', reading: 'ちょうみりょう', category_type: 'material' },
  { name: '消耗品総菜', reading: 'しょうもうひんそうざい', category_type: 'material' },
  { name: '揚げ物', reading: 'あげもの', category_type: 'product' },
  { name: '煮物', reading: 'にもの', category_type: 'product' },
  { name: 'サラダ', reading: 'さらだ', category_type: 'product' },
  { name: '平日プラン総菜', reading: 'へいじつぷらんそうざい', category_type: 'plan' },
  { name: '週末プラン総菜', reading: 'しゅうまつぷらんそうざい', category_type: 'plan' }
].each do |data|
  Resources::Category.find_or_create_by!(
    store: main_store_sozai,
    company: sozai_company,
    name: data[:name],
    category_type: data[:category_type]
  ) { |cat| cat.reading = data[:reading] }
end

# 単位の作成（総菜）
[
  { name: 'g', reading: 'ぐらむ', category: :production },
  { name: '個', reading: 'こ', category: :production },
  { name: 'kg', reading: 'きろぐらむ', category: :ordering },
  { name: 'パック', reading: 'ぱっく', category: :ordering },
  { name: '本', reading: 'ほん', category: :production },
  { name: '袋', reading: 'ふくろ', category: :ordering },
  { name: 'ml', reading: 'みりりっとる', category: :production },
  { name: '枚', reading: 'まい', category: :manufacturing },
  { name: '個', reading: 'こ', category: :manufacturing },
  { name: '切', reading: 'きれ', category: :manufacturing },
  { name: '杯', reading: 'はい', category: :manufacturing }
].each do |data|
  Resources::Unit.find_or_create_by!(
    store: main_store_sozai,
    company: sozai_company,
    name: data[:name],
    category: data[:category]
  ) { |u| u.reading = data[:reading] }
end

# 発注グループの作成（総菜）
Resources::MaterialOrderGroup.find_or_create_by!(
  store: main_store_sozai,
  company: sozai_company,
  name: '精肉'
) { |g| g.reading = 'せいにく' }

Resources::MaterialOrderGroup.find_or_create_by!(
  store: main_store_sozai,
  company: sozai_company,
  name: '青果'
) { |g| g.reading = 'せいか' }

# 原材料の作成（総菜）
[
  {
    name: 'じゃがいも', reading: 'じゃがいも', description: '北海道産じゃがいも',
    category: '野菜', unit_for_product: '切', unit_for_order: 'kg', production_unit: 'g',
    order_group: '青果', measurement_type: 'weight', unit_weight_for_order: 10.0,
    default_unit_weight: 8.0
  },
  {
    name: '玉ねぎ', reading: 'たまねぎ', description: '国産玉ねぎ',
    category: '野菜', unit_for_product: '個', unit_for_order: 'kg', production_unit: 'g',
    order_group: '青果', measurement_type: 'weight', unit_weight_for_order: 10.0,
    default_unit_weight: 1.0
  },
  {
    name: 'にんじん', reading: 'にんじん', description: '国産にんじん',
    category: '野菜', unit_for_product: '切', unit_for_order: 'kg', production_unit: 'g',
    order_group: '青果', measurement_type: 'weight', unit_weight_for_order: 10.0,
    default_unit_weight: 7.5
  },
  {
    name: 'ひき肉', reading: 'ひきにく', description: '国産合挽き肉',
    category: '肉', unit_for_product: '個', unit_for_order: 'kg', production_unit: 'g',
    order_group: '精肉', measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 1.0
  },
  {
    name: '豚バラ肉', reading: 'ぶたばらにく', description: '国産豚バラスライス',
    category: '肉', unit_for_product: '枚', unit_for_order: 'kg', production_unit: 'g',
    order_group: '精肉', measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 10.0
  },
  {
    name: '鶏もも肉', reading: 'とりももにく', description: '国産鶏もも肉',
    category: '肉', unit_for_product: '切', unit_for_order: 'kg', production_unit: 'g',
    order_group: '精肉', measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 12.0
  },
  {
    name: 'パン粉', reading: 'ぱんこ', description: '生パン粉',
    category: '調味料', unit_for_product: '杯', unit_for_order: 'kg', production_unit: 'g',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 1.0
  },
  {
    name: '小麦粉', reading: 'こむぎこ', description: '薄力粉',
    category: '調味料', unit_for_product: '杯', unit_for_order: 'kg', production_unit: 'g',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 1.0
  },
  {
    name: '揚げ油', reading: 'あげあぶら', description: '業務用揚げ油',
    category: '調味料', unit_for_product: '杯', unit_for_order: 'ml', production_unit: 'ml',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 18000.0,
    default_unit_weight: 1.0
  },
  {
    name: 'しょうゆ', reading: 'しょうゆ', description: '濃口醤油',
    category: '調味料', unit_for_product: '杯', unit_for_order: 'ml', production_unit: 'ml',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 1800.0,
    default_unit_weight: 1.0
  },
  {
    name: '砂糖', reading: 'さとう', description: '上白糖',
    category: '調味料', unit_for_product: '杯', unit_for_order: 'kg', production_unit: 'g',
    order_group: nil, measurement_type: 'weight', unit_weight_for_order: 1.0,
    default_unit_weight: 1.0
  },
  {
    name: 'パック容器小', reading: 'ぱっくようきしょう', description: '小サイズパック',
    category: '消耗品総菜', unit_for_product: '枚', unit_for_order: 'パック', production_unit: 'パック',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 50,
    default_unit_weight: 1.0
  },
  {
    name: 'パック容器大', reading: 'ぱっくようきだい', description: '大サイズパック',
    category: '消耗品総菜', unit_for_product: '枚', unit_for_order: 'パック', production_unit: 'パック',
    order_group: nil, measurement_type: 'count', pieces_per_order_unit: 50,
    default_unit_weight: 1.0
  }
].each do |data|
  category = Resources::Category.find_by(company: sozai_company, store: main_store_sozai, name: data[:category])
  unit_for_product = Resources::Unit.find_by(company: sozai_company, store: main_store_sozai, name: data[:unit_for_product])
  unit_for_order = Resources::Unit.find_by(company: sozai_company, store: main_store_sozai, name: data[:unit_for_order])
  production_unit = Resources::Unit.find_by(company: sozai_company, store: main_store_sozai, name: data[:production_unit])
  order_group = data[:order_group].present? ? Resources::MaterialOrderGroup.find_by(company: sozai_company, store: main_store_sozai, name: data[:order_group]) : nil

  Resources::Material.find_or_create_by!(
    company: sozai_company,
    store_id: main_store_sozai.id,
    name: data[:name]
  ) do |m|
    m.reading = data[:reading]
    m.description = data[:description]
    m.category = category
    m.unit_for_product = unit_for_product
    m.unit_for_order = unit_for_order
    m.production_unit = production_unit
    m.order_group = order_group
    m.measurement_type = data[:measurement_type]
    m.unit_weight_for_order = data[:unit_weight_for_order]
    m.pieces_per_order_unit = data[:pieces_per_order_unit]
    m.default_unit_weight = data[:default_unit_weight]
  end
end

# 商品の作成（総菜）
agemono_cat_sozai = Resources::Category.find_by(company: sozai_company, store: main_store_sozai, name: '揚げ物')
nimono_cat_sozai = Resources::Category.find_by(company: sozai_company, store: main_store_sozai, name: '煮物')

korokke_sozai = Resources::Product.find_or_create_by!(
  company: sozai_company,
  store_id: main_store_sozai.id,
  item_number: 'SZ01'
) do |p|
  p.name = 'コロッケ'
  p.reading = 'ころっけ'
  p.category = agemono_cat_sozai
  p.price = 100
  p.status = :selling
end

karaage_sozai = Resources::Product.find_or_create_by!(
  company: sozai_company,
  store_id: main_store_sozai.id,
  item_number: 'SZ02'
) do |p|
  p.name = '唐揚げ'
  p.reading = 'からあげ'
  p.category = agemono_cat_sozai
  p.price = 200
  p.status = :selling
end

nikujaga_sozai = Resources::Product.find_or_create_by!(
  company: sozai_company,
  store_id: main_store_sozai.id,
  item_number: 'SZ03'
) do |p|
  p.name = '肉じゃが'
  p.reading = 'にくじゃが'
  p.category = nimono_cat_sozai
  p.price = 350
  p.status = :selling
end

# 商品と原材料の紐付け（総菜）
[
  { product: korokke_sozai, materials: { 'ひき肉' => { quantity: 1, unit: '個', unit_weight: 50.0 }, 'じゃがいも' => { quantity: 10, unit: '切', unit_weight: 80.0 }, 'パン粉' => { quantity: 1, unit: '杯', unit_weight: 10.0 }, 'パック容器小' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } },
  { product: karaage_sozai, materials: { '鶏もも肉' => { quantity: 8, unit: '切', unit_weight: 100.0 }, '小麦粉' => { quantity: 1, unit: '杯', unit_weight: 10.0 }, '揚げ油' => { quantity: 1, unit: '杯', unit_weight: 50.0 }, 'パック容器小' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } },
  { product: nikujaga_sozai, materials: { '豚バラ肉' => { quantity: 10, unit: '枚', unit_weight: 80.0 }, 'じゃがいも' => { quantity: 12, unit: '切', unit_weight: 100.0 }, '玉ねぎ' => { quantity: 1, unit: '個', unit_weight: 50.0 }, 'にんじん' => { quantity: 4, unit: '切', unit_weight: 30.0 }, 'しょうゆ' => { quantity: 1, unit: '杯', unit_weight: 15.0 }, '砂糖' => { quantity: 1, unit: '杯', unit_weight: 10.0 }, 'パック容器大' => { quantity: 1, unit: '枚', unit_weight: 1.0 } } }
].each do |data|
  product = data[:product]
  data[:materials].each do |material_name, attrs|
    material = Resources::Material.find_by(company: sozai_company, store_id: main_store_sozai.id, name: material_name)
    unit = Resources::Unit.find_by(company: sozai_company, store: main_store_sozai, name: attrs[:unit])
    Planning::ProductMaterial.find_or_create_by!(product: product, material: material) do |pm|
      pm.quantity = attrs[:quantity]
      pm.unit = unit
      pm.unit_weight = attrs[:unit_weight]
    end
  end
end

# プランの作成（総菜）
weekday_plan_cat_sozai = Resources::Category.find_by(company: sozai_company, store: main_store_sozai, name: '平日プラン総菜')
weekend_plan_cat_sozai = Resources::Category.find_by(company: sozai_company, store: main_store_sozai, name: '週末プラン総菜')

weekday_plan_sozai = Resources::Plan.find_or_create_by!(
  company: sozai_company,
  store_id: main_store_sozai.id,
  name: '平日総菜計画'
) do |plan|
  plan.reading = 'へいじつそうざいけいかく'
  plan.category = weekday_plan_cat_sozai
  plan.status = :active
  plan.user = company_admin_sozai
end

[
  { product: korokke_sozai, production_count: 50 },
  { product: karaage_sozai, production_count: 30 },
  { product: nikujaga_sozai, production_count: 20 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: weekday_plan_sozai, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

weekend_plan_sozai = Resources::Plan.find_or_create_by!(
  company: sozai_company,
  store_id: main_store_sozai.id,
  name: '週末総菜計画'
) do |plan|
  plan.reading = 'しゅうまつそうざいけいかく'
  plan.category = weekend_plan_cat_sozai
  plan.status = :active
  plan.user = company_admin_sozai
end

[
  { product: korokke_sozai, production_count: 80 },
  { product: karaage_sozai, production_count: 50 },
  { product: nikujaga_sozai, production_count: 30 }
].each do |data|
  Planning::PlanProduct.find_or_create_by!(plan: weekend_plan_sozai, product: data[:product]) do |pp|
    pp.production_count = data[:production_count]
  end
end

# 月次予算と日次目標（総菜）
if defined?(Management::MonthlyBudget)
  mb_sozai = Management::MonthlyBudget.find_or_create_by!(
    company: sozai_company,
    store_id: main_store_sozai.id,
    budget_month: current_month_start
  ) do |budget|
    budget.target_amount = ENV.fetch('TEST_MONTHLY_BUDGET', '1200000').to_i
    budget.target_discount_rate = 5.0
    budget.forecast_discount_rate = 10.0
  end

  if defined?(Management::DailyTarget)
    (current_month_start..current_month_end).each do |date|
      target = date.wday.in?([ 0, 6 ]) ? ENV.fetch('TEST_DAILY_TARGET_WEEKEND', '60000').to_i : ENV.fetch('TEST_DAILY_TARGET_WEEKDAY', '30000').to_i
      Management::DailyTarget.find_or_create_by!(
        monthly_budget: mb_sozai,
        target_date: date
      ) { |dt| dt.target_amount = target }
    end
  end

  if defined?(Planning::PlanSchedule)
    (current_month_start..Date.new(2026, 1, 2)).each do |date|
      target_plan = date.wday.in?([ 0, 6 ]) ? weekend_plan_sozai : weekday_plan_sozai
      target_amount = date.wday.in?([ 0, 6 ]) ? ENV.fetch('TEST_DAILY_TARGET_WEEKEND', '60000').to_i : ENV.fetch('TEST_DAILY_TARGET_WEEKDAY', '30000').to_i

      products = target_plan.plan_products.includes(:product).map do |pp|
        {
          'product_id' => pp.product_id,
          'product_name' => pp.product.name,
          'production_count' => pp.production_count,
          'price' => pp.product.price
        }
      end

      total_cost = products.sum { |p| p['production_count'] * p['price'] }
      achievement_rate = [ 0.85, 0.92, 0.98, 1.03, 1.12 ][(date.day - 1) % 5]
      actual_revenue = (target_amount * achievement_rate).round(-2)
      discount_rate = 12.0
      discount_amount = (actual_revenue * 0.12).round(-2)

      snapshot = {
        'products' => products,
        'total_cost' => total_cost,
        'discount_rate' => discount_rate,
        'discount_amount' => discount_amount
      }

      plan_schedule = Planning::PlanSchedule.find_or_create_by!(
        company: sozai_company,
        store_id: main_store_sozai.id,
        plan: target_plan,
        scheduled_date: date
      )

      plan_schedule.update!(
        plan_products_snapshot: snapshot,
        actual_revenue: actual_revenue,
        status: 'completed'
      )
    end

    (Date.new(2026, 1, 3)..current_month_end).each do |date|
      target_plan = date.wday.in?([ 0, 6 ]) ? weekend_plan_sozai : weekday_plan_sozai

      products = target_plan.plan_products.includes(:product).map do |pp|
        {
          'product_id' => pp.product_id,
          'product_name' => pp.product.name,
          'production_count' => pp.production_count,
          'price' => pp.product.price
        }
      end

      total_cost = products.sum { |p| p['production_count'] * p['price'] }

      snapshot = {
        'products' => products,
        'total_cost' => total_cost,
        'discount_rate' => 0.0,
        'discount_amount' => 0
      }

      plan_schedule = Planning::PlanSchedule.find_or_create_by!(
        company: sozai_company,
        store_id: main_store_sozai.id,
        plan: target_plan,
        scheduled_date: date
      )

      plan_schedule.update!(
        plan_products_snapshot: snapshot,
        actual_revenue: nil,
        status: 'scheduled'
      )
    end
  end
end

puts "シード処理完了"
puts "招待コード: #{ENV.fetch('TEST_STORE_INVITATION_CODE', 'MAIN2026')} (魚屋の寿司), #{ENV.fetch('TEST_COMPANY2_STORE_INVITATION_CODE', 'SOZAI2026')} (ほっと総菜)"
puts "月次予算: #{ENV.fetch('TEST_MONTHLY_BUDGET', '1200000')}円, 日次目標: 平日#{ENV.fetch('TEST_DAILY_TARGET_WEEKDAY', '30000')}円/週末#{ENV.fetch('TEST_DAILY_TARGET_WEEKEND', '60000')}円"
