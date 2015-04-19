module JiraSync
    require 'fileutils'
    require 'json'


    class LocalIssueRepository

        def initialize(path, attachments_path=nil)
            @path = path
            FileUtils::mkdir_p @path
            @attachments_path = attachments_path
            FileUtils::mkdir_p @attachments_path unless @attachments_path == nil
        end

        def save(issue, attachments=[])
            json = JSON.pretty_generate(issue)
            file_path = "#{@path}/#{issue['key']}.json"
            File.write(file_path, json)

            if stores_attachments? then
                attachments.each do |attachment|
                    save_attachment(attachment[:issue], attachment[:attachment], attachment[:data])
                end
            end

            updateTime = DateTime.parse(issue['fields']['updated'])

            File.utime(DateTime.now.to_time, updateTime.to_time, file_path)
        end

        def state_exists?
            file_path = "#{@path}/sync_state.json"
            File.exist?(file_path)
        end

        def save_state(state)
            json = JSON.pretty_generate(state)
            file_path = "#{@path}/sync_state.json"
            File.write(file_path, json)
        end

        def load_state()
            file_path = "#{@path}/sync_state.json"
            if (!File.exists?(file_path))
                raise ("File '#{file_path}' with previous sync state could not be found\n" +
                          "please run an initial fetch first")
            end
            s = IO.read(file_path)
            JSON.parse(s)
        end
        
        def stores_attachments?
            @attachments_path != nil
        end
        
        def save_attachment(issue, attachment, data)
            file_path = "#{@attachments_path}/#{issue['key']} #{attachment['id']} #{attachment['filename']}"
            File.write(file_path, data, {:mode => 'wb'})
        end
    end
end
