ActionController::Routing::Routes.draw do |map|

  map.resource :session, :member => {:destroy => :get}

  map.resources :users
  map.resources :accounts
  map.resources :memberships

  map.resources :buckets, :as => '', :requirements => {:id => /[\w\d\_\.\-]+/} do |bucket|
    bucket.resources :archives, :new => {:upload => :get, :upload_success => :get},
      :member => {:filter => :post}, :collection => {:queue => :get},
      :requirements => {:bucket_id => /[\w\d\_\.\-]+/}
  end

  map.root :controller => 'buckets', :action => 'index'
end
