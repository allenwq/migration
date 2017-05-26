class ProcessPool
  STOP = :stop
  attr_reader :running_pids

  def initialize(size)
    @size = size
    @jobs = Queue.new
    @running_pids = []

    @workers = (1..@size).map do
      thread = Thread.new do
        loop do
          job = @jobs.pop
          break if job == STOP
          @before_fork_proc.call if @before_fork_proc
          p = fork do
            if @around_job_proc
              @around_job_proc.call(&job)
            else
              job.call
            end
          end
          running_pids << p
          pid, status = Process.waitpid2(p)
          running_pids.delete(pid)

          if status.exitstatus != 0
            # This process just failed, terminate all other processes
            terminate!
            break
          end
        end
      end

      thread.abort_on_exception = true
      thread
    end
  end

  def schedule(&job)
    @jobs << job
  end

  def wait
    @size.times do
      @jobs << STOP
    end

    ret = @workers.each(&:join)

    @running_pids = []

    if errored?
      @errored = false
      raise 'An error occurred in one of the job.'
    end

    ret
  end

  def before_fork(&proc)
    @before_fork_proc = proc
  end

  def around_job(&proc)
    @around_job_proc = proc
  end

  def errored?
    @errored == true
  end

  # Kill all running processes
  def terminate!
    return if errored?
    @errored = true

    running_pids.each do |id|
      Process.kill('TERM', id)
    end
  end
end
