namespace :admin do
  desc "Create a backoffice user: bin/rails admin:create EMAIL=name@example.org (prompts for the password)"
  task create: :environment do
    require "io/console"

    email = ENV.fetch("EMAIL") { abort "Set EMAIL, e.g. bin/rails admin:create EMAIL=name@example.org" }
    password = ENV["PASSWORD"] || $stdin.getpass("Password (12+ characters): ")

    admin = AdminUser.new(email: email, password: password)
    abort admin.errors.full_messages.join("\n") unless admin.save
    puts "Created admin #{admin.email}"
  end

  desc "Change a password, which also ends that admin's sessions: bin/rails admin:password EMAIL=name@example.org"
  task password: :environment do
    require "io/console"

    admin = AdminUser.find_by(email: ENV.fetch("EMAIL") { abort "Set EMAIL" }) || abort("No admin with that email")
    admin.password = ENV["PASSWORD"] || $stdin.getpass("New password (12+ characters): ")
    abort admin.errors.full_messages.join("\n") unless admin.save
    puts "Password changed for #{admin.email}; existing sessions have ended"
  end
end
