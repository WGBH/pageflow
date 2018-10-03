# This migration comes from pageflow (originally 20170315130000)
class AddThemeNameToRevisions < ActiveRecord::Migration
  def change
    add_column :pageflow_revisions, :theme_name, :string, null: false, default: 'default'

# POSTGRES
    if Regexp.new("postgres", Regexp::IGNORECASE).match(ActiveRecord::Base.connection.adapter_name)
      sql = <<-SQL
        UPDATE pageflow_revisions
        SET theme_name = pageflow_themings.theme_name
        FROM pageflow_entries INNER JOIN pageflow_themings ON pageflow_entries.theming_id = pageflow_themings.id
        WHERE 
          pageflow_revisions.entry_id = pageflow_entries.id
      SQL

# MYSQL
    elsif Regexp.new("mysql", Regexp::IGNORECASE).match(ActiveRecord::Base.connection.adapter_name)    
      sql = <<-SQL
        UPDATE pageflow_revisions, pageflow_entries, pageflow_themings
        SET pageflow_revisions.theme_name = pageflow_themings.theme_name
        WHERE pageflow_revisions.entry_id = pageflow_entries.id
        AND pageflow_entries.theming_id = pageflow_themings.id
      SQL
    end
    execute(sql)
  end
end
