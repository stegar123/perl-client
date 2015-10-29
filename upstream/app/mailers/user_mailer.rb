class UserMailer < ActionMailer::Base
  default from: "fingerbank@inverse.ca"
  default to: "support@inverse.ca"

  def request_api_submission(user)
    @user = user
    mail(subject: "Request to submit to the fingerbank API")
  end

  def user_blocked(user)
    @user = user
    mail(to: @user.email, reply_to: "support@inverse.ca", subject: "Your fingerbank account has been blocked.")
  end

  def hourly_limit_reached(user)
    @user = user
    now = Time.now
    warned_at = Rails.cache.fetch("mail-#{user.name}-hourly-limit-reached", :expires_in => 1.hour) {Time.now}
    if warned_at > now
      mail(to: @user.email, reply_to: "support@inverse.ca", subject: "You have reached your hourly API limit")
    end
  end

  def pending_combination_declined(pending_combination, reason)
    @pending_combination = pending_combination
    @user = @pending_combination.owner
    @reason = reason
    mail(to: @user.email, reply_to: "support@inverse.ca", subject: "Fingerbank - Recategorization request declined")
  end

  def pending_combination_approved(pending_combination)
    @pending_combination = pending_combination
    @user = @pending_combination.owner
    mail(to: @user.email, reply_to: "support@inverse.ca", subject: "Fingerbank - Recategorization request approved")
  end

end
