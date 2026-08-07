# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "=== Populating MediaVault Database ==="

puts "\nCreating default users..."
home = User.find_or_create_by!(name: "Home")

puts "Creating default categories..."
movies = Category.find_or_create_by!(name: "Movies")
tv_shows = Category.find_or_create_by!(name: "TV Shows")

puts "\nScanning local media library..."
ScanMediaService.call

puts "\nSeed completed successfully!"
