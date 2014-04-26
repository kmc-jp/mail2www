#
# config.rb - mail2www configuration file
#
require 'mail'

module Mail2www
  class Config < Hash
    def initialize(other = {})
      merge!(other)

      # user configurations
      self[:mail_dir] ||= File.expand_path(File.dirname(__FILE__)) + '/../mail'
      self[:folders] ||= %w(test admin info other shinkan2014)
      self[:title] ||= 'mail2www'

      # system configurations
      self[:mails_per_page] ||= 20
    end
  end
end
