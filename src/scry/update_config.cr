require "./log"
require "./workspace"
require "./settings"

module Scry
  struct UpdateConfig
    LOG_LEVELS = {
      "debug" => Logger::DEBUG,
      "info"  => Logger::INFO,
      "warn"  => Logger::WARN,
      "error" => Logger::ERROR,
      "fatal" => Logger::FATAL,
    }

    def initialize(@workspace : Workspace, @settings : LSP::Protocol::DidChangeConfigurationParams)
    end

    def initialize(@workspace : Workspace, @settings)
      raise "Can't update settings with #{settings.inspect}"
    end

    def run
      @workspace.max_number_of_problems = customizations.max_number_of_problems
      Log.logger.level = log_level(customizations.log_level || "error")
      Log.logger.info("Scry Configuration Updated:\n #{@settings.to_json}")
      {@workspace, nil}
    end

    private def customizations
      Settings.from_json(@settings.settings.to_json).crystal_config
    end

    private def log_level(level : String)
      LOG_LEVELS[level]
    end
  end
end
