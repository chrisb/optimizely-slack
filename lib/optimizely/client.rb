module Optimizely
  class Client
    include ActiveSupport::Configurable

    attr_reader :connection
    config_accessor :api_token

    API_BASE_URL = "https://api.optimizely.com/"

    def initialize
      @connection = Faraday.new(url: API_BASE_URL, headers: { "Authorization" => "Bearer #{api_token}" }) do |faraday|
        faraday.response :json
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
      end
    end

    def project(project_id:)
      Hashie::Mash.new get("/v2/projects/#{project_id}")
    end

    def experiments(project_id:)
      exps = []
      result = "not blank"
      page = 1
      until result.blank? do # pagination
        result = get "/v2/experiments", project_id: project_id, per_page: 100, page: page
        exps += result
        page += 1
      end

      exps.map do |e|
        e["experiment_key"] = e.delete("key")
        e["variations"].map! do |v|
          v["variation_key"] = v.delete("key")
          v.except "actions"
        end
        Hashie::Mash.new e.except("url_targeting")
      end
    end

    def results(experiment_id:)
      results = get("/v2/experiments/#{experiment_id}/results")
      return nil unless results
      results["reach"]["variations"].keys.each do |variation_id|
        results["reach"]["variations"][variation_id]["vistor_count"] =
          results["reach"]["variations"][variation_id].delete("count")
      end
      Hashie::Mash.new results
    end

    protected

    def get(*args)
      request(:get, *args)
    end

    def request(method, *args)
      @connection.send(method, *args).body
    end
  end
end
