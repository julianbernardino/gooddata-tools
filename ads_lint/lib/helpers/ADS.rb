require 'sequel'
require 'jdbc/dss'

Jdbc::DSS.load_driver
Java.com.gooddata.dss.jdbc.driver.DssDriver

class Helpers::ADS

  def initialize(config={})
    @username         = config.delete(:username)
    @password         = config.delete(:password)
    @ads_instance_url = config.delete(:ads_instance_url)

    if @username == '' || @username.nil?
      raise ArgumentError, "username is empty string or nil"
    elsif @password == '' || @password.nil?
      raise ArgumentError, "password is empty string or nil"
    elsif @ads_instance_url == '' || @ads_instance_url.nil?
      raise ArgumentError, "ads_instance_url is empty string or nil"
    end
  end

  def execute(query)
    Sequel.connect @ads_instance_url, :username => @username, :password => @password do |conn|
      results = conn.run (query)
    end
  end

  def read_data(query)
    data = []
    Sequel.connect @ads_instance_url, :username => @username, :password => @password do |conn|
      conn[query].each do |row|
        data.push(row)
      end
    end

    data
  end

end
