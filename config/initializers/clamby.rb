if defined?(Clamby)
  Clamby.configure(check: true,
                   daemonize: true,
                   stream: true,
                   silence_output: false)
end
