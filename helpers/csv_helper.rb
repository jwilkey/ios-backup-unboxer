class CsvHelper
  def self.sms_header
    "Address,FromMe,Contact,Date,Content,HadAttachment"
  end

  def self.row_with_message(msg)
    date = convertDate(msg[6])
    content = msg[5]
    content = content.gsub(/\n/, " ") unless !content
    "\n\"#{msg[3]}\",#{msg[4] == 1 ? "Yes" : "No"},\"#{"Unknown"}\",\"#{date}\",\"#{content}\",#{msg[7]==1 ? "Yes" : "No"}"
  end

  def self.convertDate(backupDate)
    DateTime.strptime("#{backupDate + 978307200}", '%s')
  end
end
