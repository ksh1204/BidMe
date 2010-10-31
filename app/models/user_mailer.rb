class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "http://localhost:3000/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://localhost:3000/"
  end
  
  def reset_notification(user)
    setup_email(user)
    @subject    += 'Link to reset your password'
    @body[:url]  = "http://localhost:3000/reset/#{user.reset_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://localhost:3000/"
  end
  
  def ban_notification(user)
    setup_email(user)
    @subject += 'You have been banned!'
    @body = "If you want to be unbanned, please send an email to BidMe Administrator bidme410@gmail.com"
  end
  
  def unban_notification(user)
    setup_email(user)
    @subject += 'You have been unbanned!'
    @body = "Congratulations! You just have been unbanned!"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "BidMe"
      @subject     = "[BidMe] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
