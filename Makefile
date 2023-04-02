new:
	echo "$$_gemfile" > web/Gemfile
	touch web/Gemfile.lock
	docker-compose run web rails new . --api --force --database=mysql --skip-turbolinks --skip-test --skip-bundle
	# chown→ファイルの所有者を変更、-R→ディレクトリ内の所有者も変更、.→任意のファイル
	# chown a:c b→ファイルbの所有者をユーザa（グループ権限c）に変更
	sudo chown -R $$USER:$$USER .
	echo "$$_database_yml" > web/config/database.yml
	sed -i "" -e "s/# gem 'rack-cors'/gem 'rack-cors'/" web/Gemfile

	# echo "gem 'nokogiri'" >> web/Gemfile
	# docker-compose run web gem install nokogiri --platform=ruby
	# docker-compose run web gem install nokogiri -v 1.13.10
	docker-compose run web bundle config set force_ruby_platform true
	docker-compose run web bundle install
	echo "$$_cors_rb" > web/config/initializers/cors.rb
	docker-compose build
	docker-compose run web rails db:create
	# docker-compose run frontend vue create .
	# http://localhost:3000 で確認
	# docker-compose run web rails generate controller welcome index
	# docker-compose run web sh -c 'sleep 20 && rake db:create'
	sudo chown -R $$USER:$$USER .

run:
	docker-compose up --build

define _gemfile
source 'https://rubygems.org'
gem 'rails', '~> 6.0.0'
endef
export _gemfile

define _database_yml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: db

development:
  <<: *default
  database: app_development

test:
  <<: *default
  database: app_test

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
endef
export _database_yml

define _cors_rb
# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins 'example.com'
#
#     resource '*',
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:8080'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
endef
export _cors_rb

push:
	docker-compose run web rake assets:precompile
	sudo chown -R $$USER:$$USER .
	docker-compose build
	ecs-cli push $(APP_NAME) --region $(REGION)

export IMAGE  = $(shell aws ecr describe-repositories --region $(REGION) --repository-names $(APP_NAME) --query 'repositories[0].repositoryUri' --output text)
export DIGEST = $(shell aws ecr batch-get-image --region $(REGION) --repository-name $(APP_NAME) --image-ids imageTag=latest --query 'images[0].imageId.imageDigest' --output text)

migrate:
	ecs-cli compose -f migrate-compose.yml --project-name $(APP_NAME)-migrate up --cluster $(CLUSTER) --region $(REGION)

export IMAGE  = $(shell aws ecr describe-repositories --region $(REGION) --repository-names $(APP_NAME) --query 'repositories[0].repositoryUri' --output text)
export DIGEST = $(shell aws ecr batch-get-image --region $(REGION) --repository-name $(APP_NAME) --image-ids imageTag=latest --query 'images[0].imageId.imageDigest' --output text)

deploy:
	ecs-cli compose -f app-compose.yml --project-name $(APP_NAME)-app up --cluster $(CLUSTER) --region $(REGION)
