# encoding: UTF-8

module Helpers
  class << self

    def connect_ADS(config={})
			Helpers::ADS.new(config)
    end

  end
end

require_relative 'helpers/ADS'