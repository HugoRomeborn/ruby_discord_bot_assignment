# spec_helper.rb - Test configuration och setup
#
# Denna fil laddas av alla tester för att:
# - Konfigurera Minitest
# - Aktivera minitest-reporters för snygg output
# - Ladda gemensamma test-hjälpare (mocks)
#
# Användning i testfiler:
#   require_relative 'spec_helper'
#   require_relative '../lib/command'  # Ladda fortfarande produktionskod explicit!
#
#   class TestCommand < Minitest::Test
#     def test_something
#       # ...
#     end
#   end

require 'minitest/autorun'
require 'minitest/reporters'

# Aktivera SpecReporter för färgglad, lättläst output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Ladda test-hjälpare (mocks)
require_relative 'mock_event'
