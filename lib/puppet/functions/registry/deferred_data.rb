# frozen_string_literal: true

Puppet::Functions.create_function(:'registry::deferred_data') do
  dispatch :deferred_data do
    param 'Any', :args
    return_type 'Any'
  end

  def deferred_data(args)
    args
  end
end
