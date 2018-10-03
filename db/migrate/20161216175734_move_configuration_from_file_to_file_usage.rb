# This migration comes from pageflow (originally 20161216175734)
class MoveConfigurationFromFileToFileUsage < ActiveRecord::Migration
  def up
    add_column :pageflow_file_usages, :configuration, :text

    {
      pageflow_image_files: 'Pageflow::ImageFile',
      pageflow_video_files: 'Pageflow::VideoFile',
      pageflow_audio_files: 'Pageflow::AudioFile'
    }.each do |table_name, type_name|

# POSTGRES
      if Regexp.new("postgres", Regexp::IGNORECASE).match(ActiveRecord::Base.connection.adapter_name)
        sql = <<-SQL
          UPDATE pageflow_file_usages
          SET configuration = #{table_name}.configuration
          FROM #{table_name}
          WHERE
            pageflow_file_usages.file_type = '#{type_name}' AND
            pageflow_file_usages.file_id = #{table_name}.id 
        SQL
       
  # MYSQL
      elsif Regexp.new("mysql", Regexp::IGNORECASE).match(ActiveRecord::Base.connection.adapter_name)    
        sql = <<-SQL
          UPDATE pageflow_file_usages
          INNER JOIN #{table_name} ON
            pageflow_file_usages.file_id = #{table_name}.id AND
            pageflow_file_usages.file_type = "#{type_name}"
          SET pageflow_file_usages.configuration = #{table_name}.configuration
        SQL
      end
      execute(sql)
    end

    remove_column :pageflow_image_files, :configuration
    remove_column :pageflow_video_files, :configuration
    remove_column :pageflow_audio_files, :configuration
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
