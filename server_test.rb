ENV['RACK_ENV'] = 'test'

require_relative 'server'
require 'test/unit'
require 'rack/test'

class ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_GET_responds_with_200
    get '/'
    assert last_response.ok?
  end

  def test_GET_responds_with_json_containing_acknowledgement
    get '/'
    assert_not_nil JSON.parse(last_response.body)['ack']
  end

  def test_GET_responds_with_json_containing_x_coord
    get '/'
    assert_not_nil JSON.parse(last_response.body)['state']['x']
  end

  def test_GET_responds_with_json_containing_y_coord
    get '/'
    assert_not_nil JSON.parse(last_response.body)['state']['y']
  end

  def test_POST_accepts_a_state_and_command
    post '/', '{"state":{"x":5,"y":6},"command":"listen"}'
    assert last_response.ok?
  end

  def test_POST_responds_with_json_containing_acknowledgement
    post '/', '{"state":{"x":5,"y":6},"command":"listen"}'
    assert_not_nil JSON.parse(last_response.body)['ack']
  end

  def test_POST_responds_with_json_containing_x_coord
    post '/', '{"state":{"x":5,"y":6},"command":"listen"}'
    assert_not_nil JSON.parse(last_response.body)['state']['x']
  end

  def test_POST_responds_with_json_containing_y_coord
    post '/', '{"state":{"x":5,"y":6},"command":"listen"}'
    assert_not_nil JSON.parse(last_response.body)['state']['y']
  end
end
