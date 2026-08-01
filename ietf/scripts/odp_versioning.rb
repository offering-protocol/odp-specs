# frozen_string_literal: true

module OdpVersioning
  module_function

  VERSION_PATTERN = /\A(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\z/

  def parse(value)
    match = VERSION_PATTERN.match(value.to_s)
    match && [Integer(match[1]), Integer(match[2])]
  end

  def compatible?(supported, received)
    supported_version = parse(supported)
    received_version = parse(received)
    !!(supported_version && received_version && supported_version[0] == received_version[0])
  end
end
