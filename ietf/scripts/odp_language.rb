# frozen_string_literal: true

module OdpLanguage
  GRANDFATHERED = %w[
    art-lojban cel-gaulish en-gb-oed i-ami i-bnn i-default i-enochian i-hak i-klingon i-lux
    i-mingo i-navajo i-pwn i-tao i-tay i-tsu no-bok no-nyn sgn-be-fr sgn-be-nl sgn-ch-de
    zh-guoyu zh-hakka zh-min zh-min-nan zh-xiang
  ].freeze

  module_function

  def tag?(value)
    return false unless value.is_a?(String)

    subtags = value.downcase.split("-", -1)
    return false if subtags.any?(&:empty?) || subtags.any? { |subtag| !subtag.match?(/\A[a-z0-9]{1,8}\z/) }
    return true if GRANDFATHERED.include?(subtags.join("-"))

    index = 0
    if subtags.first == "x"
      return subtags.length > 1
    elsif subtags.first&.match?(/\A[a-z]{2,3}\z/)
      index = 1
      3.times do
        break unless subtags[index]&.match?(/\A[a-z]{3}\z/)

        index += 1
      end
    elsif subtags.first&.match?(/\A[a-z]{4}\z|\A[a-z]{5,8}\z/)
      index = 1
    else
      return false
    end

    index += 1 if subtags[index]&.match?(/\A[a-z]{4}\z/)
    index += 1 if subtags[index]&.match?(/\A(?:[a-z]{2}|[0-9]{3})\z/)

    variants = []
    while subtags[index]&.match?(/\A(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3})\z/)
      variants << subtags[index]
      index += 1
    end
    return false unless variants.uniq.length == variants.length

    extensions = []
    while subtags[index]&.match?(/\A[0-9a-wy-z]\z/)
      extensions << subtags[index]
      index += 1
      start = index
      index += 1 while subtags[index]&.match?(/\A[a-z0-9]{2,8}\z/)
      return false if index == start
    end
    return false unless extensions.uniq.length == extensions.length

    if subtags[index] == "x"
      index += 1
      start = index
      index += 1 while subtags[index]&.match?(/\A[a-z0-9]{1,8}\z/)
      return false if index == start
    end

    index == subtags.length
  end
end
