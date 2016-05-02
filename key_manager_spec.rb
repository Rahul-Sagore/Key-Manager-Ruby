require "rspec"
require "./key_manager"

describe KeyManager do

	before do
    @keys_manager = KeyManager.new
    @key_hash = @keys_manager.generate_random_keys(5)
    @keys_manager.save_keys(@key_hash)

  end

  #TEST: Generate Unique Keys
  it "should return array of unique keys - GENERATE" do
    expect(@key_hash.size).to eq 5
  end

  #TEST: ASSIGN RANDOM KEY FROM AVAILABLE KEYS,
  it "should return random key from available keys - ASSIGNS" do
    key_hash = @keys_manager.allocate_available_key
    expect(@keys_manager.blocked_keys[key_hash[:key]]).to eq "blocked"
  end

  #TEST: RELEASE ASSIGNED KEY
  it "should unblock the key that was assigned - RELEASES" do
  	assigned_key = @keys_manager.blocked_keys.keys[0]
 
    released = @keys_manager.unblock_key?(assigned_key)

    expect(released).to eq true
  end
  
  #TEST: DELTE THE KEY
  it "should delete the key - DELETES" do
  	random_key = @key_hash[0]

    deleted = @keys_manager.delete_key?(random_key)

    expect(deleted).to eq true
  end

end