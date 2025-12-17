class ApplicationRequestMailer < ApplicationMailer
  def invitation_email(application_request)
    @application_request = application_request
    @invitation_url = accept_application_requests_url(
      token: application_request.invitation_token,
      host: ENV.fetch('APP_HOST', 'localhost:3000'),
      protocol: ENV.fetch('APP_PROTOCOL', 'http')
    )

    mail(
      to: application_request.contact_email,
      subject: '【MM-App】アプリケーション責任者招待のご案内'
    )
  end

  def approval_notification(admin_request)
    @admin_request = admin_request
    @user = admin_request.user
    @login_url = new_user_session_url(
      host: "#{admin_request.user.tenant.subdomain}.#{ENV.fetch('APP_DOMAIN', 'localhost:3000')}",
      protocol: ENV.fetch('APP_PROTOCOL', 'http')
    )

    mail(
      to: @user.email,
      subject: '【MM-App】ユーザー登録が承認されました'
    )
  end

  def rejection_notification(admin_request)
    @admin_request = admin_request
    @user = admin_request.user

    mail(
      to: @user.email,
      subject: '【MM-App】ユーザー登録申請について'
    )
  end
end
