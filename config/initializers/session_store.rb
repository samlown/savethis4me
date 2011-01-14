# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_savethis4.me_session',
  :secret      => '8ab2794f361165c1e27fea9c42fb02227bfb1e2b17711e02ce03a4881cff59381d3fe8b5cb8b9839fff113ea396318c8cadf908e23e1ab60574bf2ac38732aff'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
