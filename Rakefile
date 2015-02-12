require "sqlite3"
require "colorize"
require "cfpropertylist"
require 'digest/sha1'
require 'launchy'
require 'pry'

def system_or_exit(cmd, unsecure = false, stdout = nil)
  puts "Executing #{cmd}" if !unsecure
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

namespace :path do
  desc "Print all iTunes backup paths"
  task :all do
    backup_dir = ENV['HOME'] + "/Library/Application\ Support/MobileSync/Backup"
    latest_backup = nil
    Dir.foreach(backup_dir) do |item|
      next if item == '.' or item == '..' or item == '.DS_Store'
      f = File.new("#{backup_dir}/#{item}")
      puts "#{f.path} --- MODIFIED:#{f.ctime}"
    end
  end

  desc "Print the path to your most recent iTunes backup"
  task :recent do
    puts get_latest_backup.path
  end
end

desc "Backup Message attachments"
task :backup_sms do

end

desc "Print SMS text, date and sender"
task :sms do
  backup = get_latest_backup
  iphone_sms_db_name = "#{backup.path}/3d0d7e5fb2ce288813306e4d4636395e047a3d28"
  puts "DB Name: #{iphone_sms_db_name}"
  db = SQLite3::Database.new iphone_sms_db_name
  print_tables(db)
  db.execute("SELECT h.ROWID, m.ROWID, m.handle_id, h.id, m.is_from_me, m.text, m.date FROM message AS m JOIN handle AS h ON m.handle_id==h.ROWID ORDER BY h.id, m.date") do |message|
    puts "#{message}".colorize(message[4]==1 ? :blue : :green)
  end
end

desc "Print Contacts"
task :contacts do
  backup = get_latest_backup
  contacts_db_path = "#{backup.path}/75b12106910f0b106f64d72eb75397427884fd5a"
  puts "DB Name: #{contacts_db_path}"
  db = SQLite3::Database.new contacts_db_path
  print_tables(db)
  db.execute("SELECT * FROM contacts WHERE kind!='map-location'") do |contact|
    puts "#{contact}"
  end
end

desc "Print Calls"
task :calls do
  backup = get_latest_backup
  calls_db_path = "#{backup.path}/2b2b0084a1bc3a5ac8c27afdf14afb42c61a19ca"
  puts "DB Name: #{calls_db_path}"
  db = SQLite3::Database.new calls_db_path
  print_tables(db)
  db.execute("SELECT * FROM call") do |call|
    puts "#{call}"
  end
end

namespace :export do
  desc "Export sms conversations to a csv file"
  task :sms_csv do
    backup = get_latest_backup
    iphone_sms_db_name = "#{backup.path}/3d0d7e5fb2ce288813306e4d4636395e047a3d28"
    db = SQLite3::Database.new iphone_sms_db_name
    csv = "Address,FromMe,Contact,Date,Content,HadAttachment"
    db.execute("SELECT h.ROWID, m.ROWID, m.handle_id, h.id, m.is_from_me, m.text, m.date FROM message AS m JOIN handle AS h ON m.handle_id==h.ROWID ORDER BY h.id, m.date") do |msg|
      date = DateTime.strptime("#{msg[6] + 978307200}", '%s')
      content = msg[5]
      content = content.gsub(/\n/, " ") unless !content
      csv += "\n\"#{msg[3]}\",#{msg[4] == 1 ? "Yes" : "No"},\"#{"Unknown"}\",\"#{date}\",\"#{content}\",#{msg[7]==1 ? "Yes" : "No"}"
    end
    File.open('./export/sms.csv', 'w') { |file| file.write(csv) }
    Launchy.open("./export/sms.csv")
  end

  desc "Export images and videos into organized folders"
  task :attachments do
    system("mkdir -p ./export/videos") or puts "videos directory already exists"
    files = get_attachment_paths
    files.each { |attachment|
      f = File.new(attachment[0])
      date = DateTime.strptime("#{attachment[1] + 978307200}", '%s')
      sender = attachment[3]
      sender.slice! '+'
      filename = date.strftime("%Y_%m_%d_H%HM%MS%S_#{sender}")
      if attachment[2].include? 'image/'
        directory = "./export/images/#{date.year}/#{date.month}"
        system("mkdir -p #{directory}") or puts "Unable to create directory: #{directory}"
        extension = attachment[2]
        extension.slice! 'image/'
        command = "cp '#{attachment[0]}' #{directory}/#{filename}.#{extension}"
        system(command) or puts "Unable to execute:\n#{command}".red
      elsif attachment[2].include? 'video/'
        system("cp '#{attachment[0]}' ./export/videos/#{filename}.mov") or puts "Unable to copy video:\n#{filename}".red
      end
    }
  end

  desc "ExportCreate and open an HTML page of SMS image attachments"
  task :attachments_html do
    files = get_attachment_paths
    html = "<!DOCTYPE html><html><style>.thumb { max-width: 250px; max-height: 250px; }</style><body>"
    files.each { |attachment|
      f = File.new(attachment[0])
      if attachment[2].include? 'image/'
        html += "\n<img class='thumb' src='#{f.path}'>"
      end
    }
    html += "</body></html>"
    system("mkdir ./export") or puts "Unable to make 'export' directory".red
    File.open('./export/sms_images.html', 'w') { |file| file.write(html) }
    Launchy::Browser.run("./export/sms_images.html")
  end
