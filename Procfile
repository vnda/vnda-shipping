web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development} -C config/puma.rb
worker: bundle exec sidekiq -c 1 -q default
