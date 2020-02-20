source 'https://rubygems.org'

gem 'actionpack-action_caching'  # Fue removido del core en 4.0
gem 'activerecord-session_store'  # Pasa los request con POST a traves de la base (para request muy largos)
gem 'ancestry', git: 'https://github.com/calonsot/ancestry.git', :ref => 'bfadb2c'  # lee los ancestros en modo de arbol
gem 'axlsx', git: 'https://github.com/randym/axlsx.git', ref: 'c8ac844'
gem 'axlsx_rails'  # Gema para exportar en excel
gem 'bootstrap-sass', '~> 3.4.1'
gem 'carrierwave'  # Form file upload
gem 'cocoon'  # Anida las formas de diferentes o del mismo modelo
gem 'coffee-rails', '~> 4.2'
gem 'composite_primary_keys'  # Multiples llaves primarias
gem 'daemons', '1.0.10'  # para hacer ejecutables bash
gem 'delayed_job'
gem 'delayed_job_mongoid'
gem 'delayed-web'
gem 'devise'
gem 'exifr'
gem 'font-awesome-rails', '~> 4.7'
gem 'fontello_rails_converter'
gem 'formtastic'
gem 'haml'
gem 'htmlentities'
gem 'i18n-js'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'levenshtein-ffi', :require => 'levenshtein'
gem 'mail'
gem 'mime-types'
gem 'mysql2'
gem 'nokogiri'  # Hacer un parse con xml
gem 'pg'
gem 'puma', '~> 3.12' # Use Puma as the app server
gem 'rack-contrib'
gem 'rack-google-analytics'
gem 'rails', '5.1.6.2'
gem 'railties'
gem 'rake'
gem 'recaptcha', :require => 'recaptcha/rails'  # Con el api de google
gem 'rest-client', :require => 'rest_client'
gem 'rinku', :require => 'rails_rinku'  # extiende el metodo auto_link
gem 'roo', :require => 'roo'  # Solo lectura excel, open office, google docs
gem 'rubyXL', :require => 'rubyXL'  # Crea archivos xlsx, con formato
gem 'rubyzip', :require => 'zip'
gem 'sass-rails', '~> 5.0'
gem 'savon'  # Para consumir webservices con SOAP y WSDL
gem 'seed_dump'  # Extrae las tuplas de un modelo o de toda la base
gem 'simple_form'
gem 'soulmate', :require => 'soulmate/server'
gem 'therubyracer', platforms: :ruby
gem 'turbolinks', '~> 5'  # Hace mas rapidos los links
gem 'trollop'
gem 'uglifier'
gem 'wash_out'
gem 'whenever', :require => false
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'zip-zip' # Needed by axlsx

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development, :test, :production do
  gem 'blurrily', git: 'https://github.com/calonsot/blurrily.git', :ref => 'c0cbbd1e9961774a6b8e2546285d38095b4d1bfa', :require => 'blurrily/server.rb'  # Forza a blurrily a usar rails 5
end

group :development, :development_mac, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'

  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
