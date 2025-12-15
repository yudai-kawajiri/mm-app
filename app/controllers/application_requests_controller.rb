# frozen_string_literal: true

class ApplicationRequestsController < ApplicationController
  layout 'application'  # ナビゲーションバーなしのレイアウトを明示的に指定
  
  before_action :find_application_request_by_token, only: [:accept, :accept_confirm]

  def new
    @application_request = ApplicationRequest.new
  end

  def create
    @application_request = ApplicationRequest.new(application_request_params)
    @application_request.status = :pending

    if @application_request.save
      ApplicationRequestMailer.invitation_email(@application_request).deliver_later
      redirect_to root_path, notice: t('application_requests.create.notice')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def accept
    return redirect_to root_path, alert: t('application_requests.accept.errors.invalid_token') unless @application_request&.acceptable?
    return redirect_to root_path, alert: t('application_requests.accept.errors.expired') if @application_request.expired?
  end

  def accept_confirm
    return redirect_to root_path, alert: t('application_requests.accept.errors.invalid_token') unless @application_request&.acceptable?

    ActiveRecord::Base.transaction do
      subdomain = generate_subdomain(@application_request.company_name)
      
      tenant = Tenant.create!(
        name: @application_request.company_name,
        subdomain: subdomain,
        company_email: @application_request.company_email,
        company_phone: @application_request.company_phone
      )

      store = tenant.stores.create!(
        name: "#{@application_request.company_name}本店",
        code: '001'
      )

      user = User.create!(
        name: @application_request.admin_name,
        email: @application_request.admin_email,
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        tenant: tenant,
        store: store,
        role: :company_admin,
        approved: true
      )

      @application_request.update!(
        tenant: tenant,
        status: :completed
      )

      sign_in(user)
      
      redirect_to authenticated_root_url(subdomain: subdomain), 
                  notice: t('application_requests.accept.messages.registration_complete'),
                  allow_other_host: true
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("ApplicationRequest accept_confirm failed: #{e.message}")
    flash.now[:alert] = t('application_requests.accept.errors.registration_failed')
    render :accept, status: :unprocessable_entity
  end

  private

  def application_request_params
    params.require(:application_request).permit(
      :company_name,
      :company_email,
      :company_phone,
      :admin_name,
      :admin_email
    )
  end

  def find_application_request_by_token
    @application_request = ApplicationRequest.find_by(invitation_token: params[:token])
  end

  def generate_subdomain(company_name)
    base = company_name.gsub(/[^a-zA-Z0-9]/, '-').downcase[0..10]
    subdomain = base
    counter = 1

    while Tenant.exists?(subdomain: subdomain)
      subdomain = "#{base}-#{counter}"
      counter += 1
    end

    subdomain
  end
end
