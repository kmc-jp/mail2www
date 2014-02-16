#
# config.rb - mail2www configuration file
#
require 'tempfile'
require 'mail'
require_relative 'utils'

module Mail2www
  class Config < Hash
    include Utils

    def initialize(other={})
      merge!(other)

      # user configurations
      self[:log_file] ||= "log.txt"
      self[:mail_dir] ||= "./mail"
      self[:spam_filter] ||= ""
      self[:folders] ||= ["test", "admin", "info", "other"]
      self[:cgi_title] ||= "mail2www"
      self[:cgi_name] ||= "" # index.cgi

      # system configurations
      self[:index_file] ||= "index"
      self[:perm_files] ||= 0644
      self[:mails_per_page] ||= 20
    end

    def assort(mail)
      tmp = Tempfile.new("mail2www")
      begin
        tmp.write mail
        mail = Mail.read(tmp.path)
      rescue
        tmp.close
        tmp.unlink
      end

      if in_to_or_cc?(mail, /kmc-ml@googlegroups.com/)
        'kmc-ml'
      elsif in_to_or_cc?(mail, /info@kmc.gr.jp/)
        'info'
      else
        'other'
      end
    end

    def spam?(mail)
      IO.popen(SPAM_FILTER, "r+") do |io|
        io.write mail
      end

      case ($?.to_i / 256)
      when 0
        true
      when 1
        false
      else
        raise "failed to execute spam filter: #{$?}"
      end
    end
  end
end
