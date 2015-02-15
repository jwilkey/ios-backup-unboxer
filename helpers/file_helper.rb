class FileHelper
  def self.exportAttachment(attachment)
    mime = attachment[2]
    media_path = mime.split('/').first + "s"
    if !['images','videos'].include? media_path
      return
    end

    date = convertDate(attachment[1])
    created_date = date.strftime("%m/%d/%Y %H:%M:%S")
    filename = attachment[4].split('/').last

    directory = "./export/#{media_path}/#{date.year}/#{date.month}"
    system("mkdir -p #{directory}") or puts "Unable to create directory: #{directory}".red
    file_path = "#{directory}/#{filename}"
    command = "cp '#{attachment[0]}' #{file_path}"
    puts "Copying #{attachment[4]}"
    system(command) or puts "Unable to execute:\n#{command}".red
    system("SetFile -d '#{created_date}' #{file_path}") or puts "Unable to set creator and created date".red
  end

  def self.save_and_open_csv(csv)
    File.open('./export/sms.csv', 'w') { |file| file.write(csv) }
    system("open ./export/sms.csv")
  end
end
