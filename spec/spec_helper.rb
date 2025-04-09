require_relative "../lib/btc_wallet"

def fixture_path(relative_path)
  File.join(File.dirname(__FILE__), 'fixtures', relative_path)
end

def fixture_file(relative_path)
  file = File.read(fixture_path(relative_path))
  JSON.parse(file)
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
