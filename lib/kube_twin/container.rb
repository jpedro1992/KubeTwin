# frozen_string_literal: true

require_relative './logger'
require_relative './event'
require 'erv'
require 'pycall'
require 'pycall/import'
include PyCall::Import

module KUBETWIN
  class RequestInfo < Struct.new(:request, :service_time, :arrival_time)
    include Comparable
    def <=>(other)
      arrival_time <=> other.arrival_time
    end
  end

  class Container
    SEED = 123

    # states
    CONTAINER_WAITING      = 0      # still running the operations it requires in order to complete start up
    CONTAINER_RUNNING      = 1      # executing without issues
    CONTAINER_TERMINATED   = 2      # began execution and then either ran to completion or failed for some reason

    # no need for :port now
    attr_reader :containerId,
                :imageId,
                :endCode,
                :name,
                :state,
                :wait_for,
                :service_time,
                :request_queue,
                :served_request,
                :total_queue_time,
                :containers_to_free,
                :busy,
                :total_queue_processing_time # endCode = 0 if all operations successfull, 0 if there's any kind of error

    Guaranteed = Struct.new(:cpu, :memory)
    Limits = Struct.new(:cpu, :memory)

    def initialize(containerId, imageId, st_distribution, opts = {})
      @containerId = containerId
      @imageId = imageId
      @state = Container::CONTAINER_WAITING
      @limits = Limits.new(500, 500)
      @guaranteed = Guaranteed.new(500, 500)
      @startedTime = Time.now
      @state = CONTAINER_WAITING
      @name = opts[:label]
      @replica_set = opts[:replica_set]

      @blocking = opts[:blocking].nil? || opts[:blocking]

      # node info
      @node = opts[:node]
      @wait_for = opts[:img_info][:wait_for].nil? ? [] : opts[:img_info][:wait_for]

      @busy           = false
      @request_queue  = [] # queue incoming requests

      @trace = opts[:trace] ? true : false
      @working_time = 0.0
      # metric info -- first implementation
      @containers_to_free = []

      @served_request = 0
      @total_queue_processing_time = 0
      @total_queue_time = 0
      @last_request_time = nil
      @path = opts[:img_info][:mdn_file]
      @rps = opts[:img_info][:rps].to_i
      @service_time = ERV::RandomVariable.new(st_distribution) if @path.nil?
      @arrival_times = []
    end

    def check_rps(interval = 8)
      # @arrival_times.last(interval).reverse.inject(:-) / interval.to_f
      i = 0
      interarrival_times = 0.0
      @arrival_times.last(interval).reverse.each_slice(2) do |t, tl|
        break if t.nil? || tl.nil?

        # puts "t: #{t} tl: #{tl}"
        i += 1
        interarrival_times += t - tl
      end
      interarrival_times / i.to_f
    end

    def to_free(container)
      # add a chained container, which must wait
      # until the next workflow step is completed
      @containers_to_free << container
    end

    def free_linked_container
      # return the reference to the container
      # which was waiting the next step to be
      # completed
      @containers_to_free.shift
    end

    def reset_metrics
      @served_request = 0
      @total_queue_processing_time = 0
      @total_queue_time = 0
    end

    def startupC
      @state = Container::CONTAINER_RUNNING
    end

    def new_request(sim, r, time)
      # improve this code in the future
      r.arrival_at_container = time
      rps = @rps
      # s_time = calculate_service_time(sim)
      @service_time = sim.retrieve_mdn_model(name, rps) unless @path.nil?
      @last_request_time = time
      while (st = @service_time.sample) <= 1E-6; end

      ri = RequestInfo.new(r, st, time)
      @request_queue << ri

      if @trace
        puts '***'
        @request_queue.each_cons(2) do |x, y|
          puts "#{x[2]},#{y[2]},#{y[2] - x[2]}"
          raise 'Inconsistent ordering in request_queue!' if y[2] < x[2]
        end
        puts '***'
      end

      try_servicing_new_request(sim, time) unless @busy
    end

    def request_finished(sim, time)
      @busy = false
      # update also the metrics
      @served_request += 1
      try_servicing_new_request(sim, time) unless @busy
    end

    def calculate_service_time(sim)
      unless @path.nil?
        if @arrival_times.length < 2
          rps = if @rps.nil?
                  1 # default value for the current use-case
                else
                  @rps
                end
        else
          inter_arrival_times = check_rps
          # @logger.info "Inter_Arrival_time; #{inter_arrival_times}"
          if inter_arrival_times == 0.0
            raise 'Inter arrival time is zero'
            rps = 34
          else
            begin
              # rps = (1 / inter_arrival_times).ceil
              rps = (1 / inter_arrival_times.to_f)
              # ceil the rps to the second decimal digit
              rps = rps.round(1)
            rescue StandardError
              puts inter_arrival_times
              abort
            end
          end
        end
        # @logger.debug("Name: #{@name} Retrieved RPS: #{rps}")
        rps = 34 if rps > 34
      end
      if @name == 'FE1'
        # @logger.debug "Retrieved RPS: #{rps} for container #{@name} containerId: #{@containerId} queue size: #{@request_queue.size}"
      end
      @service_time = sim.retrieve_mdn_model(@name, @rps, @replica_set.replicas) unless @path.nil?
      while (st = @service_time.sample) <= 1E-5; end
      #       case @name
      #       when 'FE1'
      #         st *= 0.43
      #       when 'FE2'
      #         st *= 0.36
      #       when 'FE3'
      #         st *= 0.21
      #       else
      #         st
      #       end
      st
    end

    def try_servicing_new_request(sim, time)
      raise "Container is currently processing another request (id: #{@containerId})" if @busy

      return if @request_queue.empty? # || (@state == Container::CONTAINER_TERMINATED)

      # monkey patch for MQTT service
      @busy = @blocking == true
      # puts "Start: #{time}"
      ri = @request_queue.shift
      # puts "#{containerId} #{@request_queue.length} sr: #{served_request} #{time - ri.arrival_time}" if @request_queue.length > 2

      req = ri.request
      # update the request's working information

      # req.update_queuing_time(time - ri.arrival_time)
      req.update_queuing_time(time - req.arrival_at_container)
      s_time = calculate_service_time(sim)
      ri.service_time = s_time

      req.step_completed(ri.service_time)
      next_step = req.next_step

      # update container-based metric here
      @total_queue_time += time - ri.arrival_time
      # raise "We are looking at two different times" if req.queuing_time != (time - ri.arrival_time)
      @total_queue_processing_time += ri.service_time + (time - ri.arrival_time)
      # schedule completion of workflow step
      # puts "Finished #{time + ri.service_time} #{@request_queue.length}"
      sim.new_event(Event::ET_WORKFLOW_STEP_COMPLETED, [req, next_step], time + ri.service_time, self)
    end

    def request_resources(moreCpu)
      raise 'Impossible assign resources, container is still running' if @state == CONTAINER_RUNNING

      @guaranteed.cpu += moreCpu
      raise 'CPU limits error, too much resources in request' if @guaranteed.cpu > @limits.cpu

      @state = CONTAINER_WAITING

      puts 'Resources assigned, waiting for setup...'
      startupC
    end
  end
end
