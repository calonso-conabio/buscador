require_relative 'boot'
require 'rails/all'
require 'uri'
require 'open-uri'
require 'csv'
require File.expand_path('../config', __FILE__)

CONFIG = BuscadorConfig.new(File.expand_path('../config.yml', __FILE__))

# DelayedJob priorities
USER_PRIORITY = 0               # response to user action, should happen ASAP w/o bogging down a web proc
NOTIFICATION_PRIORITY = 1       # notifies user of something, not ASAP, but soon
USER_INTEGRITY_PRIORITY = 2     # maintains data integrity for stuff user's care about
INTEGRITY_PRIORITY = 3          # maintains data integrity for everything else, needs to happen, eventually
OPTIONAL_PRIORITY = 4           # inconsequential stuff like updating wikipedia summaries

Bundler.require(*Rails.groups)

# General settings
IP = CONFIG.site_url.split(':')[1].gsub('//','')
PORT = CONFIG.site_url.split(':')[2][0..-1]
SITE_NAME = CONFIG.site_name
SITE_NAME_SHORT = CONFIG.site_name_short || SITE_NAME


unless Rails.env.development_mac?
  require 'blurrily/client.rb'  #para el fuzzy match
  FUZZY_NOM_COM = Blurrily::Client.new(:host => IP, :db_name => 'nombres_comunes')
  FUZZY_NOM_CIEN = Blurrily::Client.new(:host => IP, :db_name => 'nombres_cientificos')
end

module Buscador
  class Application < Rails::Application
    config.assets.precompile << 'delayed/web/application.css'
    config.load_defaults 5.1
    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8

    config.time_zone = 'Mexico City'

    config.middleware.use I18n::JS::Middleware

    #config.autoload_paths += %W(#{config.root}/lib)
    config.eager_load_paths += Dir[Rails.root.join('lib')]
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{*/}')]
    #config.sass.preferred_syntax=:sass

    # Cambia en nombre de la tabla por default
    ActiveRecord::SessionStore::Session.table_name = 'sessions'

    # Devise
    config.action_mailer.default_url_options = { host: IP, port: PORT }

    # Google analytics
    config.middleware.use Rack::GoogleAnalytics, :tracker => CONFIG.google_analytics.tracker_id, :domain => CONFIG.google_analytics.domain_name

    # Para que no escape caracteres inecesarios como "&"
    config.active_support.escape_html_entities_in_json = false

    # Para a configuracion del correo
    Mail.defaults do
      retriever_method(:imap, { :address => CONFIG.smtp.address,
                                :user_name => CONFIG.smtp.user_name,
                                :password => CONFIG.smtp.password
                            })
      delivery_method(:smtp, :address => CONFIG.smtp.address,
                      :user_name => CONFIG.smtp.user_name,
                      :password => CONFIG.smtp.password)
    end
  end
end
