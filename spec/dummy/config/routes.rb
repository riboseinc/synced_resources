# (c) Copyright 2017 Ribose Inc.
#

Rails.application.routes.draw do
  resources :dummy, only: :index
end
