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
        redirect_to :action => 'profile', :username => current_user.login
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
  
  def add_money
    @user = current_user
	@money = @user.money
	@allowed = @user.money_refill
	if @allowed > 0
		@user.money = @money + 1000
		@user.money_refill = @allowed - 1
		@user.save
		gflash :success => "Money Successfully Transferred to your account!"
		redirect_to :action => 'profile', :username => @user.login
	else
		gflash :error => "You have depleted your money reserve."
		redirect_to :action => 'profile', :username => @user.login
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
        redirect_to :action => 'messagebox'
      else
        gflash :error => "Message could not be sent!"
        redirect_to :action => 'write_message'
      end
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
        redirect_back_or_default('/messagebox')
      end
    end
    
    def show_sent_message
      @message = Message.find(params[:id])
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
      if current_user.id == @message.sender.id
        render :action => 'show_sent_message'
      else
        gflash :error => "Unknown request."
        redirect_back_or_default('/sent_messages')
      end
    end
 
 def about
	@user = current_user
 end    

 def rate
    @user = User.find(params[:id])
    @user.rate(params[:stars], current_user, params[:dimension])
    render :update do |page|
      page.replace_html @user.wrapper_dom_id(params), ratings_for(@user, params.merge(:wrap => false))
      page.visual_effect :highlight, @user.wrapper_dom_id(params)
    end
  end

    def profile
      @user = User.find_by_login(params[:username])
	  @bids = Bid.find_all_by_bidder_id(@user.id, :group => 'item_id')
	  @comments = @user.user_comments
		  respond_to do |format|
		    format.html
        format.js { render_to_facebox }
      @user_items = current_user.user_items
      end

      
    end


	def small_profile
      @user = User.find_by_login(params[:username])
	@comments = @user.user_comments
		  respond_to do |format|
		    format.html
        format.js { render_to_facebox }
      @user_items = current_user.user_items
      end
	end
    
    def remove_profile_photo
      @user = current_user
      @user.update_attribute(:profile_photo_file_name, nil)
    end
    
    def report_user
      @reporter = current_user
      @reportee = User.find_by_login(params[:username])
      if @reporter.id == @reportee.id
        gflash :error => "Unknown request!"
        redirect_back_or_default('/')
      end
      @admin = User.find_by_login('admin')
      @message = @reporter.sent_messages.build(:receiver_id => @admin.id, :description => "<a href='/profile/#{@reporter.login}'>#{@reporter.login}</a> has reported <a href='/profile/#{@reporter.login}'>#{@reportee.login}</a>! Do something about it!")
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
      if @follower.id == @following.id
        gflash :error => "Invalid request!"
        redirect_back_or_default('/')
      end
      exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})
      if !exist
        @follow = @follower.follow_followings.build(:following_id => @following.id)
        @follow.save
        @message = @follower.sent_messages.build(:receiver_id => @following.id, :description => "You have a new follower! A user with the name of <a href='/profile/#{@follower.login}'>#{@follower.login}</a> is now following you!")
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
      if @follower.id == @following.id
        gflash :error => "Unknown request!"
        redirect_back_or_default('/')
      end
      exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})
      if exist
        exist.destroy
        gflash :success => "You are no longer following #{@following.login}!"
      else
        gflash :error => "You are already not following #{@following.login}!"
      end
      redirect_to :action => 'profile', :username => @following.login
    end

	def watch_item
		@watcher = current_user
		@item = Item.find(params[:id])
		exist = Watch.find(:first, :conditions => {:watcher_id => @watcher.id, :item_id => @item.id})
		if !exist && !@item.closed
		@watch = @watcher.watches.build(:watcher_id => @watcher.id, :item_id => @item.id)
		@watch.save
		gflash :success => "You are now watching #{@item.name}!"
		elsif @item.closed
			gflash :error => "Can not watch this auction!"
		else
			gflash :error => "You are already watching #{@item.name}!"
		end
		redirect_to :controller => 'items', :action => 'show', :id => @item.id
	end
    
    def unwatch_item
      @watcher = current_user
      @watching = Item.find(params[:id]) 
      exist = Watch.find(:first, :conditions => {:watcher_id => @watcher.id, :item_id => @watching.id})
      if exist
        exist.destroy
        gflash :success => "You are no longer watching #{@watching.name}!"
      else
        gflash :error => "You are already not following #{@watching.name}!"
      end
      redirect_to :controller => 'items', :action => 'show', :id => @watching.id	
    end


    def show_user_items
      @user_items = UserItem.paginate :per_page => 8, :page => params[:page], :conditions => { :user_id => current_user.id }, :order => 'created_at DESC'
      @sold = Transaction.find_all_by_seller_id(current_user.id)
      @bought = Transaction.find_all_by_buyer_id(current_user.id)
      @following = Follow.find_all_by_follower_id(current_user.id)
      @watched = Watch.find_all_by_watcher_id(current_user.id)
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
		  money = @user.money
		 
		  if @item.closed
		    gflash :error => "This auction is closed."
		    redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		  elsif !price
  		  gflash :error => "Price cannot be empty"
  		  redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		  else
		    
		  if (@bids.count > 0)                   
		    @highest = @bids.first
		    if price.to_f <= @highest.price
		      gflash :error => "Bid price must be greater than the current price of the item!"
		      redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		    elsif (@bids.first.bidder.id == current_user.id)
			gflash :error => "Cannot outbid yourself!"
			redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		    elsif (money < price.to_f)
			gflash :error => "You cannot afford to pay this"
			redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
		    else			
    		  @highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
    		  @highest_bid.save
		  @user.money = @user.money - price.to_f
		  @user.save
    		  gflash :success => "Bid success. You are now the highest bidder!"
    		  render :juggernaut => {:type => :send_to_all} do |page|
            page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "highest_bid", :duration => 5
            page.replace_html "search_page_#{@item.id}", :partial => 'items/searched_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "search_page_#{@item.id}", :duration => 5
          end
          if @highest.bidder.id != @highest_bid.bidder.id
            @message = @admin.sent_messages.build(:receiver_id => @highest.bidder.id, :description => "You have been OUTBIDDED by <a href='/profile/#{@highest_bid.bidder.login}'>#{@highest_bid.bidder.login}</a> for <a href='items/show/#{@highest_bid.item.id}'>#{@highest_bid.item.name}</a>")
            @message.save	
            @hbidder = User.find(@highest.bidder.id)
            @hbidder.money = @hbidder.money + @highest.price
            @hbidder.save 
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
          redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
	elsif money < price.to_f
	   gflash :error => "Cannot afford to bid with that price!"
           redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
        else
          @highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
          @highest_bid.save
          @user.money = @user.money - price.to_f
	  @user.save
    		  gflash :success => "Bid success. You are now the highest bidder!"
    		  render :juggernaut => {:type => :send_to_all } do |page|
            page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "highest_bid", :duration => 5
            page.replace_html "search_page_#{@item.id}", :partial => 'items/searched_bid_price', :object => @highest_bid
            page.visual_effect :highlight, "search_page_#{@item.id}", :duration => 5
          end
        end
        redirect_to :controller => "items", :action => 'show', :id => params[:item_id]
      end
		end
	end
	
	def buy_it_now
    @item = Item.find(params[:id])
    if @item.closed
      gflash :error => "Unknown action"
    else
      if current_user == @item.user
        gflash :error => "You cannot buy your own item!"
      elsif current_user.money >= @item.bin_price
        if @item.bids.first
          @highest_bid = @item.bids.sort_by{|b| b.price}.last
          highest_bidder = @highest_bid.bidder
          highest_bidder.update_attribute(:money, highest_bidder.money+@highest_bid.price)
        end
        gflash :success => "Congratulations! You have bought the item."
        @item.closed = true
        render :juggernaut => {:type => :send_to_all} do |page|
              page.replace_html :show_item_time, ""
              page.replace_html :bid_id, ""
              page.replace_html :highest_bid, "Auction is closed!"
              page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
              page.visual_effect :highlight, "item_time_#{@item.id}", :duration => 5
        end
        @item.update_attribute(:closed,true)
        poster = @item.user
        poster.update_attribute(:money, poster.money+@item.bin_price)
        current_user.update_attribute(:money,current_user.money-@item.bin_price)
      else
        gflash :error => "Cannot afford to buy this item"
      end
    end
    redirect_to :controller => 'items', :action => 'show', id => params[:id]
  end
  
  def list_followers
    @user = User.find_by_login(params[:username])
  end

end



 
