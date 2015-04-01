# MagicStick

Create leagues and matches for yourself and friends.

# Developing

## Install Ruby

Although you technically don't need to utilize ruby through rbenv, this setup is recommended.
If you already have ruby 2.0 installed, then you can proceed to the _Download the Code_ section.

### Get [rbenv](https://github.com/sstephenson/rbenv/blob/master/README.md)

### Install [ruby-build](https://github.com/sstephenson/ruby-build)

### Install ruby

Follow the instructions on the ruby-build page to install ruby 2.1.X.

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
$ npm install
```

If you run into issues with `$ bundle install` and are using `rbenv`, please
consult [this post on stackoverflow](http://stackoverflow.com/a/11146496/626810).

## Run Grunt

This will compile all front-end site files and watch them for changes.

```sh
$ grunt
```

## Run the Server

This will compile the server files, watch them for changes, and take care of (re)starting the server.

```sh
$ bundle exec unicorn config.ru
```
