require 'mail'

module Mail
  class Ruby19
    class << self
      alias_method :__pick_encoding__, :pick_encoding
      def pick_encoding(charset)
        case charset
        when /SHIFT-JIS/
          Encoding::Shift_JIS
        else
          Ruby19.__pick_encoding__(charset)
        end
      end
    end
  end
end
