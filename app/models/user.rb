require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  has_many :user_items
  has_many :posted_items, :through => :user_items, :source => :item

  
  has_many :bids, :foreign_key => "bidder_id"
  has_many :bidded_items, :through => :bids, :source => :item
  
  has_many :bought_transactions, :class_name => "Transaction", :foreign_key => "buyer_id"
  has_many :bought_items, :through => :bought_transactions, :foreign_key => "item_id"
  has_many :sold_transactions, :class_name => "Transaction", :foreign_key => "seller_id"
  has_many :sold_items, :through => :sold_transactions, :foreign_key => "item_id"
  
  has_many :watches, :foreign_key => "watcher_id"
  has_many :watched_items, :through => :watches
  
  ajaxful_rateable :dimensions => [:quality]
  ajaxful_rater

  has_many :user_comments, :foreign_key => "commentee_id"
  has_many :commentees, :through => :user_comments
  
  has_many :sent_messages, :class_name => "Message", :foreign_key => "sender_id"
  has_many :receivers, :through => :sent_messages
  has_many :received_messages, :class_name => "Message", :foreign_key => "receiver_id"
  has_many :senders, :through => :received_messages, :source => :user
  
  has_many :follow_followers, :class_name => "Follow", :foreign_key => "following_id"
  has_many :followers, :through => :follow_followers
  has_many :follow_followings, :class_name => "Follow", :foreign_key => "follower_id"
  has_many :followings, :through => :follow_followings
  

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..10
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :first_name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :first_name,     :maximum => 20
  
  validates_format_of       :last_name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :last_name,     :maximum => 20

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..50 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  before_create :make_activation_code 
  
  has_attached_file :profile_photo,
  :styles => {
    :thumb=> "50x50#",
    :small  => "200x126>",
    :medium => "300x300>",
    :large =>   "400x400>" }

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :first_name, :last_name, :address, :phone, :password, :password_confirmation, :profile_photo, :logged_in, :last_ip, :money


  # Activates the user in the database.
  def activate!
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  def is_admin?
    self.is_admin
  end 
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end
  
  def create_reset_code
      @reset = true
      self.update_attribute(:reset_code, Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join ))
      #logger.debug self.reset_code
      #save(false)
    end 

  def recently_reset?
    @reset
  end 
    
  def delete_reset_code
    self.update_attribute(:reset_code, nil)
    #save(false)
  end
  
  def make_message_notification(sender)
    #flash[:new_message] = "You have received a new message from #{sender.login}"
  end


  protected
    
    def make_activation_code
        self.activation_code = self.class.make_token
    end
 
  
end
