class ApplicationRequestMailer < ApplicationMailer
  def invitation_email(application_request, company_slug)
    @application_request = application_request
    @admin_name = application_request.admin_name
    @admin_email = application_request.admin_email
    @company_slug = company_slug
    @temporary_password = application_request.temporary_password
    @invitation_url = accept_application_requests_url(
      token: application_request.invitation_token,
      host: ENV.fetch("APP_HOST", "localhost:3000"),
      protocol: ENV.fetch("APP_PROTOCOL", "http")
    )

    mail(
      to: application_request.admin_email,
      subject: t("application_request_mailer.invitation_email.subject")
    )
  end

  def approval_notification(admin_request)
    @admin_request = admin_request
    @user = admin_request.user
    @company_slug = admin_request.company.slug
    @login_url = company_new_user_session_url(
      company_slug: @company_slug,
      host: ENV.fetch("APP_HOST", "localhost:3000"),
      protocol: ENV.fetch("APP_PROTOCOL", "http")
    )

    mail(
      to: @user.email,
      subject: t("application_request_mailer.approval_notification.subject")
    )
  end

  def rejection_notification(admin_request)
    @admin_request = admin_request
    @user = admin_request.user

    mail(
      to: @user.email,
      subject: t("application_request_mailer.rejection_notification.subject")
    )
  end
end
