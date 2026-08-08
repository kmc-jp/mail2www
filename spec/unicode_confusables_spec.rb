# frozen_string_literal: true

require 'stringio'
require_relative './spec_helper'
require_relative '../lib/unicode_confusables'

describe Mail2www::UnicodeConfusables do
  describe '.parse' do
    it 'parses the version and mappings while ignoring comments' do
      table = described_class.parse(StringIO.new(<<~TABLE))
        # Version: 17.0.0
        0430 ; 0061 ; MA # CYRILLIC SMALL LETTER A
        00E6 ; 0061 0065 ; MA
      TABLE

      expect(table.version).to eq('17.0.0')
      expect(table.skeleton("p\u0430yp\u0430l")).to eq('paypal')
      expect(table.skeleton("\u00E6")).to eq('ae')
    end

    it 'rejects malformed mappings' do
      input = StringIO.new("# Version: 17.0.0\n0430 ; nope ; MA\n")

      expect { described_class.parse(input) }.to raise_error(ArgumentError, /invalid Unicode/)
    end

    it 'rejects duplicate source code points' do
      input = StringIO.new("# Version: 17.0.0\n0430 ; 0061 ; MA\n0430 ; 0062 ; MA\n")

      expect { described_class.parse(input) }.to raise_error(ArgumentError, /duplicate source/)
    end
  end

  describe '.load' do
    it 'loads the bundled Unicode table' do
      table = described_class.load

      expect(table.version).to eq('17.0.0')
      expect(table.skeleton("p\u0430yp\u0430l.com")).to eq('paypal.corn')
    end
  end

  describe '.default' do
    it 'loads the bundled table once' do
      expect(described_class.default).to equal(described_class.default)
    end
  end

  describe '#skeleton' do
    it 'normalizes before and after applying mappings' do
      table = described_class.parse(StringIO.new(<<~TABLE))
        # Version: test
        00E9 ; 0065 ; MA
        0301 ; 0300 ; MA
      TABLE

      expect(table.skeleton("\u00E9")).to eq("e\u0300")
    end
  end
end
