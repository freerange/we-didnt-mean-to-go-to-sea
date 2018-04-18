require 'test/unit'
require_relative 'sound_responder'
require_relative 'game'

class SoundResponderTest < Test::Unit::TestCase
  def setup
    @buoy1 = Feature.new('Buoy', 0, 0, 1)
    @lighthouse = Feature.new('Lighthouse', 0, 0, 1)
    @coastline = Feature.new('Coastline', 0, 0, 1)
    @dummy_state = State.new(0,0)

    @subject = SoundResponder.new
  end

  def test_single_buoy
    features_and_volume = [[@buoy1, 1]]
    cmd = @subject.listen_cmd(features_and_volume, @dummy_state)
    assert_equal cmd, 'sox -m -v 1.0 audio/bell1.wav output.wav && play output.wav'
  end

  def test_single_lighthouse
    features_and_volume = [[@lighthouse, 1]]
    cmd = @subject.listen_cmd(features_and_volume, @dummy_state)
    assert_equal cmd, 'sox -m -v 1.0 audio/horn.wav output.wav && play output.wav'
  end

  def test_single_coastline
    features_and_volume = [[@coastline, 1]]
    cmd = @subject.listen_cmd(features_and_volume, @dummy_state)
    assert_equal cmd, 'sox -m -v 1.0 audio/wave.wav output.wav && play output.wav'
  end

  def test_two_equidistant_buoys
    features_and_volume = [[@buoy1, 1], [@buoy1, 1]]
    cmd = @subject.listen_cmd(features_and_volume, @dummy_state)
    expected_volume_buoy_1 = 1.0/2.0
    expected_volume_buoy_2 = 1.0/2.0
    assert_equal cmd, "sox -m -v #{expected_volume_buoy_1} audio/bell1.wav -v #{expected_volume_buoy_2} audio/bell1.wav output.wav && play output.wav"
  end

  def test_two_buoys_different_distance
    features_and_volume = [[@buoy1, 1], [@buoy1, 0.5]]
    cmd = @subject.listen_cmd(features_and_volume, @dummy_state)
    expected_volume_buoy_1 = 1.0/1.5
    expected_volume_buoy_2 = 0.5/1.5
    assert_equal cmd, "sox -m -v #{expected_volume_buoy_1} audio/bell1.wav -v #{expected_volume_buoy_2} audio/bell1.wav output.wav && play output.wav"
  end
end
