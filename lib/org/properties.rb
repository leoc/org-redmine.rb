require 'org/object'

module Org
  class Properties < Org::Object # :nodoc:
    OPENING = ':PROPERTIES:'.freeze
    CLOSING = ':END:'.freeze

    def headline
      file.find_headline(offset: beginning, reverse: true)
    end

    def ancestor_if(&block)
      file.find_ancestor_if(offset: beginning, &block)
    end

    def content_beginning
      beginning + OPENING.length
    end

    def content_ending
      ending - CLOSING.length
    end

    def [](name)
      to_hash[name]
    end

    def to_hash
      @hash ||=
        begin
          return {} if beginning == ending
          options = { offset: content_beginning, limit: content_ending }
          hash = {}
          property = file.find_property(options)
          while property
            hash[property.name.to_sym] = property.value
            property = file.find_property(options.merge(offset: property.ending))
          end
          hash
        end
    end
  end
end
