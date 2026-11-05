# Language order: ?lang=, then the saved cookie, then the browser's language, then the default.
module SetLocale
  extend ActiveSupport::Concern

  LOCALE_COOKIE = :lang

  included do
    around_action :with_request_locale
  end

  private

  def with_request_locale(&action)
    response.headers["Vary"] = "Cookie, Accept-Language"
    expires_now
    I18n.with_locale(request_locale, &action)
  end

  def request_locale
    chosen = supported_locale(params[:lang])
    remember_locale(chosen) if chosen

    chosen ||
      supported_locale(cookies[LOCALE_COOKIE]) ||
      browser_locale ||
      I18n.default_locale
  end

  # First supported language in the header, by quality and then by position.
  def browser_locale
    request.headers["Accept-Language"].to_s.split(",")
      .map { |entry| entry.strip.split(";q=") }
      .map { |tag, quality| [ tag.to_s[0, 2].downcase, quality ? quality.to_f : 1.0 ] }
      .reject { |_tag, quality| quality.zero? }
      .sort_by.with_index { |(_tag, quality), index| [ -quality, index ] }
      .filter_map { |tag, _quality| supported_locale(tag) }
      .first
  end

  def supported_locale(value)
    I18n.available_locales.find { |locale| locale.to_s == value }
  end

  def remember_locale(locale)
    cookies[LOCALE_COOKIE] = { value: locale.to_s, expires: 1.year.from_now, same_site: :lax }
  end
end
