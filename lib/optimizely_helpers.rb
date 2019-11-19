module OptmizelyHelpers
  CACHE_PATH = "./.optimizely-cache"

  def use_cache?
    ActiveModel::Type::Boolean.new.cast ENV.fetch('USE_CACHE', 'true')
  end

  def use_results_cache?
    return false if !use_cache?
    ActiveModel::Type::Boolean.new.cast ENV.fetch('USE_RESULTS_CACHE', 'true') # default should be false
  end

  def get_project(project_id)
    project_from_yaml(project_id) || project_from_api(project_id)
  end

  def get_experiments(project_id)
    experiments_from_yaml(project_id) || experiments_from_api(project_id)
  end

  def get_results(experiment_id)
    results_from_yaml(experiment_id) || results_from_api(experiment_id)
  end

  def project_cache_path(project_id)
    File.join(CACHE_PATH,"project-#{project_id}.yml")
  end

  def experiments_cache_path(project_id)
    File.join(CACHE_PATH,"project-#{project_id}-experiments.yml")
  end

  def results_cache_path(experiment_id)
    File.join(CACHE_PATH,"results-#{experiment_id}.yml")
  end

  def project_from_yaml(project_id)
    return unless use_cache?
    path = project_cache_path(project_id)
    return unless File.exist?(path)
    YAML.load(File.open(path))
  end

  def results_from_yaml(experiment_id)
    return unless use_results_cache?
    path = results_cache_path(experiment_id)
    return unless File.exist?(path)
    YAML.load(File.open(path))
  end

  def experiments_from_yaml(project_id)
    return unless use_cache?
    path = experiments_cache_path(project_id)
    return unless File.exist?(path)
    YAML.load(File.open(path))
  end

  def project_from_api(project_id)
    Optimizely::Client.new.project(project_id: project_id).tap do |project|
      File.open(project_cache_path(project_id), "w") { |f| YAML.dump project, f }
    end
  end

  def experiments_from_api(project_id)
    Optimizely::Client.new.experiments(project_id: project_id).tap do |experiments|
      File.open(experiments_cache_path(project_id), "w") { |f| YAML.dump experiments, f }
    end
  end

  def results_from_api(experiment_id)
    Optimizely::Client.new.results(experiment_id: experiment_id).tap do |results|
      File.open(results_cache_path(experiment_id), "w") { |f| YAML.dump results, f }
    end
  end

  def extra_jira_metadata(experiment)
    {}.tap do |meta|
      return {} unless ENV['JIRA_URL']
      meta[:jira_ticket] = experiment.name.scan(JIRA_TICKET_REGEX).try(:flatten).try(:first).try(:upcase)
      meta[:jira_ticket_url] = "https://#{ENV.fetch('JIRA_URL')}/browse/#{meta[:jira_ticket]}" if meta[:jira_ticket]
    end
  end

  def experiment_metadata(experiment)
    {}.tap do |meta|
      meta.merge! extra_jira_metadata(experiment)
      meta[:pretty_name] = experiment.name.gsub(JIRA_TICKET_REGEX, '').strip.squish

      if meta[:pretty_name].include?(" ")
        # already humanized?
      elsif meta[:pretty_name].blank?
        if meta[:jira_ticket]
          meta[:pretty_name] = "Experiment for #{meta[:jira_ticket]}" # get JIRA ticket name from API?
        else
          meta[:pretty_name] = experiment.name
        end
      else
        meta[:pretty_name] = meta[:pretty_name].underscore.humanize.titleize
      end
    end
  end

  def number_to_percentage(number, precision = 2)
    "#{(number * 100.0).round(precision)}%"
  end

  def friendly_lift_status(status)
    case status.to_sym
    when :equal
      "flat"
    else
      status
    end
  end
end
