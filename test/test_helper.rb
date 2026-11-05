ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

module ApiTestHelpers
  PDF_BYTES = "%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF\n"
  # 1x1 transparent PNG
  PNG_BYTES = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=".unpack1("m0")
  SVG_BYTES = %(<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>)
  PASSWORD = "correct-horse-battery"

  def json
    JSON.parse(response.body)
  end

  def upload(content, filename, content_type)
    file = Tempfile.new([ "upload", File.extname(filename) ], binmode: true)
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
  end

  def create_admin
    AdminUser.create!(email: "admin@example.org", password: PASSWORD)
  end

  def log_in(admin = create_admin)
    post "/admin/session", params: { email: admin.email, password: PASSWORD }
    assert_redirected_to "/admin/news"
    admin
  end

  def create_report(title: "Звіт")
    Report.create!(title_uk: title, file: { io: StringIO.new(PDF_BYTES), filename: "report.pdf" })
  end

  def create_image(item, caption: nil)
    item.images.create!(caption: caption, file: { io: StringIO.new(PNG_BYTES), filename: "photo.png" })
  end

  def with_upload_limit(key, megabytes)
    uploads = Rails.configuration.x.uploads
    original = uploads[key]
    uploads[key] = megabytes
    yield
  ensure
    uploads[key] = original
  end
end

class ActionDispatch::IntegrationTest
  include ApiTestHelpers

  setup { Admin::SessionsController::RATE_LIMIT_STORE.clear }
end
