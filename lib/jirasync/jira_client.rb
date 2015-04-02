module JiraSync

    require 'httparty'
    require 'uri'
    require 'json'


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
            url = "#{@baseurl}/rest/api/latest/issue/#{jira_id}"
            auth = {:username => @username, :password => @password}
            response = HTTParty.get url, {:basic_auth => auth, :timeout => @timeout}
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def latest_issue_for_project(project_id)
            url = "#{@baseurl}/rest/api/2/search?"
            auth = {:username => @username, :password => @password}

            response = HTTParty.get url, {
                :basic_auth => auth,
                :query => {:jql => 'project="' + project_id + '" order by created', fields: 'summary,updated', maxResults: '1'},
                :timeout => @first_requets_timeout
            }
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def changed_since(project_id, date)
            url = "#{@baseurl}/rest/api/2/search?"
            auth = {:username => @username, :password => @password}
            jql = 'project = "' + project_id + '" AND updated > ' + (date.to_time.to_i * 1000).to_s
            # "' + date.to_s + '"'
            response = HTTParty.get url, {
                :basic_auth => auth,
                :query => {:jql => jql, fields: 'summary,updated', maxResults: '1000'},
                :timeout => @timeout
            }
            if response.code == 200
                response.parsed_response
            else
                raise FetchError.new(response.code, url)
            end
        end

        def project_info(project_id)
            url = "#{@baseurl}/rest/api/2/project/#{project_id}"
            auth = {:username => @username, :password => @password}
            response = HTTParty.get url, {
                :basic_auth => auth,
                :query => {:jql => 'project="' + project_id + '"', fields: 'summary,updated', maxResults: '50'},
                :timeout => @timeout
            }
            if response.code == 200
                response.parse_response
            else
                raise FetchError(response.code, url)
            end

        end
    end
end



