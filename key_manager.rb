require "PStore"
require "securerandom"
require 'thread'

class KeyManager # CLASS for Managing/Manipulating Keys
	attr_accessor :available_keys, :blocked_keys

	def initialize
		@database = PStore.new('keys.pstore')
		init_keys
		@mutex = Mutex.new # Semaphore Mutual exclusion
	end

	def init_keys
		@powerup_key ||= {}
		@database.transaction do
			if !@database[:keys].nil?
				@available_keys = @database[:keys]
				@blocked_keys = @database[:blocked_keys]
			end
		end
	end

	def generate_random_keys(num) # Generate random keys
		if num.is_a? Integer
			random_keys = []
			num.times {
				random_keys.push(SecureRandom.uuid)
			}
			random_keys
		end
	end

	def save_keys(keys) # API: SAVE THE GENERATED KEY
		keys.each { |key|
			key_hash = {key: key}
			@database.transaction do
				@database[:keys] ||= []
				@database[:keys].push(key_hash)

				@mutex.synchronize {
					@powerup_key[key] = Time.now
				}
				delete_key_timeout key
			end
		}
		init_keys
		@available_keys
	end

	def allocate_available_key # API: ALLOCATE THE AVAILBLE KEY TO THE USER
		index = rand(@available_keys.size)

		used = {}, result  = false
		exec_db_operation do
			@database[:keys] ||= []
			@database[:blocked_keys] ||= {}
			if @database[:keys].size > 0
				used = @database[:keys].delete_at(index)
				@database[:blocked_keys][used[:key]] = "blocked"

				unblock_timeout(used[:key]) # Calling timeout function for each allocated key
				result = used
			end
		end
		init_keys #init Instance variables
		return result
	end

	def unblock_key?(key) # API: UNBLOCK THE BLOCKED KEY
		unblocked_key = "", result = false
		exec_db_operation do
			unblocked_key = @database[:blocked_keys].delete(key) if !@database[:blocked_keys].nil? #Delete the key from block HASH

			if !unblocked_key.nil? && unblocked_key
			 	@database[:keys].push({key: key}) # PUT it in available keys again if key found in block Hash
				result = true
			end
		end
		init_keys
		return result
	end

	def delete_key?(key) # API: DELETE THE KEY FROM THE DATASTORE
		result = false
		@database.transaction do
			key_hash = {key: key}
			deleted_key = @database[:keys].delete(key_hash) #Deleting from Avaiable keys

			if !@database[:blocked_keys].nil?  # Deleting from blocked key if it is there.
				delete_blocked = @database[:blocked_keys].delete(key)
			end
			# "Delete key" result
			if !deleted_key.nil? || !delete_blocked.nil?
				@powerup_key.delete(key)
				result = true
			end
		end
		init_keys
		return result
	end

	def make_it_alive(key) # API: MAKE THE KEY ALIVE FOR MORE 5 MINUTE
		result = true
		@mutex.synchronize {
			if !@powerup_key[key].nil?
				@powerup_key[key] = Time.now
			else
				result = false
			end
		}
		delete_key_timeout(key)
		result
	end

	def unblock_timeout(key) # METHOD: RELEASE "BLOCKED KEY" AFTER 60 SECOND OF ALLOCATION
		exec_thread(40) {
		    unblock_key?(key)
		}
	end

	def delete_key_timeout(key) # METHOD: DELETE KEY AFTER 5 MINUTE, IF NOT KEPT ALIVE
		exec_thread(20) { |seconds|
			@mutex.synchronize {
				if Time.now - @powerup_key[key] >= seconds
		    	delete_key?(key)
		    end
			}
		}	
	end

	def exec_thread(seconds) # Yield general function for executing thread
		Thread.new do
		  while true do
		  	sleep seconds
		  	yield seconds
		  end
		end
	end

	def exec_db_operation
		@mutex.synchronize { # Blocking parallel request unitl previous one completes
			@database.transaction do
				yield
			end
		}
	end

	def display_keys
		response = ""
		@database.transaction do
			response += "\nAvailable keys: #{@available_keys} \n\n" 
			response += "\nBlocked Keys: #{@blocked_keys}"
		end
		response
	end
end
