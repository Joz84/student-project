# if Rails.env.production? || Rails.env.staging?
if Rails.env.staging?
  require "email_interceptor"
  ActionMailer::Base.register_interceptor(EmailInterceptor)
end
