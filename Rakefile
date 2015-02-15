require "sqlite3"
require "colorize"
require "cfpropertylist"
require 'digest/sha1'
require 'launchy'
require 'pry'
Dir["./helpers/*.rb"].each {|file| require file }

def system_or_exit(cmd, unsecure = false, stdout = nil)
  puts "Executing #{cmd}" if !unsecure
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

namespace :path do
  desc "Print all iTunes backup paths"
  task :all do
    backup_dir = ENV['HOME'] + "/Library/Application\ Support/MobileSync/Backup"
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
  iphone_sms_db_name = PathHelper.sms_database(get_latest_backup.path)
  puts "DB Name: #{iphone_sms_db_name}"
  db = SQLite3::Database.new iphone_sms_db_name
  db.execute("SELECT h.ROWID, m.ROWID, m.handle_id, h.id, m.is_from_me, m.text, m.date FROM message AS m JOIN handle AS h ON m.handle_id==h.ROWID ORDER BY h.id, m.date") do |message|
    puts "#{message}".colorize(message[4]==1 ? :blue : :green)
  end
end

desc "Print Contacts"
task :contacts do
  contacts_db_path = PathHelper.contacts_database(get_latest_backup.path)
  puts "DB Name: #{contacts_db_path}"
  db = SQLite3::Database.new contacts_db_path
  print_tables(db)
  db.execute("SELECT * FROM contacts WHERE kind!='map-location'") do |contact|
    puts "#{contact}"
  end
end

desc "Print Calls"
task :calls do
  calls_db_path = PathHelper.calls_database(get_latest_backup.path)
  puts "DB Name: #{calls_db_path}"
  db = SQLite3::Database.new calls_db_path
  print_tables(db)
  db.execute("SELECT * FROM call") do |call|
    puts "#{call}"
  end
end

desc "Print all image files"
task :images do
  count = 0
  eachFileWithMime(get_latest_backup.path) do |file_name, mime, total_count|
    if mime.include? "image"
      count += 1
      puts "#{count.to_s.rjust(5, ' ')} #{file_name} #{mime}"
    end
  end
end

desc "Creates ./export/image_links/ which contains symlinks to all image files"
task :images_link do
  backup_path = get_latest_backup.path
  system("mkdir -p ./export/image_links") or raise "Unable to create images_links directory"
  eachFileWithMime(backup_path) do |file_name, mime, total_count|
    if mime.include? "image"
      FileUtils.ln_s "#{backup_path}/#{file_name}", "./export/image_links/#{file_name}"
    end
  end
end

desc "Image database"
task :photos do
  db = SQLite3::Database.new PathHelper.photos_database(get_latest_backup.path)
  db.execute("SELECT * FROM all_photos") do |row|
    puts "#{row}"
  end
end

namespace :export do
  desc "Export sms conversations to a csv file"
  task :sms_csv do
    db = SQLite3::Database.new PathHelper.sms_database(get_latest_backup.path)
    csv = CsvHelper.sms_header
    db.execute(DbQueryHelper.sms_query) do |msg|
      csv += CsvHelper.row_with_message(msg)
    end
    FileHelper.save_and_open_csv(csv)
  end

  desc "Export images and videos into organized folders"
  task :attachments do
    files = get_attachment_paths
    files.each { |attachment|
      FileHelper.exportAttachment(attachment)
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
  eachFileWithMime(get_latest_backup.path) do |file_name, mime, count|
    puts "#{count.to_s.rjust(5, ' ')} #{file_name} #{mime}"
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

def eachFileWithMime(path)
  count = 1
  Dir.foreach(path) do |item|
    IO.popen(["file", "-Ib", "#{path}/#{item}"], in: :close, err: :close) { |io|
      mime = io.read.chomp
      yield item, mime, count
      count += 1
    }
  end
end

def get_attachment_paths
  iphone_sms_db_name = PathHelper.sms_database(get_latest_backup.path)
  db = SQLite3::Database.new iphone_sms_db_name
  files = Array.new
  db.execute( "select m.ROWID, a.ROWID, attachment_id, message_id, filename, created_date, mime_type, m.handle_id, h.id from message_attachment_join AS jt JOIN message AS m ON m.ROWID==jt.message_id JOIN attachment AS a ON a.ROWID==jt.attachment_id JOIN handle AS h ON m.handle_id==h.ROWID" ) do |attachment|
    filename = attachment[4]
    next if !filename
    filename.sub! '~/', 'MediaDomain-' unless !filename
    filename = Digest::SHA1.hexdigest filename
    files.push(["#{backup.path}/#{filename}", attachment[5], attachment[6], attachment[8], attachment[4]])
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

def convertDate(backupDate)
  DateTime.strptime("#{backupDate + 978307200}", '%s')
end

def print_plist(plist_blob)
  plist = CFPropertyList::List.new(:data => plist_blob)
  puts "#{CFPropertyList.native_types(plist.value).keys}".green
end
