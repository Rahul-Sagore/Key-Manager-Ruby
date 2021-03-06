require "socket"
require "json"
require "securerandom"
require "PStore"

require "./key_manager" # CUSTOM METHOD FOR MANAGING KEYS

class HTTPServer #HTTP SERVER For serving request

	def initialize(port)
		@server = TCPServer.new("localhost", port)
		puts "Server started at: http://localhost:#{port}\n"

		@keys = KeyManager.new # Object of Key Manager Class
		@database = PStore.new('keys.pstore') #Data Storage
		@is_valid_request = true
	end

	def get_endpoint(request) # Get URL end point hit by the user
		return request.split(" ") if request
	end

	def get_url_param(url)
		split = url.split('/')
		split
	end

	def start() # Start Processing the request sent by the user
		loop do
			socket = @server.accept
			request = socket.gets
			request_array = get_endpoint(request) #Fetch Method name, URL, in array form
			url = request_array[1]
			response = "Welcome to KEY Manager API! \n"

			STDERR.puts url

			param = get_url_param(url)

			# HANDING ROUTES/API
			case url
			when "/"
				@database.transaction do
					response += "\nAvailable keys: #{@keys.available_keys} \n" 
					response += "\nBlocked Keys: #{@keys.blocked_keys}"
				end

			when "/E1"
				keys = @keys.generate_random_key(param[-1])
				key_hash = @keys.save_key(keys)
				response = key_hash.to_json
				response
			when "/E2" # ISSUE AVAILABLE KEYS TO THE USER, THEN BLOCK IT
				use_key = @keys.allocate_available_key
				if use_key != false
					response = use_key.to_json
				else
					@is_valid_request = false
				end

			when "/E3" #UNBLOCK THE BLOCKED KEY FOR REUSE
				if !request_data[:key].nil? 
					is_unblocked = @keys.unblock_key?(request_data[:key]) # Returns true if successfully unblocked

					response = {message: "Key has been successfully unblocked!"}.to_json if is_unblocked
					response = {message: "Wrong key provided"}.to_json if !is_unblocked
				else
					response = {message: "Invalid Post data"}.to_json
				end

			when "/E4" # DELETE THE KEY
				if !request_data[:key].nil? 
					is_deleted = @keys.delete_key?(request_data[:key])

					response = {message: "Key has been successfully deleted!"}.to_json if is_deleted
					response = {message: "Wrong key provided"}.to_json if !is_deleted
				else
					response = {message: "Invalid Post data"}.to_json
				end

			when "/E5" #MAKING KEY, KEEP ALIVE
				if !request_data[:key].nil?
					made_alive = @keys.make_it_alive(request_data[:key])
					response = {message: "Key has been kept alived!"}.to_json
				else
					response = {message: "Invalid Post data"}.to_json
				end
			else
				@is_valid_request = false
			end

			end_response(socket, response)
		end
	end

	def end_response(socket, response)
			res_header = "HTTP/1.1 200 OK\r\n" if @is_valid_request
			if !@is_valid_request
				res_header = "HTTP/1.1 404 Not Found\r\n"
				response = "404, ERROR"
			end

			socket.print res_header +
		               "Content-Type: text/plain\r\n" +
		               "Content-Length: #{response.bytesize}\r\n" +
		               "Connection: close\r\n"

		  socket.print "\r\n" #Print blank line
			socket.print response

		  socket.close
	end
end

server = HTTPServer.new(8000)
server.start
