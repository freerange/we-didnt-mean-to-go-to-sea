class SoundResponder
  ACK = "Aye aye, Captain"

  def success(state)
    [ACK, state]
  end

  def listen(features_and_volume, state)
    cmd = listen_cmd(features_and_volume, state)
    puts cmd
    system(cmd)
    success(state)
  end

  def listen_cmd(features_and_volume, state)
    total_volume = features_and_volume.inject(0) { |t, (feature, volume)| t += volume }
    commands = features_and_volume.map do |feature, volume|
      feature_volume = volume / total_volume.to_f
      filename = feature_to_filename(feature)
      "-v #{feature_volume} #{filename}"
    end

    "sox -m #{commands.join(' ')} output.wav && play output.wav"
  end

  def feature_to_filename(feature)
    case feature.name
    when 'Buoy'
      "audio/bell1.wav"
    when 'Lighthouse'
      "audio/horn.wav"
    when 'Coastline'
      "audio/wave.wav"
    end
  end
end
