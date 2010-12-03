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

	# Function for edit page
  def edit
		# admin is able to edit any user's page
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

	# Function for creating a new user
  def create
    logout_keeping_session!

		# create a new user with the parameters provided
    @user = User.new(params[:user])
		
		# if creation of @user is successful and if it was written to the database successfully
    success = @user && @user.save
		
		# if success is TRUE and if there were no errors
    if success && @user.errors.empty?
			# redirect back and flash a pop up regarding successful creation 
      redirect_back_or_default('/')
      gflash :success => "Thanks for signing up!  We're sending you an email with your activation code."
    else
			# else display pop up error and redirect back to the page
      gflash :error  => "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

	# Function to activate user's account 
  def activate
    logout_keeping_session!
		# retrieve the user with the activation code specified
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
			# case when not activated and the code was valid, activate user
      user.activate!
			# display pop up regarding successful activation
      gflash :success => "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
			# when the user input a blank code
      gflash :error => "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
			# user was not found 
      gflash :error  => "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
  
	# Function for updating the user profile
  def update
		# if admin, allow editing user's profile
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end

		# update user profile with regards to the parameters
    if @user.update_attributes(params[:user])
      gflash :success => "Profile Successfully Updated"
      if current_user.is_admin?
				# if admin, go back to the user list
        redirect_to :action => 'list'
      else
				# if normal user, go back to profile page
        redirect_to :action => 'profile', :username => current_user.login
      end
    else
			# update_attributes failed, go back to edit page
      render :action => 'edit', :id => params[:id]
    end
  end
  
	# Function to edit user's password
  def update_password
		# if admin, allow editing user's password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
			# else just use current user
      @user = current_user
    end

		# update user password with regards to the parameters
    if @user.update_attributes(params[:user])
      gflash :success => "Password Successfully Updated"
      redirect_to :action => 'edit', :id => @user.id
    else
      render :action => 'change_password', :id => params[:id]
    end
  end
  
	# Function to change user's password
  def change_password
		# if admin, allow editing user's password
    if current_user.is_admin?
      @user = User.find(params[:id])
    else
      @user = current_user
    end
  end

	# Function to add money to user's account
  def add_money
		# get current user's money
  	@user = current_user
		@money = @user.money
		# get refill limit
		@allowed = @user.money_refill

		# if limit has not been reached, add money to account
		if @allowed > 0
			@user.money = @money + 1000
			@user.money_refill = @allowed - 1
			@user.save
			gflash :success => "Money Successfully Transferred to your account!"
			redirect_to :action => 'profile', :username => @user.login
		else
			# otherwise flash pop up regarding depleted money reserve
			gflash :error => "You have depleted your money reserve."
			redirect_to :action => 'profile', :username => @user.login
		end
  end

	# Function to handle the forgotten password page
  def forgot
		if request.post?
			# find user with email specified
			user = User.find_by_email(params[:user][:email])
			if user
				# if found, send the reset code to the email
      	user.create_reset_code
        gflash :success => "Reset code sent to #{user.email}"
      else
			# else flash pop up regarding error
      gflash :error => "Email does not exist in system"
    	end
    	redirect_back_or_default('/')
    end
	end

	# Function that handles the reset code and resetting the password
	def reset
		# find user using the reset code specified
    @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
      if request.post?
				# update user's password
      	if @user.update_attributes(:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation])
					# delete the code  
	        self.current_user = @user
          @user.delete_reset_code
					# flash notice regarading successfull reset
          gflash :success => "Password reset successfully for #{@user.email}"
          redirect_back_or_default('/')
        else
          render :action => :reset
        end
      end
	end

	# Function for listing all users
  def list
		# retrieve all users
    @users = User.find(:all)
  end

	# Destroy a user
  def destroy
		# find user with specified ID
	  @user = User.find(params[:id])

		# erase @user from database
	  unless @user.destroy
			# if not successful
	    gflash :error => "Error Deleting User"
      redirect_to :action => 'list'
    end
  end
    
	def send_message
		# determine sender and reciever
	  @user = current_user
    @receiver = User.find_by_login(params[:receiver])

		# if reciever exists
    if @receiver
			# create the message with parameters specified
    	@message = @user.sent_messages.build(:receiver_id => @receiver.id, :description => params[:description])
    	@message.save

			# get all unread messages of reciever and count them
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => @receiver.id, :unread => true})
      @num_unread = @unread_messages.count

			# automatically replace the html to show the new message and inbox unread message number for the reciever
			# using ajax so refreshing the page is not necessary
      render :juggernaut => {:type => :send_to_client, :client_id => @receiver.id} do |page|
        page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
        page.visual_effect :fade, :no_message, :duration => 2
        page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
        page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
        page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
      end

			# error in sending, go back to message box
      gflash :progress => "Your message is being sent"
      redirect_to :action => 'messagebox'
    else
			# reciever was not found, error
      gflash :error => "Message could not be sent!"
      redirect_to :action => 'write_message'
    end
  end

	# Write message function for the new message page
	def write_message
		# sender will be the current user
		@user = current_user
		@message = Message.new
		@message.sender = current_user
		@unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
		# if reciever has been specified, automatically use his/her name in the "To:" box
		if params[:receiver]
			@message.receiver = User.find_by_login(params[:receiver])
		end
  end

	# Message box function is used for the message box
  def messagebox
		# retrieve all messages and unread messages of current user
    @user = current_user
    @messages = Message.paginate_by_receiver_id @user.id, :page => params[:page], :order => 'created_at DESC', :per_page => 10
    @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
    end

	# Sent messages function is for the sent message box    
  def sent_messages
    @user = current_user
	  # retrieve all sent messages by the current user
    @sent_messages = @user.sent_messages.sort_by{|m| m.created_at}.reverse
    @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
  end

	# Show messages function is for the show message box 
	def show_message
		# find message with specified ID and set its 'unread' attribute to FALSE
  	@message = Message.find(params[:id])
    @message.update_attribute(:unread,false)
    @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})

		# check if reciever is current user, security  
    if current_user.id == @message.receiver.id
      render :action => 'show_message'
    else
      gflash :error => "Unknown request."
      redirect_back_or_default('/messagebox')
    end
  end
  
	# Show sent messages function is for the show sent message box 
  def show_sent_message
		# find message with specified ID 
    @message = Message.find(params[:id])
    @unread_messages = Message.find(:all, :conditions => {:receiver_id => current_user.id, :unread => true})
    
		# check if reciever is current user, security
		if current_user.id == @message.sender.id
      render :action => 'show_sent_message'
    else
      gflash :error => "Unknown request."
      redirect_back_or_default('/sent_messages')
    end
  end

	# Function for about page
	def about
		@user = current_user
	end    

	# Rate function for handling user ratings
	def rate
		# retrieve user with specified ID and rate him/her 
    @user = User.find(params[:id])
    @user.rate(params[:stars], current_user, params[:dimension])

		# automatically display the new rating
    render :update do |page|
      page.replace_html @user.wrapper_dom_id(params), ratings_for(@user, params.merge(:wrap => false))
      page.visual_effect :highlight, @user.wrapper_dom_id(params)
    end
  end

	# Profile function for the profile page
	def profile
		# determine which user's profile page
		@user = User.find_by_login(params[:username])
		# retrieve all bids by this user
	  @bids = Bid.find_all_by_bidder_id(@user.id, :group => 'item_id')
		# get all comments for this user
	  @comments = @user.user_comments
		# get all user_items by this user
	  @user_items = @user.posted_items

		# code for facebox
	  respond_to do |format|
			format.html
      format.js { render_to_facebox }
    end
	end

	# Function for the small profile page used
	# for facebox
	def small_profile
		# determine which user's profile page
  	@user = User.find_by_login(params[:username])
		# get all comments for this user
	  @comments = @user.user_comments
		# get all user_items by this user
	  @user_items = current_user.user_items
		respond_to do |format|
			format.html
      format.js { render_to_facebox }
    end
	end

	# Remove profile photo    
	def remove_profile_photo
		# user must be current user(cant remove someone else's photo)
	  @user = current_user
		# remove photo
	  @user.update_attribute(:profile_photo_file_name, nil)
  end
    
	# Function to report a user 
  def report_user
		# determine who is being reported and reporter
    @reporter = current_user
    @reportee = User.find_by_login(params[:username])

		# if reporting self, show error pop up
    if @reporter.id == @reportee.id
      gflash :error => "Unknown request!"
      redirect_back_or_default('/')
    end

		# send user to the admin about the report
    @admin = User.find_by_login('admin')
    @message = @reporter.sent_messages.build(:receiver_id => @admin.id, :description => "<a href='/profile/#{@reporter.login}'>#{@reporter.login}</a> has reported <a href='/profile/#{@reporter.login}'>#{@reportee.login}</a>! Do something about it!")
    @message.save

		# automatically replace the html to show the new message and inbox unread message number using ajax so
		# refreshing the page is not necessary, i.e. automatically update number of unread messages in inbox, etc.
    @unread_messages = Message.find(:all, :conditions => {:receiver_id => @admin.id, :unread => true})
    @num_unread = @unread_messages.count
    render :juggernaut => {:type => :send_to_client, :client_id => @admin.id} do |page|
      page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
      page.visual_effect :fade, :no_message, :duration => 2
      page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
      page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
      page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
    end

		# flash pop up to show report success then redirect back
    gflash :progress => "Your report is being sent to Administrator"
    redirect_to :action => 'profile', :username => @reportee.login
  end

	# Function to follow user
  def follow_user
		# determine whos following who
  	@follower = current_user
    @following = User.find_by_login(params[:username])
    @user = @following

		# if trying to follow self, return error
    if @follower.id == @following.id
      gflash :error => "Invalid request!"
      redirect_back_or_default('/')
    end
		
		# see if user is already being followed
    exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})

    if !exist
			# doesnt exist, follow the user
      @follow = @follower.follow_followings.build(:following_id => @following.id)
      @follow.save

			# send message about new follower
      @message = @follower.sent_messages.build(:receiver_id => @following.id, :description => "You have a new follower! A user with the name of <a href='/profile/#{@follower.login}'>#{@follower.login}</a> is now following you!")
      @message.save

			# automatically replace the html to show the new message and inbox unread message number using ajax so
			# refreshing the page is not necessary, i.e. automatically update number of unread messages in inbox, etc.
      @unread_messages = Message.find(:all, :conditions => {:receiver_id => @following.id, :unread => true})
      @num_unread = @unread_messages.count
      render :juggernaut => {:type => :send_to_client, :client_id => @following.id} do |page|
        page.insert_html :top, :main_content, :partial => 'base/new_message', :object => @message
        page.visual_effect :fade, :no_message, :duration => 2
        page.replace :inbox_link, :partial => 'update_inbox_link', :object => @num_unread
        page.insert_html :top, :messages, :partial => 'base/insert_message', :object => @message
        page.visual_effect :highlight, "message_#{@message.id}", :duration => 5
  	  end

			# show pop up regarding follow success
      gflash :success => "You are now following #{@following.login}!"
    else
      gflash :error => "You are already following #{@following.login}!"
    end
    redirect_to :action => 'profile', :username => @following.login
  end

	# Function to handle unfollowing a user    
	def unfollow_user
		# determine who is following who
	  @follower = current_user
    @following = User.find_by_login(params[:username])
    @user = @following

		# if follower was self, unknown
    if @follower.id == @following.id
      gflash :error => "Unknown request!"
      redirect_back_or_default('/')
    end

		# see if user is being followed 	
    exist = Follow.find(:first, :conditions => {:follower_id => @follower.id, :following_id => @following.id})
    if exist
			# if he is, erase from database
      exist.destroy
			# show pop up regarding unfollow success
      gflash :success => "You are no longer following #{@following.login}!"
    else
      gflash :error => "You are already not following #{@following.login}!"
    end
    redirect_to :action => 'profile', :username => @following.login
  end

	# Function to watch an item
	def watch_item
		# determine watcher, item to watch
		@watcher = current_user
		@item = Item.find(params[:id])
		exist = Watch.find(:first, :conditions => {:watcher_id => @watcher.id, :item_id => @item.id})

		# if it exists and is not closed
		if !exist && !@item.closed
			# build the relationship between item and watcher
			@watch = @watcher.watches.build(:watcher_id => @watcher.id, :item_id => @item.id)
			@watch.save
			# show pop up regarding watch success
			gflash :success => "You are now watching #{@item.name}!"
		elsif @item.closed
			gflash :error => "Can not watch this auction!"
		else
			gflash :error => "You are already watching #{@item.name}!"
		end
		redirect_to :controller => 'items', :action => 'show', :id => @item.id
	end
 
	# Function to unwatch an item   
	def unwatch_item
		# determine watcher, item to watch
		@watcher = current_user
    @watching = Item.find(params[:id]) 
    exist = Watch.find(:first, :conditions => {:watcher_id => @watcher.id, :item_id => @watching.id})
		# if it exists
    if exist
			# delete relationship
      exist.destroy
			# show pop up regarding watch success
      gflash :success => "You are no longer watching #{@watching.name}!"
    else
			# show pop up regarding watch error
      gflash :error => "You are already not following #{@watching.name}!"
    end
    redirect_to :controller => 'items', :action => 'show', :id => @watching.id	
  end

	# Function to handle showing user items   
	def show_user_items
		# gather user items of current user
  	@user_items = UserItem.paginate :per_page => 8, :page => params[:page], :conditions => { :user_id => current_user.id }, :order => 'created_at DESC'
		# gather sold items of current user
    @sold = Transaction.find_all_by_seller_id(current_user.id)
		# gather bought items of current user
    @bought = Transaction.find_all_by_buyer_id(current_user.id)
		# gather all users the current user follows
    @following_users = current_user.followings
		# gather items the current user is watching
    @watched = Watch.find_all_by_watcher_id(current_user.id)
  end

	# Function to handle showing posted items
	def show_posted_items_page
  	@user_items = UserItem.paginate :per_page => 8, :page => params[:page], 
									:conditions => { :user_id => current_user.id }, :order => 'created_at DESC'
  end

	# Function to handle showing history items
	def show_history_items_page
  	@sold = Transaction.find_all_by_seller_id(current_user.id)
    @bought = Transaction.find_all_by_buyer_id(current_user.id)
  end

	# Function for handling writing a comment
	def write_comment
		# determing whos who
		@user = current_user
		@commentee = User.find(params[:commentee_id])

		# if the comment is not blank
		if !(params[:description] == "")
			# create new comment for the commentee
		  @comment = UserComment.new(:user_id => @user.id,
															   :commentee_id => params[:commentee_id],
															   :description => params[:description] )
		  @comment.save
		end
		redirect_to :action => 'profile', :username => @commentee.login
	end

	# Function to handle bidding
	def bid
		# initialize all variables
		@user = current_user
		@bids = Bid.find(:all, :conditions => {:item_id => params[:item_id]}, :order => "price DESC")
		@item = Item.find(params[:item_id])
		@admin = User.find_by_login("admin")
		price = params[:bid_price]
		money = @user.money

		# cannot bid when auction is closed		 
		if @item.closed
		    gflash :error => "This auction is closed."
		# must put in price
		elsif !price
			gflash :error => "Price cannot be empty"
		else
			# if theres bids before this bid
			if (@bids.count > 0)
				# get highest of the bids
				@highest = @bids.first

				# if this bid is less than the current highest one, error
				if price.to_f <= @highest.price
					gflash :error => "Bid price must be greater than the current price of the item!"
				elsif (@bids.first.bidder.id == current_user.id)
					# if highest bidder is already the user trying to bid again
				    gflash :error => "Cannot outbid yourself!"
		    	elsif (money < price.to_f)
					# if the user cannot afford the bid
			    gflash :error => "You cannot afford to pay this"
				else
					# new highest bidder, the user
					@highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
					@highest_bid.save

					# deduct money from the user since he is currently highest bidder
					@user.money = @user.money - price.to_f
					@user.save

					# show pop up regarding bid success
					gflash :success => "Bid success. You are now the highest bidder!"

					# automatically replace the html to show the new highest bidder using ajax so
					# refreshing the page is not necessary, i.e. automatically update highest bidder box
					render :juggernaut => {:type => :send_to_all} do |page|
					  	page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
					    page.visual_effect :highlight, "highest_bid_div", :duration => 5
					    page.replace_html "search_page_#{@item.id}", :partial => 'items/searched_bid_price', :object => @highest_bid
					    page.visual_effect :highlight, "search_page_#{@item.id}", :duration => 5
					end

					# if someone was outbidded by the current bid
					if @highest.bidder.id != @highest_bid.bidder.id
						# send message to the previous highest bidder
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
		    	end
			else # if there are no other bids
				if price.to_f <= @item.start_price 
					# if this bid is less than the current highest one, error
					gflash :error => "Bid price must be greater than the current price of the item!"
				elsif money < price.to_f
					# if the user cannot afford the bid	
					gflash :error => "Cannot afford to bid with that price!"
				else
					# since first one to bid, current bid is the highest
					@highest_bid = @user.bids.build(:item_id => params[:item_id], :price => params[:bid_price])
					@highest_bid.save

					# deduct money from the user since he is currently highest bidder
					@user.money = @user.money - price.to_f
					@user.save

					# show pop up regarding bid success
					gflash :success => "Bid success. You are now the highest bidder!"

					# automatically replace the html to show the new highest bidder using ajax so
					# refreshing the page is not necessary, i.e. automatically update highest bidder box
					render :juggernaut => {:type => :send_to_all } do |page|
						page.replace_html :highest_bid, :partial => 'items/highest_bid_price', :object => @highest_bid
						page.visual_effect :highlight, "highest_bid_div", :duration => 5
						page.replace_html "search_page_#{@item.id}", :partial => 'items/searched_bid_price', :object => @highest_bid
						page.visual_effect :highlight, "search_page_#{@item.id}", :duration => 5
				  	end
				end # end if price.to_f <= @item.start_price 
			end # end if (@bids.count > 0)
		end # end if @item.closed
		redirect_to :controller => 'items', :action => 'show', :id => params[:item_id]
	end

	# Function handling BIN option - Buy It Now
	def buy_it_now
		# find item with respect to its ID
    @item = Item.find(params[:id])

		# can't buy closed item, security
    if @item.closed
      gflash :error => "Unknown action"
    else
			# can't buy your own items
      if current_user == @item.user
        gflash :error => "You cannot buy your own item!"
      elsif current_user.money >= @item.bin_price
				# if there are bids, refund highest bidder
        if @item.bids.first
          @highest_bid = @item.bids.sort_by{|b| b.price}.last
          highest_bidder = @highest_bid.bidder
          highest_bidder.update_attribute(:money, highest_bidder.money+@highest_bid.price)
        end
				
				# show pop up regarding BIN success
        gflash :success => "Congratulations! You have bought the item."
        @item.closed = true

				# automatically replace the html to show the auction is now closed using ajax so
				# refreshing the page is not necessary, i.e. automatically update the auction closed box
        render :juggernaut => {:type => :send_to_all} do |page|
              page.replace_html :show_item_time, ""
              page.replace_html :bid_id, ""
              page.replace_html :highest_bid, "Auction is closed!"
              page.replace_html :show_item_bin_button, ""
              page.replace_html :show_item_watch, ""
              page.replace_html :show_item_stop, ""
              page.replace_html "item_time_#{@item.id}", :partial => 'items/search_time_ticker', :object => @item
              page.visual_effect :highlight, "item_time_#{@item.id}", :duration => 5
        end

				# update item attribute
        @item.update_attribute(:closed,true)

				# add money to the seller
				poster = @item.user
        poster.update_attribute(:money, poster.money+@item.bin_price)

				# deduct the money from the buyer
        current_user.update_attribute(:money,current_user.money-@item.bin_price)

				# create new transaction
				transaction = Transaction.new
  	    transaction.seller_id = poster.id
  	    transaction.buyer_id = current_user.id
  	    transaction.item_id = @item.id
  	    transaction.price = @item.bin_price
  	    transaction.save
      else
        gflash :error => "Cannot afford to buy this item"
      end
    end
    redirect_to :controller => 'items', :action => 'show', :id => params[:item_id]
  end
  
  def list_followers
    @user = User.find_by_login(params[:username])
  end

end



 
