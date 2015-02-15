class DbQueryHelper
  def self.sms_query
    "SELECT h.ROWID, m.ROWID, m.handle_id, h.id, m.is_from_me, m.text, m.date FROM message AS m JOIN handle AS h ON m.handle_id==h.ROWID ORDER BY h.id, m.date"
  end
end
