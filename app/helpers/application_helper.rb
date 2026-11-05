module ApplicationHelper
  PHONE = "+380 96 119 50 47"
  EMAIL = "life_giving@ukr.net"
  INSTAGRAM_URL = "https://www.instagram.com/life_giving24/"
  INSTAGRAM_HANDLE = "@life_giving24"

  def icon(name)
    tag.svg(class: "icon", aria: { hidden: true }) { tag.use(href: "#{image_path("icons.svg")}#i-#{name}") }
  end

  def phone_link(**options)
    link_to PHONE, "tel:#{PHONE.delete(" ")}", **options
  end

  def email_link
    mail_to EMAIL
  end

  def report_size(report)
    t("site.transparency.size", size: size_in_mb(report))
  end

  def size_in_mb(report)
    number_with_precision(report.file.blob.byte_size / 1.megabyte.to_f, precision: 1, delimiter: "")
  end
end
