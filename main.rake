namespace :migration do
  task start: :environment do
    require_relative 'main.rb'
  end
end
