require './environment'

task default: %w[broadcast_results]

task environment: :dotenv do
  Optimizely::Client.api_token = ENV.fetch('OPTIMIZELY_API_TOKEN')
end

EXPERIMENTS_CACHE_PATH = './.experiments'
JIRA_TICKET_REGEX = /\A\[?([A-Za-z]{2,30}-[0-9]+)\]?\_?/

task broadcast_results: :environment do
  client = Optimizely::Client.new
  slack_channel = ENV.fetch("SLACK_CHANNEL_ID") { raise "SLACK_CHANNEL_ID is not configured!" }
  project_ids = ENV.fetch('PROJECT_ID').split(',')
  project_ids.each do |project_id|
    project = get_project(project_id)
    project_url = "https://app.optimizely.com/v2/projects/#{project_id}/experiments"
    running_experiments = get_experiments(project_id).select { |experiment| experiment["status"] == "running" }
    running_experiments.each do |experiment|
      metadata = experiment_metadata(experiment)
      results = get_results(experiment.id)
      next if results.nil?

      results_url = "https://app.optimizely.com/v2/projects/#{project_id}/results/#{experiment.id}?previousView=EXPERIMENTS"
      blocks = []
      blocks << slack_block_section(":zap: *#{metadata[:pretty_name]}* (#{project.name})")
      blocks << { type: "divider" }

      if experiment.variations.map { |v| v.weight }.uniq.sort == [0, 10_000]
        blocks << slack_block_section(":warning: *Variant at 100% detected!* Please systemize this experiment...")
      else
        results.metrics.first(1).each do |metric|
          baseline = metric.results.values.detect(&:is_baseline)
          blocks << slack_block_section("*#{metric.name}* #{'(PRIMARY)' if metric == results.metrics.first} against baseline 🧪 _#{baseline.name}_")

          metric.results.values.reject(&:is_baseline).map do |result|
            blocks << slack_block_section("🧪 _#{result.name}_ is performing at #{number_to_percentage(result.lift.value.to_f)} (#{friendly_lift_status result.lift.lift_status}) with #{number_to_percentage result.lift.significance, 0} significance.")
          end
        end

        blocks << slack_block_context("Results as of #{Time.now.strftime '%B %d, %Y %l:%M %p'}")
      end

      blocks << slack_block_actions([
        { text: ":optimizely: #{project.name}", url: project_url },
        { text: ":opitmizely: Full Results", url: results_url },
        { text: ":jira: #{metadata[:jira_ticket]}", url: metadata[:jira_ticket_url] },
      ])

      post_message_blocks slack_channel, blocks
      exit
    end
  end
end
