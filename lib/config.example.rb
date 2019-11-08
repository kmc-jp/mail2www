#
# config.rb - mail2www configuration file
#

module Mail2www
  class Config < Hash
    def initialize(other = {})
      merge!(other)

      # user configurations
      self[:mail_dir] ||= File.expand_path(File.dirname(__FILE__)) + '/../mail'
      self[:folders] ||= %w(test admin info other shinkan2014)
      self[:title] ||= 'mail2www'
      self[:prefix] ||= ''

      # smtp configurations
      self[:smtp_server] = 'smtp.example.com'
      self[:mailname] = 'example.com'
      self[:bounce_to] = 'bounce@example.com'

      # system configurations
      self[:mails_per_page] ||= 20
    end
  end
end