end

namespace :tables do
  desc "List Tables with schema in each backup file"
  task :schema do
    eachDatabase(get_latest_backup.path) do |db, db_path|
      puts "#{db_path}".yellow
      print_tables(db)
    end
  end

  desc "List Tables names in each backup file"
  task :names do
    eachDatabase(get_latest_backup.path) do |db, db_path|
      puts "#{db_path}".yellow
      print_tables(db, true)
    end
  end

  desc "List Table schemas where search query is present"
  task :search, [:query] do |t, args|
    q = args[:query]
    eachDatabase(get_latest_backup.path) do |db, db_path|
      found = false
      output = "#{db_path}".yellow
      db.execute( "SELECT name FROM sqlite_master WHERE type='table'" ) do |row|
        tablename = row[0]
        if tablename.include? q
          output += "\n#{tablename}".blue.on_black.bold
          found = true
        else
          output += "\n#{tablename}".blue
        end
        db.execute("PRAGMA table_info('#{tablename}')") do |r|
          if r.include? q
            output += "\n#{r}".white.on_black.bold
            found = true
          else
            output += "\n#{r}"
          end
        end
      end
      puts output if found
    end
  end
end

desc "List file types in backup"
task :file_types do
  backup_path = get_latest_backup.path
  Dir.foreach(backup_path) do |item|
    IO.popen(["file", "-Ib", "#{backup_path}/#{item}"], in: :close, err: :close) { |io| puts "#{item} #{io.read.chomp}" }
  end
end

def get_latest_backup
  backup_dir = ENV['HOME'] + "/Library/Application\ Support/MobileSync/Backup"
  latest_backup = nil
  Dir.foreach(backup_dir) do |item|
    next if item == '.' or item == '..' or item == '.DS_Store'
    f = File.new("#{backup_dir}/#{item}")
    latest_backup = f unless latest_backup && latest_backup.ctime > f.ctime
  end
  latest_backup
end

def eachDatabase(backup_path, print_path=true)
  Dir.foreach(backup_path) do |item|
    next if item == '.' or item == '..' or item == '.DS_Store'
    db_path = "#{backup_path}/#{item}"
    begin
      db = SQLite3::Database.new db_path
      db.execute("pragma schema_version")
      yield db, db_path
      db.close
    rescue SQLite3::NotADatabaseException
      # swallow
    rescue Exception => e
      puts "EXCEPTION in #{db_path}:\n#{e}".red
    end
  end
end

def get_attachment_paths
  backup = get_latest_backup
  iphone_sms_db_name = "#{backup.path}/3d0d7e5fb2ce288813306e4d4636395e047a3d28"
  db = SQLite3::Database.new iphone_sms_db_name
  files = Array.new
  db.execute( "select m.ROWID, a.ROWID, attachment_id, message_id, filename, created_date, mime_type, m.handle_id, h.id from message_attachment_join AS jt JOIN message AS m ON m.ROWID==jt.message_id JOIN attachment AS a ON a.ROWID==jt.attachment_id JOIN handle AS h ON m.handle_id==h.ROWID" ) do |attachment|
    filename = attachment[4]
    next if !filename
    filename.sub! '~/', 'MediaDomain-' unless !filename
    filename = Digest::SHA1.hexdigest filename
    files.push(["#{backup.path}/#{filename}", attachment[5], attachment[6], attachment[8]])
  end
  files
end

def print_tables(db, hide_schema=false)
  db.execute( "SELECT name FROM sqlite_master WHERE type='table'" ) do |row|
    tablename = row[0]
    puts "#{tablename}".blue
    next if hide_schema

    db.execute("SELECT Count(*) FROM #{tablename}") do |c|
      puts "Rows: #{c[0]}"
    end
    db.execute("PRAGMA table_info('#{tablename}')") do |r|
      puts "#{r}"
    end
  end
end

def find_in_schema(db, query)
  listed_details = false
  db.execute( "SELECT name FROM sqlite_master WHERE type='table'" ) do |row|
    puts "Connected to: #{database_name}".yellow unless listed_details
    listed_details = true
    tablename = row[0]
    puts "#{tablename}".blue
    if !names_only
      db.execute("SELECT Count(*) FROM #{tablename}") do |c|
        puts "Rows: #{c[0]}"
      end
      db.execute("PRAGMA table_info('#{tablename}')") do |r|
        puts "#{r}"
      end
    end
  end
end

def print_plist(plist_blob)
  plist = CFPropertyList::List.new(:data => plist_blob)
  puts "#{CFPropertyList.native_types(plist.value).keys}".green
end