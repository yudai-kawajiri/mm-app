class Users::RegistrationsController < Devise::RegistrationsController
  #  編集画面 と更新処理 にのみ 'authenticated_layout' を適用
  layout 'authenticated_layout', only: [:edit, :update]
end