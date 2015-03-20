module JiraSync
    require 'parallel'
    require 'json'
    require 'date'

    class Syncer

        def initialize(client, repo, project_key)
            @client = client
            @project_key = project_key
            latest_issue = @client.latest_issue_for_project(@project_key)['issues'][0]
            @latest_issue_key = latest_issue['key'].split("-")[1].to_i
            @repo = repo
        end

        # Fetches a number of tickets in parallel
        # prints progress information to stderr
        # and returns a list of tickets that
        # couldn't be fetched.
        def fetch(keys)
            keys_with_errors = []
            Parallel.each_with_index(keys, :in_threads => 64) do |key, index|
                STDERR.puts(key) if ((index % 100) == 0)
                begin
                    issue = @client.get(key)
                    issue_project_key = issue['fields']['project']['key']
                    if (issue_project_key == @project_key)
                        @repo.save(issue)
                    else
                        STDERR.puts("Skipping ticket #{key} which has moved to #{issue_project_key}.")
                    end

                rescue FetchError => e
                    if (e.status != 404)
                        STDERR.puts(e.to_s)
                        keys_with_errors.push(key)
                    end
                rescue => e
                    STDERR.puts(e.to_s)
                    keys_with_errors.push(key)
                end
            end
            keys_with_errors.sort
        end

        def fetch_all
            start_time = DateTime.now

            keys = (1..@latest_issue_key).map { |key_number| @project_key + "-" + key_number.to_s }
            keys_with_errors = fetch(keys)

            @repo.save_state({"time" => start_time, "errors" => keys_with_errors})
        end

        def update()
            state = @repo.load_state()
            start_time = DateTime.now
            since = DateTime.parse(state['time']).new_offset(0)
            STDERR.puts("Fetching issues that have changes since #{since.to_s}")
            issues = @client.changed_since(@project_key, since)['issues'].map { |issue| issue['key'] }
            STDERR.puts("Updated Issues")
            STDERR.puts(issues.empty? ?  "None" : issues.join(", "))
            STDERR.puts("Issues with earlier errors")
            STDERR.puts(state['errors'].empty? ? "None" : state['errors'].join(", "))
            keys_with_errors = fetch(issues + state['errors'])
            @repo.save_state({"time" => start_time, "errors" => keys_with_errors})
        end

        def dump()
            puts(@latest_issue_key)

        end
    end
end