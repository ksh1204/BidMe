# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_BidMe_session',
  :secret      => 'e12a294fddc8dbb80abb1b336e39fa0d684d6572fd803888aa5c08d8a24bfb6ac0dfbf64c10853d651c1eeef0970c7bea5db340cb0901428852c8d4f95bd001b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
