#!/usr/bin/env ruby

require 'awesome_print'

require 'optparse'
require 'ostruct'
require 'mash'
require 'singleton'


class Rippers
  include Singleton

  class << self
    def register_adapter(id, kls)
      adapters.merge! id => kls
    end

    def adapters
      instance.adapters
    end
  end

  def adapters
    @adapters ||= {}.to_mash
  end
end

class BaseRipper
  class << self
    def register(name)
      Rippers.register_adapter name, self
    end

    def matches?
      false
    end
  end
end

class Imgur < BaseRipper
  register :imgur

  class << self
    def url_patterns
      [
        /imgur[.]com/i,
      ]
    end

    def matches?(url=`pbpaste`)
      return true if url_patterns.any?{|re| url[re] }
      false
    end
  end
end

puts TestD.assert # => nil

# >> PASS:TestD: registering :test_d as an adapter
