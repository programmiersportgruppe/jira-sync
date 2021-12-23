module JiraSync

    require 'httparty'
    require 'uri'
    require 'json'
    require 'parallel'


    class FetchError < StandardError
        attr_reader :status, :url

        def initialize(status, url)
            @status = status
            @url= url
        end

        def to_s
            "Got status #{status} for #{url}"
        end
    end


    class JiraClient

        def initialize(baseurl, username, password)
            @username = username
            @password = password
            @baseurl = baseurl
            @timeout = 15
            @first_requets_timeout = 60
        end

        def get(jira_id)
            api_get "issue/#{jira_id}"
        end

        def attachments_for_issue(issue)
            attachments = []
            Parallel.map(issue['fields']['attachment'], :in_threads => 64) do |attachment|
                response = http_get attachment['content']
                attachments.push({:data => response.body, :attachment => attachment, :issue => issue})
            end
            attachments
        end

        def latest_issue_for_project(project_id)
            api_get "search",
                query: {:jql => 'project="' + project_id + '" order by created', fields: 'summary,updated', maxResults: '1'},
                timeout: @first_requets_timeout
        end

        def changed_since(project_id, date)
            jql = 'project = "' + project_id + '" AND updated > ' + (date.to_time.to_i * 1000).to_s
            # "' + date.to_s + '"'
            api_get "search", query: {:jql => jql, fields: 'summary,updated', maxResults: '1000'}
        end

        def project_info(project_id)
            api_get "project/#{project_id}", query: {:jql => 'project="' + project_id + '"', fields: 'summary,updated', maxResults: '50'}
        end

        private def api_get(relative_path)
            http_get "#{@baseurl}/rest/api/2/#{relative_path}"
        end

        private def http_get(url, query: nil, timeout: @timeout)
            auth = {:username => @username, :password => @password}
            response = HTTParty.get url, {
                :basic_auth => auth,
                :query => query,
                :timeout => timeout,
            }
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end
    end
end



