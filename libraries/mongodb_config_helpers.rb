# MongoDBConfigHelpers provides helpers to remove rendering logic
# from templates
module MongoDBConfigHelpers
  # to_boost_program_options takes a config Hash (with string keys and
  # scalar values) and converts to the boost::program_options format
  # used by mongodb 2.4.
  #
  # Notably it:
  # - ensures consistent ordering by key name
  # - does not render entries with a value of nil
  def to_boost_program_options(config)
    config.sort
    .map do |key, value|
      next if value.nil?
      "#{key} = #{value}"
    end
    .join("\n")
  end
end
