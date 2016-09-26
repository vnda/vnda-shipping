#!/bin/bash

bundle check || bundle install

bundle exec puma -p 9000 -C ./vendor/docker/development/app/puma.rb
