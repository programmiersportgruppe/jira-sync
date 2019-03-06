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


    class JiraAuthentication
        attr_reader :options

        def initialize(options)
            @options = options
        end
    end


    class UsernamePasswordAuthentication < JiraAuthentication
        attr_reader :username

        def initialize(username, password)
            super({
                :basic_auth => {
                    :username => username,
                    :password => password,
                },
            })
            @username = username
        end
    end


    class CookieAuthentication < JiraAuthentication
        attr_reader :cookie

        def initialize(cookie)
            super({
                :headers => {
                    "Cookie" => cookie,
                },
            })
            @cookie = cookie
        end
    end


    class JiraClient

        def initialize(baseurl, authentication)
            @authentication = authentication
            @baseurl = baseurl
            @timeout = 15
            @first_requets_timeout = 60
        end



        def get(jira_id)
            url = "#{@baseurl}/rest/api/latest/issue/#{jira_id}"
            response = HTTParty.get url, @authentication.options.merge({:timeout => @timeout})
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def attachments_for_issue(issue)
            attachments = []
            Parallel.map(issue['fields']['attachment'], :in_threads => 64) do |attachment|
                response = HTTParty.get attachment['content'], @authentication.options.merge({:timeout => @timeout})
                if response.code == 200
                    attachments.push({:data => response.body, :attachment => attachment, :issue => issue})
                else
                    raise FetchError.new(response.code, url)
                end
            end
            
            attachments
        end

        def latest_issue_for_project(project_id)
            url = "#{@baseurl}/rest/api/2/search?"

            response = HTTParty.get url, @authentication.options.merge({
                :query => {:jql => 'project="' + project_id + '" order by created', fields: 'summary,updated', maxResults: '1'},
                :timeout => @first_requets_timeout
            })
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def changed_since(project_id, date)
            url = "#{@baseurl}/rest/api/2/search?"
            jql = 'project = "' + project_id + '" AND updated > ' + (date.to_time.to_i * 1000).to_s
            # "' + date.to_s + '"'
            response = HTTParty.get url, @authentication.options.merge({
                :query => {:jql => jql, fields: 'summary,updated', maxResults: '1000'},
                :timeout => @timeout
            })
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def project_info(project_id)
            url = "#{@baseurl}/rest/api/2/project/#{project_id}"
            response = HTTParty.get url, @authentication.options.merge({
                :query => {:jql => 'project="' + project_id + '"', fields: 'summary,updated', maxResults: '50'},
                :timeout => @timeout
            })
            if response.code == 200
                response.parse_response
            else
                raise FetchError(response.code, url)
            end

        end
    end
end



