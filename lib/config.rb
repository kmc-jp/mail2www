#
# config.rb - mail2www configuration file
#
require 'tempfile'
require 'mail'
require_relative 'utils'

module Config
  include Utils

  # user configuration
  LOGFILE = "log.txt"
  MAIL_DIR = "./mail"
  SPAM_FILTER = ""
  FOLDERS = [ "test", "admin", "info" ]
  CGI_TITLE = "mail2www"
  CGI_NAME = "" # index.cgi

  # system configuration
  INDEX_FILE = "index"
  PERM_FILES = 0644
  MAILS_PER_PAGE = 20

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
