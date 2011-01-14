# include at least one source and the rails gem
source :gemcutter

gem 'rails', '2.3.10'

gem 'haml', '>= 3.0'

gem 'ruby-openid', '~> 2.0.4', :require => 'openid'

gem 'rmagick', '2.12.2', :require => "RMagick"

gem 'aws'
gem 'carrierwave', '0.4.10'

# gem 'base32', :git => 'git://github.com/levinalex/base32.git', :require => 'base32/crockford'

gem 'daemons'

group :production do
  gem 'pg'
end

group :development do
  # bundler requires these gems in development
  # gem 'rails-footnotes'
  gem 'mongrel'
  gem 'sqlite3-ruby', :require => 'sqlite3'
end

group :test do
  # bundler requires these gems while running tests
  gem 'rspec'
end

