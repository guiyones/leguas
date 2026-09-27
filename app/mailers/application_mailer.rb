class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Léguas <nao-responda@leguas.localhost>")
  layout "mailer"
end
