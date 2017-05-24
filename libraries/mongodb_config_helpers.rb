# MongoDBConfigHelpers provides helpers to remove rendering logic
# from templates
module MongoDBConfigHelpers
  # to_boost_program_options takes a config Hash (with string keys and
  # scalar values) and converts to the boost::program_options format
  # used by mongodb 2.4.
  #
  # Notably it:
  # - ensures consistent ordering by key name
  # - does not render entries with a value of nil or ''
  def to_boost_program_options(config)
    config.sort \
          .map do |key, value|
      next if value.nil? || value == ''
      "#{key} = #{value}"
    end \
          .compact.join("\n")
  end

  def to_yaml_options(config)
    config.to_hash.compact.to_yaml
  end
end

# Monkey patches Hash to allow us to throw away keys that have empty or nil values
class Hash
  def compact
    inject({}) do |new_hash, (k, v)|
      if v.is_a?(Hash)
        v = v.compact
        new_hash[k] = v unless v.empty?
      else
        new_hash[k] = v unless v.nil?
      end
      new_hash
    end
  end
end
