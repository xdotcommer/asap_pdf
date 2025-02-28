class ConfigurationsController < ApplicationController
  def edit
    @config = JSON.parse(File.read(Rails.root.join("python_components", "config.json")))
    models_data = JSON.parse(File.read(Rails.root.join("python_components", "models.json")))
    @models = models_data.keys
  end

  def update
    config_path = Rails.root.join("python_components", "config.json")
    config = JSON.parse(File.read(config_path))

    config["active_model"] = params[:config][:active_model]
    config["key"] = params[:config][:key]
    config["page_limit"] = params[:config][:page_limit].to_i
    config["prompt"] = params[:config][:prompt]

    File.write(config_path, JSON.pretty_generate(config))
    redirect_to edit_configuration_path, notice: "Configuration updated successfully"
  rescue => e
    redirect_to edit_configuration_path, alert: "Error updating configuration: #{e.message}"
  end
end
