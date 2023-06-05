# frozen_string_literal: true

Puppet::Functions.create_function(:'registry::deferred_data') do
  dispatch :deferred_data do
    param 'Optional[Variant[String, Numeric, Array[String]]]', :args
    return_type 'Optional[Variant[String, Numeric, Array[String]]]'
  end

  def deferred_data(args)
    args
  end
end
