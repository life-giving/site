module Admin
  class SessionsController < BaseController
    # Its own store: the app has no shared cache, and the null store would disable the limit.
    RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

    skip_before_action :authenticate!
    rate_limit to: 5, within: 1.minute, only: :create, name: "ip", store: RATE_LIMIT_STORE, with: :too_many_attempts
    rate_limit to: 10, within: 15.minutes, only: :create, name: "email", store: RATE_LIMIT_STORE, with: :too_many_attempts,
               by: -> { params[:email].to_s.strip.downcase }

    def new
    end

    def create
      admin = AdminUser.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)
      return reject(t("admin.session.invalid"), :unprocessable_content) unless admin

      cookies[TOKEN_COOKIE] = {
        value: JwtToken.encode(admin),
        expires: JwtToken::TTL.from_now,
        path: TOKEN_PATH,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :strict
      }
      redirect_to admin_news_index_path, status: :see_other
    end

    def destroy
      cookies.delete(TOKEN_COOKIE, path: TOKEN_PATH)
      redirect_to new_admin_session_path, status: :see_other
    end

    private

    def too_many_attempts
      reject(t("admin.session.too_many"), :too_many_requests)
    end

    def reject(message, status)
      flash.now[:alert] = message
      render :new, status: status
    end
  end
end
