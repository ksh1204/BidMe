ActionController::Routing::Routes.draw do |map|
 

  map.resources :items

  map.add_money 'users/add_money', :controller => 'users', :action => 'add_money'
  map.edit 'users/edit', :controller => 'users', :action => 'edit'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.send_message '/users/send_message', :controller => 'users', :action => 'send_message'
  map.forgot    '/forgot',                    :controller => 'users',     :action => 'forgot'
  map.reset     'reset/:reset_code',          :controller => 'users',     :action => 'reset'
  map.change_password 'users/change_password', :controller => 'users', :action => 'change_password'
  map.about '/users/about', :controller => 'users', :action => 'about'
  map.home '/users/home', :controller => 'users', :action => 'home'
  map.messagebox 'messagebox', :controller => 'users', :action => 'messagebox'
  map.sent_messages 'sent_messages', :controller => 'users', :action => 'sent_messages'
  map.write_message 'write_message', :controller => 'users', :action => 'write_message'
  map.show_message 'message', :controller => 'users', :action => 'show_message'
  map.show_sent_message 'sent_message', :controller => 'users', :action => 'show_sent_message'
  map.profile 'profile/:username', :controller => 'users', :action => 'profile'
  map.remove_profile_photo 'remove_profile_photo', :controller => 'users', :action => 'remove_profile_photo'
  map.report_user 'report', :controller => 'users', :action => 'report_user'
  map.follow_user 'follow', :controller => 'users', :action => 'follow_user'
  map.unfollow_user 'unfollow', :controller => 'users', :action => 'unfollow_user'
  map.delete_category 'item_categories/destroy/:id', :controller=> 'item_categories', :action => 'destroy'
  map.edit_category 'item_categories/edit/:id', :controller=> 'item_categories', :action => 'edit'
  map.post '/post', :controller =>'items', :action => 'create'
  map.post_item 'post_item', :controller => 'items', :action => 'new'
  map.bin_check 'bin_check', :controller => 'items', :action => 'bin_check'
  map.search_item 'search', :controller => 'items', :action => 'search'
  map.bid_item 'bid', :controller => 'users', :action => 'bid'
  map.end_auction 'end_auction/:id', :controller => 'items', :action => 'end_auction'
  map.show 'items/:id', :controller => 'items', :action => 'show'
  map.show_user_items 'posts', :controller => 'users', :action => 'show_user_items'
  map.search_index 'search', :controller => 'items', :action => 'index'
  map.bin 'bin/:id', :controller => 'users', :action => 'buy_it_now'
  
  map.resources :messages
  map.resources :users, :member => {:rate => :post}
  map.resources :users
  
  

  map.resource :session
  
  map.resources :admins
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  map.root :controller => "base"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
