Shoes.app do
  def stop_anim
    @anim.stop
    @anim = nil
  end

  def slide_anim &blk
    stop_anim if @anim
    @anim = animate 30, &blk
  end

  def slide_out slot
    slide_anim do |i|
      slot.height = 150 - (i * 3)
      slot.contents[0].top = -i * 3
      if slot.height == 0
        stop_anim
        slot.hide
      end
    end
  end

  def slide_in slot
    slot.show
    slide_anim do |i|
      slot.height = i * 6
      slot.contents[0].top = slot.height - 150
      stop_anim if slot.height == 150
    end
  end

  background white
  stack margin: 10 do
    para link("slide out") { slide_out @lipsum }, " | ",
      link("slide in") { slide_in @lipsum }
    @lipsum = stack width: 1.0, height: 150 do
      stack do
        background "#ddd"
        border "#eee", strokewidth: 5
        para "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed " +
               "do eiusmod tempor incididunt ut labore et dolore magna " +
               "aliqua. Ut enim ad minim veniam, quis nostrud exercitation " +
               "ullamco laboris nisi ut aliquip ex ea commodo consequat. " +
               "Duis aute irure dolor in reprehenderit in voluptate velit " +
               "esse cillum dolore eu fugiat nulla pariatur. Excepteur sint " +
               "occaecat cupidatat non proident, sunt in culpa qui officia " +
               "deserunt mollit anim id est laborum.",
             margin: 10
      end
    end
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
  puts "Latest backup:  #{latest_backup.path} --- #{latest_backup.ctime}"
  latest_backup
end

def sms_attachments
  backup = get_latest_backup
  iphone_sms_db_name = "#{backup.path}/3d0d7e5fb2ce288813306e4d4636395e047a3d28"
  puts "DB Name: #{iphone_sms_db_name}"
  db = SQLite3::Database.new iphone_sms_db_name
  print_tables(db, iphone_sms_db_name)
  attachment_files = Array.new
  db.execute( "select m.ROWID, a.ROWID, attachment_id, message_id, filename from message_attachment_join AS jt JOIN message AS m ON m.ROWID==jt.message_id JOIN attachment AS a ON a.ROWID==jt.attachment_id" ) do |attachment|
    filename = attachment[4]
    next if !filename
    puts "#{filename}"
    filename.sub! '~/', 'MediaDomain-' unless !filename
    filename = Digest::SHA1.hexdigest filename
    puts "#{backup.path}/#{filename}".green
    attachment_files.push("#{backup.path}/#{filename}")
  end
  attachment_files
end
