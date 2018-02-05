if defined?(Clamby)
  Clamby.configure(check: true,
                   daemonize: true,
                   silence_output: false)
end
