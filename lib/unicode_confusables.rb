# frozen_string_literal: true

module Mail2www
  class UnicodeConfusables
    DATA_PATH = File.expand_path('../data/unicode/confusables.txt', __dir__)
    VERSION_PATTERN = /^# Version: (\S+)$/

    attr_reader :version

    def self.default
      @default ||= load
    end

    def self.load(path = DATA_PATH)
      File.open(path, 'r:UTF-8') { |file| parse(file, path:) }
    end

    def self.parse(lines, path: '(confusables)')
      version = nil
      mappings = {}

      lines.each_with_index do |line, index|
        version ||= line.match(VERSION_PATTERN)&.[](1)
        data = line.sub(/#.*/, '').strip
        next if data.empty?

        source, target, type, extra = data.split(/\s*;\s*/, -1)
        unless source && target && type == 'MA' && extra.nil?
          raise ArgumentError, "#{path}:#{index + 1}: malformed confusable mapping"
        end

        source_codepoints = parse_codepoints(source, path, index + 1)
        unless source_codepoints.one?
          raise ArgumentError, "#{path}:#{index + 1}: expected one source code point"
        end

        source_codepoint = source_codepoints.first
        if mappings.key?(source_codepoint)
          raise ArgumentError, "#{path}:#{index + 1}: duplicate source code point #{source}"
        end

        mappings[source_codepoint] = parse_codepoints(target, path, index + 1).pack('U*').freeze
      end

      raise ArgumentError, "#{path}: missing Unicode version" unless version

      new(version.freeze, mappings.freeze)
    end

    def initialize(version, mappings)
      @version = version
      @mappings = mappings
      freeze
    end

    # UTS #39 skeleton: NFD, map each source code point, then NFD again.
    def skeleton(string)
      mapped = string.unicode_normalize(:nfd).each_codepoint.map do |codepoint|
        @mappings.fetch(codepoint) { codepoint.chr(Encoding::UTF_8) }
      end.join
      mapped.unicode_normalize(:nfd)
    end

    class << self
      private

      def parse_codepoints(field, path, line_number)
        codepoints = field.split.map { |value| Integer(value, 16) }
        raise ArgumentError if codepoints.empty?

        codepoints.each { |codepoint| codepoint.chr(Encoding::UTF_8) }
        codepoints
      rescue ArgumentError, RangeError
        raise ArgumentError, "#{path}:#{line_number}: invalid Unicode code point sequence"
      end
    end
  end
end
