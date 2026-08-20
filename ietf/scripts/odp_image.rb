# frozen_string_literal: true

require_relative "odp_identity"

module OdpImage
  TYPES = %w[image/avif image/jpeg image/png image/svg+xml image/webp].freeze

  def self.list?(images)
    return false unless images.is_a?(Array) && images.length.between?(1, 16)
    return false unless images.all? { |image| image.is_a?(Hash) }
    return false unless images.map { |image| image["src"] }.uniq.length == images.length

    images.all? do |image|
      (image.keys - %w[alt height src type width]).empty? &&
        OdpIdentity.resource_reference?(image["src"]) &&
        (!image.key?("alt") || image["alt"].is_a?(String) && !image["alt"].empty? && image["alt"].length <= 1024) &&
        (!image.key?("height") || image["height"].is_a?(Integer) && image["height"].between?(1, 65_535)) &&
        (!image.key?("type") || TYPES.include?(image["type"])) &&
        (!image.key?("width") || image["width"].is_a?(Integer) && image["width"].between?(1, 65_535))
    end
  end
end
