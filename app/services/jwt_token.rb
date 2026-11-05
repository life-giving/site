# Backoffice session token, kept in an HttpOnly cookie (see Admin::SessionsController).
class JwtToken
  ALGORITHM = "HS256"
  TTL = 12.hours

  class << self
    def encode(admin)
      JWT.encode({ sub: admin.id.to_s, ver: password_version(admin), exp: TTL.from_now.to_i }, key, ALGORITHM)
    end

    # Returns the claims, or nil for a missing, tampered or expired token.
    def decode(token)
      JWT.decode(token, key, true, algorithm: ALGORITHM, required_claims: %w[sub ver exp]).first
    rescue JWT::DecodeError
      nil
    end

    # The admin a token belongs to, unless their password has changed since it was issued.
    def admin_from(token)
      claims = decode(token)
      admin = AdminUser.find_by(id: claims["sub"]) if claims
      admin if admin && ActiveSupport::SecurityUtils.secure_compare(claims["ver"].to_s, password_version(admin))
    end

    private

    def key
      @key ||= Rails.application.key_generator.generate_key("admin session jwt", 32)
    end

    # Changes with the password. Hashed because JWT claims are readable by whoever holds the token.
    def password_version(admin)
      OpenSSL::HMAC.hexdigest("SHA256", key, admin.password_salt)
    end
  end
end
