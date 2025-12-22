class ApplicationRequestsController < ApplicationController
  layout "application"
  before_action :find_application_request_by_token, only: [ :accept, :accept_confirm ]
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def new
    @application_request = ApplicationRequest.new
  end

  def create
    @application_request = ApplicationRequest.new(application_request_params)

    if @application_request.save
      @application_request.generate_invitation_token!
      ApplicationRequestMailer.invitation_email(@application_request).deliver_later
      redirect_to thanks_application_requests_path, notice: t("application_requests.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
  end

  def accept
  end

  def accept_confirm
    ActiveRecord::Base.transaction do
      slug = generate_unique_slug(@application_request.company_name)

      company = Company.create!(
        name: @application_request.company_name,
        slug: slug,
        active: true
      )

      user = User.create!(
        email: @application_request.contact_email,
        password: params[:application_request][:password],
        password_confirmation: params[:application_request][:password_confirmation],
        name: @application_request.contact_name,
        company: company,
        role: :company_admin,
        approved: true
      )

      @application_request.update!(status: :accepted, user: user)

      redirect_to new_user_session_path,
        notice: t("application_requests.accept_confirm.success")
    end
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = t("application_requests.accept_confirm.failure", error: e.record.errors.full_messages.join(", "))
    render :accept, status: :unprocessable_entity
  end

  private

  def application_request_params
    params.require(:application_request).permit(
      :company_name,
      :company_email,
      :company_phone,
      :contact_name,
      :contact_email
    )
  end

  def find_application_request_by_token
    @application_request = ApplicationRequest.find_by!(invitation_token: params[:token])
  end

  def generate_unique_slug(company_name)
    base = company_name.to_s.gsub(/[^a-zA-Z0-9]/, "").downcase[0..20]
    base = "company" if base.blank?

    slug = base
    counter = 0

    while Company.exists?(slug: slug)
      counter += 1
      slug = "#{base}-#{counter}"
    end
    slug
  end
end
