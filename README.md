# MagicStick [![Build Status](https://travis-ci.org/blaskovicz/MagicStick.svg?branch=master)](https://travis-ci.org/blaskovicz/MagicStick) [![Heroku](https://heroku-badge.herokuapp.com/?app=magic-stick&style=flat)](https://dashboard.heroku.com/apps/magic-stick/activity)

> Create leagues and matches for yourself and friends.

# Developing

## Install Ruby

Although you technically don't need to utilize ruby through rbenv, this setup is recommended.
If you already have ruby 2.0 installed, then you can proceed to the _Download the Code_ section.

### Get [rbenv](https://github.com/sstephenson/rbenv/blob/master/README.md)

### Install [ruby-build](https://github.com/sstephenson/ruby-build)

### Install ruby

Follow the instructions on the ruby-build page to install ruby 2.1.5.
Note that if you want readline support, you can take a look at [this guide](http://vvv.tobiassjosten.net/ruby/readline-in-ruby-with-rbenv/).

### Install Bundler

```sh
$ gem install bundler
$ rbenv rehash
```


## Download the code

```sh
$ git clone https://github.com/blaskovicz/MagicStick && cd MagicStick
```

## Install Dependencies

```sh
$ bundle install
$ gem install sass
$ npm install
```

If you run into issues with `$ bundle install` and are using `rbenv`, please
consult [this post on stackoverflow](http://stackoverflow.com/a/11146496/626810).

## Initialize the Database

```sh
$ bundle exec rake db:migrate
```

## Run Grunt

This will compile/test all source files and watch them for changes.
Additionally it will launch a server via shotgun in development mode. All files
are reloaded for each request ensuring changes will be picked up on subsequent
requests.

```sh
$ grunt
```

## View

The server should be running at [http://localhost:9393](http://localhost:9393)


## Testing & Deployment

### Travis

MagicStick utilizes TravisCI for testing and deployment to Heroku. See the .travis.yml for configuration details.

### Heroku

MagicStick is deployed via [Heroku](https://magic-stick.herokuapp.com/).

The configuration process is as follows:

```
# Create the heroku app
$ heroku create

# Add the postgres addon
$ heroku addons:add heroku-postgresql

# Optionally, to enable email, also add the sendgrid addon.
$ heroku addons:add sendgrid

# To install node, rake and grunt, configure the buildpacks:
$ heroku buildpacks:set -i 1 heroku/ruby
$ heroku buildpacks:set -i 2 heroku/nodejs

# Ensures dev-dependencies like grunt are installed for the build
$ heroku config:add NPM_CONFIG_PRODUCTION=false

# Configure ruby rack to run in production mode
$ heroku config:add RACK_ENV=production

# Check out env.sample for other env variables of note
$ cat env.sample
$ heroku config:add OTHER_VAR=OTHER_VAL
$ ...

# Push to Heroku
$ git push heroku master

# Execute database migrations
$ heroku run 'bundler exec rake db:migrate'
```
