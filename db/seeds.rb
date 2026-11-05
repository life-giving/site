# Runs on every new database, including production (bin/rails db:prepare), so it must stay idempotent.

REPORTS = [
  [ "statut.pdf", "Статут організації", "Organisation statute" ],
  [ "data-protection-policy.pdf", "Політика захисту даних", "Data protection policy" ],
  [ "psea-policy.pdf", "Політика запобігання сексуальній експлуатації та насильству (PSEA)",
    "Policy on Protection from Sexual Exploitation and Abuse (PSEA)" ],
  [ "gender-equality-policy.pdf", "Політика гендерної рівності та інклюзії", "Gender Equality and Inclusion Policy" ]
].freeze

REPORTS.each do |filename, title_uk, title_en|
  next if Report.exists?(title_uk: title_uk)

  File.open(Rails.root.join("db/seed_files/reports", filename)) do |io|
    Report.create!(title_uk: title_uk, title_en: title_en,
                   file: { io: io, filename: filename, content_type: "application/pdf" })
  end
end

if Rails.env.development? && NewsItem.none?
  body_one = <<~MARKDOWN
    Lorem ipsum dolor sit amet, **consectetur adipiscing** elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

    - ut enim ad minim veniam
    - quis nostrud exercitation
    - ullamco laboris nisi ut aliquip

    Duis aute irure dolor in [reprehenderit](https://example.com) in voluptate velit esse cillum dolore.
  MARKDOWN
  body_two = "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui **officia deserunt** mollit anim id est laborum."

  item = NewsItem.create!(date: "2026-10-20", title_uk: "Lorem ipsum dolor sit amet", title_en: "Lorem ipsum dolor sit amet",
                          body_uk: body_one, body_en: body_one)
  { "Lorem ipsum 1" => "logo-vertical.png", "Lorem ipsum 2" => "logo-horizontal.png" }.each do |caption, filename|
    File.open(Rails.root.join("app/assets/images", filename)) do |io|
      item.images.create!(caption: caption, file: { io: io, filename: filename, content_type: "image/png" })
    end
  end

  NewsItem.create!(date: "2026-10-01", title_uk: "Consectetur adipiscing elit", title_en: "Consectetur adipiscing elit",
                   body_uk: body_two, body_en: body_two)
end
