class ApplicationMailer < ActionMailer::Base
  # L'expéditeur appartient au domaine que Brevo authentifie ; les réponses des
  # étudiants doivent malgré tout arriver sur l'adresse universitaire.
  default from: ENV.fetch("MAILER_SENDER", "no-reply@upf-project.com"),
          reply_to: ENV.fetch("MAILER_REPLY_TO", "jonathan.serafini@upf.pf")
  layout "mailer"
end
