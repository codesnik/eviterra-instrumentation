module Eviterra
  module Instrumentation
    def self.instrument(clazz, *methods)
      clazz.module_eval do
        methods.each do |m|
          namespace = clazz.name.underscore.gsub('/', '_')
          class_eval %{def #{m}_with_instrumentation(*args, &block)
            ActiveSupport::Notifications.instrumenter.instrument "http.#{namespace}", :name => "#{m}", :class => "#{clazz}" do
              #{m}_without_instrumentation(*args, &block)
            end
          end
          }

          alias_method_chain m, :instrumentation
        end
      end
    end

    class Railtie < Rails::Railtie
      initializer "eviterra.instrumentation" do |app|
        Eviterra::Instrumentation.instrument Curl::Easy, :perform
        Eviterra::Instrumentation.instrument Curl::Multi, :perform
        Eviterra::Instrumentation.instrument Net::HTTP, :request
        Eviterra::Instrumentation.instrument Typhoeus::Hydra, :run

        ActiveSupport.on_load(:action_controller) do
          include Eviterra::Instrumentation::ControllerRuntime
        end

        Eviterra::Instrumentation::LogSubscriber.attach_to :curl_easy
        Eviterra::Instrumentation::LogSubscriber.attach_to :curl_multi
        Eviterra::Instrumentation::LogSubscriber.attach_to :net_http
        Eviterra::Instrumentation::LogSubscriber.attach_to :typhoeus_hydra
      end
    end

    module ControllerRuntime
      extend ActiveSupport::Concern

      protected

      attr_internal :http_runtime

      def cleanup_view_runtime
        # Rails.logger.debug "cleanup_view"
        http_rt_before_render = Eviterra::Instrumentation::LogSubscriber.reset_runtime
        runtime = super
        http_rt_after_render = Eviterra::Instrumentation::LogSubscriber.reset_runtime
        self.http_runtime = http_rt_before_render + http_rt_after_render
        runtime - http_rt_after_render
      end

      def append_info_to_payload(payload)
        # Rails.logger.debug "append_info"
        super
        payload[:http_runtime] = http_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, http_runtime = super, payload[:http_runtime]
          messages << ("HTTP: %.1fms" % http_runtime.to_f) if http_runtime && http_runtime != 0
          messages
        end
      end
    end

    class LogSubscriber < ActiveSupport::LogSubscriber
      def self.runtime=(value)
        Thread.current["eviterra_http_runtime"] = value
      end

      def self.runtime
        Thread.current["eviterra_http_runtime"] ||= 0
      end

      def self.reset_runtime
        rt, self.runtime = runtime, 0
        rt
      end

      def http(event)
        debug color("HTTP #{event.payload[:class]}##{event.payload[:name]} (%.1fms)" % event.duration, GREEN)
        self.class.runtime += event.duration
      end
    end
  end
end
