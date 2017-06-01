namespace :migration do
  task start: :environment do
    Rails.application.eager_load!
    require_relative 'main.rb'
  end
end
