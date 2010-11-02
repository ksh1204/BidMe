class UsersController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  before_filter :login_required, :except => [:new, :create, :activate, :forgot, :reset]

  # render new.rhtml
  def new
    @user = User.new
  end
  
  def home
    @user = current_user
  end
  
  def edit
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      gflash :success => "Thanks for signing up!  We're sending you an email with your activation code."
    else
      gflash :error  => "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      gflash :success => "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      gflash :error => "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      gflash :error  => "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
  
  def update
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    if @user.update_attributes(params[:user])
      gflash :success => "Profile Successfully Updated"
      if current_user.is_admin?
        redirect_to :action => 'list'
      else
        redirect_to :action => 'home'
      end
    else
      render :action => 'edit', :id => params[:id]
    end
  end
  
  def update_password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    if @user.update_attributes(params[:user])
      gflash :success => "Password Successfully Updated"
      redirect_to :action => 'edit', :id => @user.id
    else
      render :action => 'change_password', :id => params[:id]
    end
  end
  
  def change_password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end
  
  def forgot
      if request.post?
        user = User.find_by_email(params[:user][:email])
        if user
          user.create_reset_code
          gflash :success => "Reset code sent to #{user.email}"
        else
          gflash :success => "#{params[:user][:email]} does not exist in system"
        end
        redirect_back_or_default('/')
      end
    end

    def reset
      @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
      if request.post?
        if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
          self.current_user = @user
          @user.delete_reset_code
          gflash :success => "Password reset successfully for #{@user.email}"
          redirect_back_or_default('/')
        else
          render :action => :reset
        end
      end
    end

    def list
      @users = User.find(:all)
    end

    def destroy
      @user = User.find(params[:id])
      unless @user.destroy
        gflash :error => "Error Deleting User"
        redirect_to :action => 'list'
      end
    end
    
    def send_message
      @user = current_user
      @receiver = User.find_by_login(params[:receiver])
      if @receiver
        @message = @user.sent_messages.build(:receiver_id => @receiver.id, :description => params[:description])
        @message.save
        @unread_messages = Message.find(:all, :conditions => {:receiver_id => @receiver.id, :unread => true})
        @num_unread = @unread_messages.count
        render :juggernaut => {:type => :send_to_client, :client_id => @receiver.id} do |page|
          page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
          page.visual_effect :fade, :no_message, :duration => 2
          page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
          page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
          page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
        end
        gflash :progress => "Your message is being sent"
      end
      
      redirect_to :action => 'messagebox'
    end
    
    def write_message
      @user = current_user
      @message = Message.new
      @message.sender = current_user
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
      if params[:receiver]
        @message.receiver = User.find_by_login(params[:receiver])
      end
    end
    
    def messagebox
      @user = current_user
      @messages = Message.paginate_by_receiver_id @user.id, :page => params[:page], :order => 'created_at DESC', :per_page => 10
      #@messages = @user.received_messages.sort_by{|m| m.created_at}.reverse
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
    end
    
    def sent_messages
      @user = current_user
      @sent_messages = @user.sent_messages.sort_by{|m| m.created_at}.reverse
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
    end
    
    def show_message
      @message = Message.find(params[:id])
      @message.update_attribute(:unread,false)
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
      if current_user.id == @message.receiver.id
        render :action => 'show_message'
      else
        gflash :error => "Unknown request."
        redirect_back_or_default('/')
      end
    end
    
    def show_sent_message
      @message = Message.find(params[:id])
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
      if current_user.id == @message.sender.id
        render :action => 'show_sent_message'
      else
        gflash :error => "Unknown request."
        redirect_back_or_default('/')
      end
    end
    
    def profile
      @user = User.find_by_login(params[:username])
		  @comments = @user.user_comments
		  respond_to do |format|
		    format.html
        format.js { render_to_facebox }
      end
      
    end
    
    def remove_profile_photo
      @user = current_user
      @user.update_attribute(:profile_photo_file_name, nil)
    end
    
    def report_user
      @reporter = current_user
      @reportee = User.find_by_login(params[:username])
      @admin = User.find_by_login('admin')
      @message = @reporter.sent_messages.build(:receiver_id => @admin.id, :description => "#{@reporter.login} has reported #{@reportee.login}! Do something about it!")
      @message.save
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => @admin.id, :unread => true})
      @num_unread = @unread_messages.count
      render :juggernaut => {:type => :send_to_client, :client_id => @admin.id} do |page|
        page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
        page.visual_effect :fade, :no_message, :duration => 2
        page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
        page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
        page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
      end
      gflash :progress => "Your report is being sent to Administrator"
      redirect_to :action => 'profile', :username => @reportee.login
    end
    
    def follow_user
      @follower = current_user
      @following = User.find_by_login(params[:username])
      @user = @following
      exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})
      if !exist
        @follow = @follower.follow_followings.build(:following_id => @following.id)
        @follow.save
        @message = @follower.sent_messages.build(:receiver_id => @following.id, :description => "#{@follower.login} is following you!")
        @message.save
        @unread_messages = Message.find(:all, :conditions => {:receiver_id => @following.id, :unread => true})
        @num_unread = @unread_messages.count
        render :juggernaut => {:type => :send_to_client, :client_id => @following.id} do |page|
          page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
          page.visual_effect :fade, :no_message, :duration => 2
          page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
          page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
          page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
        end
        gflash :success => "You are now following #{@following.login}!"
      else
        gflash :error => "You are already following #{@following.login}!"
      end
      redirect_to :action => 'profile', :username => @following.login
    end
    
    def unfollow_user
      @follower = current_user
      @following = User.find_by_login(params[:username])
      @user = @following
      exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})
      if exist
        exist.destroy
        gflash :success => "You are no longer following #{@following.login}!"
      else
        gflash :error => "You are already not following #{@following.login}!"
      end
      redirect_to :action => 'profile', :username => @following.login
    end

		def write_comment
			@user = current_user
			@commentee = User.find(params[:commentee_id])
			if !(params[:description] == "")
			  @comment = UserComment.new(:user_id => @user.id,
																   :commentee_id => params[:commentee_id],
																   :description => params[:description] )
			  @comment.save
			end
			redirect_to :action => 'profile', :username => @commentee.login
		end
		
		def bid
		  @user = current_user
		  @bids = Bid.find(:all, :conditions => {:item_id => params[:item_id]}, :order => "price DESC")
		  @item = Item.find(params[:item_id])
		  @admin = User.find_by_login("admin")
		  price = params[:bid_price]
		  if !price
		    gflash :error => "Price cannot be empty"
		    redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		  elsif @item.closed
		    gflash :error => "This auction is closed."
		    redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		  end
		    
		  if @bids.count > 0
		    @highest = @bids.first
		    if price.to_f <= @highest.price
		      gflash :error => "Bid price must be greater than the current price of the item!"
		      redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		    else
    		  @highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
    		  @highest_bid.save
    		  gflash :success => "Bid success. You are now the highest bidder!"
    		  render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "highest_bid", :duration => 5
          end
          if @highest.bidder.id != @highest_bid.bidder.id
            @message = @admin.sent_messages.build(:receiver_id => @highest.bidder.id, :description => "You have been OUTBIDDED by #{@highest_bid.bidder.login} for <a href='items/show/#{@highest_bid.item.id}'>#{@highest_bid.item.name}</a>")
            @message.save
            @unread_messages = Message.find(:all, :conditions => {:receiver_id => @highest.bidder.id, :unread => true})
            @num_unread = @unread_messages.count
            render :juggernaut => {:type => :send_to_client, :client_id => @highest.bidder.id} do |page|
              page.insert_html :top, :main_content, :partial => 'base/outbidded_message', :object => @highest_bid
              page.visual_effect :fade, :no_message, :duration => 2
              page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
              page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
              page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
            end
          end
          redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
        end
      else
        if price.to_f <= @item.start_price
          gflash :error => "Bid price must be greater than the current price of the item!"
        else
          @highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
          @highest_bid.save
          @highest_bid.save
    		  gflash :success => "Bid success. You are now the highest bidder!"
    		  render :juggernaut => {:type => :send_to_all } do |page|
            page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "highest_bid", :duration => 5
          end
        end
        redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
      end
		end

end
