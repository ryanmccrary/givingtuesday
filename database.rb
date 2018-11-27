require 'data_mapper'

class Database
  def self.initialize
    DataMapper::Logger.new($stdout, :debug)
    # memory database appears to timeout if not used in ~5 mins, which causes the database to be dumped
    #DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end

  def self.seed_data
    # Create a single, $0 amount so there aren't nils breaking everything
    Donation.create(
      amount: 0,
      customer: 'nilsbebreaking@goattrips.org')
  end
end

class Donation
  include DataMapper::Resource

  property :id, Serial
  property :amount, Integer
  property :customer, String
end
