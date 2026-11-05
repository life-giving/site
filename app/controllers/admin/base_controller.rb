module Admin
  class BaseController < ApplicationController
    TOKEN_COOKIE = :admin_token
    TOKEN_PATH = "/admin"
    # Room for the multipart envelope around the files themselves.
    MULTIPART_OVERHEAD = 1.megabyte

    layout "admin"
    helper_method :upload_limit

    before_action :authenticate!

    private

    # The backoffice is Ukrainian only, whatever language the visitor chose for the site.
    def request_locale
      I18n.default_locale
    end

    def authenticate!
      @current_admin = JwtToken.admin_from(cookies[TOKEN_COOKIE])
      redirect_to new_admin_session_path, status: :see_other unless @current_admin
    end

    def upload_limit(key)
      Rails.configuration.x.uploads.fetch(key).to_i
    end

    # Gives a friendly answer to a request too large to be valid, without creating any records.
    # The disk is protected earlier: Rack has read the body by now, so that is Puma's job (config/puma.rb).
    def limit_request_body(limit_key, redirect_path, files: 1)
      max_mb = upload_limit(limit_key)
      return if request.content_length.to_i <= (max_mb * files).megabytes + MULTIPART_OVERHEAD

      redirect_to redirect_path, alert: I18n.t("errors.messages.too_large", max_mb: max_mb), status: :see_other
    end

    def error_status(record)
      record.errors.of_kind?(:file, :too_large) ? :content_too_large : :unprocessable_content
    end
  end
end
