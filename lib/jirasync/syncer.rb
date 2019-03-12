module JiraSync
    require 'parallel'
    require 'json'
    require 'date'

    class Syncer

        def initialize(client, repo, project_key, store_attachments)
            @client = client
            @project_key = project_key
            latest_issue = @client.latest_issue_for_project(@project_key)['issues'][0]
            @latest_issue_key = latest_issue['key'].split("-")[1].to_i
            @repo = repo
            @store_attachments = store_attachments
        end

        # Fetches a number of tickets in parallel
        # prints progress information to stderr
        # and returns a list of tickets that
        # couldn't be fetched.
        def fetch(keys)
            keys_with_errors = []
            tickets_moved = []
            Parallel.each_with_index(keys, :in_threads => 64, :progress => {title:"Fetching", output: STDERR}) do |key, index|
                begin
                    issue = @client.get(key)
                    issue_project_key = issue['fields']['project']['key']
                    if (issue_project_key == @project_key)
                        @repo.save(issue)
                        if @store_attachments
                            attachments = @client.attachments_for_issue(issue)
                            attachments.each do |attachment|
                                @repo.save_attachment(attachment[:issue], attachment[:attachment], attachment[:data])
                            end
                        end
                    else
                        tickets_moved.push(issue_project_key)
                    end

                rescue FetchError => e
                    if (e.status != 404)
                        keys_with_errors.push(key)
                    else
                        # Ticket has disappeared
                    end
                rescue => e
                    STDERR.puts(e.to_s)
                    keys_with_errors.push(key)
                end
            end
            keys_with_errors.sort!
            if !keys_with_errors.empty?
                STDERR.puts("Errors fetching these tickets: #{keys_with_errors.join(",")}")
            end
            keys_with_errors
        end

        # Fetches all tickets for the project
        def fetch_all
            start_time = DateTime.now

            keys = (1..@latest_issue_key).map { |key_number| @project_key + "-" + key_number.to_s }
            keys_with_errors = fetch(keys)

            @repo.save_state({"time" => start_time, "errors" => keys_with_errors})
        end

        # Fetches only tickets that have been changed/ added since the previous fetch/ update
        def update()
            state = @repo.load_state()
            start_time = DateTime.now
            since = DateTime.parse(state['time']).new_offset(0)
            STDERR.puts("Fetching issues that have been changed/ added since #{since.to_s}")
            issues = @client.changed_since(@project_key, since)['issues'].map { |issue| issue['key'] }
            STDERR.puts("Updated Issues: #{issues.empty? ?  "None" : issues.join(",")}")
            if !state['errors'].empty?
                STDERR.print("Retrying issues with earlier errors: ")
                STDERR.puts( state['errors'].join(","))
            end
            keys_with_errors = fetch(issues + state['errors'])
            @repo.save_state({"time" => start_time, "errors" => keys_with_errors, 'updated' => issues})
        end

        def dump()
            puts(@latest_issue_key)

        end
    end
end