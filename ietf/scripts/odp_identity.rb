# frozen_string_literal: true

require "uri"

module OdpIdentity
  module_function

  LOOPBACK_HOSTS = ["localhost", "127.0.0.1", "::1"].freeze

  def local_identifier?(value)
    value.is_a?(String) && value.valid_encoding? && value.length.between?(1, 255) && !value.match?(/\p{Cc}/)
  end

  def canonical_origin?(value)
    return false unless value.is_a?(String) && value.ascii_only?

    uri = URI.parse(value)
    return false unless uri.absolute? && uri.host && !uri.userinfo && !uri.query && !uri.fragment
    return false unless uri.path.empty?

    scheme = uri.scheme.downcase
    host = uri.host.downcase
    return false unless scheme == "https" || (scheme == "http" && LOOPBACK_HOSTS.include?(host))
    return false unless uri.port.between?(1, 65_535)

    default_port = scheme == "https" ? 443 : 80
    authority_host = host.include?(":") ? "[#{host}]" : host
    port = uri.port == default_port ? "" : ":#{uri.port}"
    value == "#{scheme}://#{authority_host}#{port}"
  rescue URI::InvalidURIError
    false
  end

  def resource_reference?(value)
    return false unless value.is_a?(String) && value.ascii_only?

    uri = URI.parse(value)
    return false if uri.fragment || uri.userinfo

    if uri.absolute?
      host = uri.host&.downcase
      return false unless host
      return false unless uri.port.between?(1, 65_535)

      uri.scheme == "https" || (uri.scheme == "http" && LOOPBACK_HOSTS.include?(host))
    else
      !uri.host && value.start_with?("/") && !value.start_with?("//")
    end
  rescue URI::InvalidURIError
    false
  end
end
