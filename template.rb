# Add Gems
gem 'haml-rails'
gem 'bootstrap-sass'
gem 'simple_form'
gem 'kaminari'
gem 'font-awesome-rails'
gem 'puma'

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

gem_group :development do
  gem 'quiet_assets'
end

gem_group :test do
  gem 'capybara'
  gem 'shoulda-matchers'
end

# Make the generators less annoying
application do
  <<-eos
config.generators do |g|
  g.stylesheets     false
  g.javascripts     false
  g.helper          false
  g.view_specs      false
  g.helper_specs    false
end
  eos
end


# Run generators
generate("rspec:install")
generate("simple_form:install", "--bootstrap")
generate("kaminari:config")
generate("controller static index")

# Generate DB
rake "db:create", :env => 'development'
rake "db:migrate", :env => 'development'
rake "db:create", :env => 'test'
rake "db:migrate", :env => 'test'

# Set up Factory Girl
create_file "spec/support/factory_girl.rb" do
  <<-eos
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
  eos
end

# Customize JS Assets
inject_into_file 'app/assets/javascripts/application.js', after: "//= require jquery_ujs\n" do
  <<-eos
//= require bootstrap-sprockets
  eos
end

# Customize SCSS Assets
#
remove_file "app/assets/stylesheets/application.css"
create_file "app/assets/stylesheets/application.scss" do
  <<-eos
@import "colors";
@import "fonts";
@import "font-awesome";
@import "bootstrap-before";
@import "bootstrap-sprockets";
@import "bootstrap";
@import "bootstrap-after";
@import "global";
@import "mobile_overrides";
@import "pages/*";
  eos
end
create_file "app/assets/stylesheets/colors.scss" do
  <<-eos
$white: #ffffff;
$black: #000000;
  eos
end
create_file "app/assets/stylesheets/fonts.scss" do
  <<-eos
$default-font: Helvetica, Arial, sans-serif;
  eos
end
create_file "app/assets/stylesheets/bootstrap-before.scss"
create_file "app/assets/stylesheets/bootstrap-after.scss"
create_file "app/assets/stylesheets/global.scss" do
  <<-eos
.spacer-top { padding-top: 1em; }
.spacer-bottom { padding-bottom: 1em; }
.spacer-left { padding-left: 1em; }
.spacer-right { padding-right: 1em; }
  eos
end
create_file "app/assets/stylesheets/mobile_overrides.scss" do
  <<-eos
@media only screen and (max-width: 40em) {
    }
  eos
end
create_file "app/assets/stylesheets/pages/static.scss"

# Set up a simple Bootstrap Template
remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.haml" do
  <<-eos
!!!
%html{:lang => "en"}
  %head
    %meta{charset: "utf-8"}/
    %meta{content: "IE=edge", "http-equiv": "X-UA-Compatible"}/
    %meta{content: "width=device-width, initial-scale=1", name: "viewport"}/

    %title = content_for(:title) || 'LocalBoy'

    = stylesheet_link_tag 'application', media: 'all'
    = javascript_include_tag 'application'
    = csrf_meta_tags
  %body
    %header
      == render 'layouts/navigation'
    %main {role: "main"}
      #content-container
        == bootstrap_flash
        == yield
    %footer
      == render 'layouts/footer'
  eos
end
create_file "app/views/layouts/navbar.html.haml"
create_file "app/views/layouts/footer.html.haml"
create_file "app/helpers/bootstrap_flash_helper.rb" do
  <<-eos
module BootstrapFlashHelper

  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      # Skip Devise :timeout and :timedout flags
      next if type == :timeout
      next if type == :timedout
      type = :success if type == 'notice'
      type = :danger  if ['alert', 'error'].include?(type)
      text = content_tag(:div, 
               content_tag(:button, raw("&times;"), :class => "close", "data-dismiss" => "alert") +
               message, :class => "text-center alert fade in alert-\#{type}")
      flash_messages << text if message
    end
    flash_messages.join("\n").html_safe
  end
end
  eos
end


# Generate binstubs
run("bundle binstubs rspec-core")

# Generate a static page
route "root to: 'static#index'"

# Use Puma
create_file "Procfile" do
  <<-eos
web: bundle exec puma -C config/puma.rb
  eos
end
create_file "config/puma.rb" do
  <<-eos
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
  eos
end


# Generate inital commit
after_bundle do
  git :init
  git add: '.'
  git commit: "-a -m 'Initial commit'"
end
