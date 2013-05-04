# Be sure to restart your server when you modify this file.

Hdo::Application.config.session_store :cookie_store, key: '_hdo_session',
                                                     secure: AppConfig.ssl_enabled,
                                                     httponly: true,
                                                     expire_after: 60.minutes

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Hdo::Application.config.session_store :active_record_store
