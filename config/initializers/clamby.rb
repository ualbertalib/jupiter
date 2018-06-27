if defined?(Clamby)
  Clamby.configure(check: true,
                   daemonize: false,
                   silence_output: false)
end
