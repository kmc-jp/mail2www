#
# config.rb - mail2www configuration file
#
require 'tempfile'

module Config

  # user configuration
  LOGFILE = "log.txt"
  MAIL_DIR = "./mail"
  SPAM_FILTER = ""
  FOLDERS = [ "test", "admin", "info" ]
  CGI_TITLE = "mail2www"
  CGI_NAME = "" # index.cgi

  # system configuration
  PERM_FILES = 0666
  MAILS_PER_PAGE = 20

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
