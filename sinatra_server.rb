require "sinatra" #RUBY GEMS
require "json"

require "./key_manager" # CUSTOM code FOR MANAGING KEYS

keys_manager = KeyManager.new # Object of Key Manager Class

get '/' do
  response = keys_manager.display_keys
  response
end

get '/generate-keys/:num' do |number|
	STDERR.puts "Number : #{number}"
	key_hash = keys_manager.generate_random_keys(number.to_i)
	response = keys_manager.save_keys(key_hash)
	response.to_json
end

get '/assign-key/' do
	use_key = keys_manager.allocate_available_key
	if use_key != false
		response = use_key.to_json
	else
		status 404
		"No Key is available right now!"
	end
end

get '/unblock-key/:key' do |key|
	is_unblocked = keys_manager.unblock_key?(key) # Returns true if successfully unblocked
	response = {message: "#{key}: successfully unblocked!"}.to_json if is_unblocked
	response = {message: "Wrong key provided"}.to_json if !is_unblocked
	response
end

get '/delete-key/:key' do |key|
	is_deleted = keys_manager.delete_key?(key)
	response = {message: "#{key} successfully deleted!"}.to_json if is_deleted
	response = {message: "Wrong key provided"}.to_json if !is_deleted
	response
end

get '/keepalive-key/:key' do |key|
	if !key.nil? 
		made_alive = keys_manager.make_it_alive(key)
		response = {message: "#{key} : kept alived!"}.to_json if made_alive
		response = {message: "Wrong key provided"}.to_json if !made_alive
	else
		status 404
		"Valid Key is not present in the url"
	end
end
