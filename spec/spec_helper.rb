RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

require 'too_active'

module TooActive
  class TestEvent < Event
    event_class_for 'too_active.test'

    def self.from_args(*args)
      new(id: Time.now.to_i, start_time: Time.now - 1, end_time: Time.now, name: 'Dummy')
    end

    def self.mock
      self.from_args
    end
  end
end

Dir[File.join(__dir__, 'shared_examples/*.rb')].each { |f| require f }
