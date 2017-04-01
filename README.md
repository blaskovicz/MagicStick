# MagicStick ![](https://github.com/blaskovicz/MagicStick/raw/master/public/img/magic-wand-32.jpeg)  [![Build Status](https://travis-ci.org/blaskovicz/MagicStick.svg?branch=master)](https://travis-ci.org/blaskovicz/MagicStick) [![Heroku](https://heroku-badge.herokuapp.com/?app=magic-stick)](https://dashboard.heroku.com/apps/magic-stick/activity) [![Coverage Status](https://coveralls.io/repos/github/blaskovicz/MagicStick/badge.svg)](https://coveralls.io/github/blaskovicz/MagicStick)

> Create leagues and matches for yourself and friends.

# Developing

## Install Ruby

Although you technically don't need to utilize ruby through rbenv, this setup is recommended.
If you already have ruby `2.4.1` installed, then you can proceed to the _Download the Code_ section.

### Get [rbenv](https://github.com/sstephenson/rbenv/blob/master/README.md)

### Install [ruby-build](https://github.com/sstephenson/ruby-build)

### Install ruby

Follow the instructions on the ruby-build page to install ruby `2.4.1`.
Note that if you want readline support, you can take a look at [this guide](http://vvv.tobiassjosten.net/ruby/readline-in-ruby-with-rbenv/).

### Install Bundler

```sh
$ gem install bundler
$ rbenv rehash
```


## Download the Code

```sh
$ git clone https://github.com/blaskovicz/MagicStick && cd MagicStick
```

## Install Dependencies

_Note:_ libpq-dev and libsqlite3-dev packages will be required to compile native database extensions.
Please install those through your OS package provider (eg: `sudo apt-get install libpq-dev libsqlite3-dev` on ubuntu 16).

```sh
$ bundle install # backend dependences (`--path vendor/bundle` to install gems locally)
$ npm install # build dependencies (installed locally to `./node_modules`)
$ bower install # frontend sources (installed locally to `./public/bower_components`)
```

If you run into issues with `$ bundle install` and are using `rbenv`, please
consult [this post on stackoverflow](http://stackoverflow.com/a/11146496/626810).

## Set Up Your Development Config
$ cp env.sample .env && chmod 0600 .env

You may want to change `DATABASE_URL` and `SITE_BASE_URI`, at a minimum.

## Initialize the Database

```sh
$ bundle exec rake db:migrate
```

## Run Grunt

```sh
$ grunt
```

`grunt` will compile and test all source files as they change.
Additionally, it will launch the site via puma in development mode and
restarted it upon file changes.

You can watch the output stream (STDOUT, STDERR) for debug emails, test failures,
HTTP requests, etc.

## View

The server should now be running at [http://localhost:9393](http://localhost:9393)

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
$ heroku addons:create sendgrid

# Optionally, to enable alerts, also add the raygun addon.
$ heroku addons:create raygun

# To support jwts generated via auth0
$ heroku addons:create auth0

# To build the site, configure the buildpacks:
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
