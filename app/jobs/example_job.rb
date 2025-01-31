class ExampleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Add your job logic here
    Rails.logger.info "ExampleJob performed with arguments: #{args.inspect}"
    sleep 2 # Simulate some work being done
    Rails.logger.info "ExampleJob completed"
  end
end
