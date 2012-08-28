[![Build Status](https://secure.travis-ci.org/holderdeord/hdo-site.png)](http://travis-ci.org/holderdeord/hdo-site)

IRC channel
===========

Questions? Join us on [#holderdeord on irc.freenode.net](irc://irc.freenode.net/holderdeord)!


Development environment on Debian/Ubuntu
========================================

Install package dependencies and set up Ruby 1.9.3 with RVM.

    $ apt-get install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison libmysqlclient-dev imagemagick
    $ curl -L get.rvm.io | bash -s stable
    $ rvm install 1.9.3
    $ rvm use 1.9.3 --default
    $ ruby -v
    ruby 1.9.3p194 (2012-04-20 revision 35410) [x86_64-linux]

PS. For RVM to work properly with gnome-terminal, you have to tick the "Run command as login shell" checkbox on the "Title and Command" tab inside of gnome-terminal's Settings page.

Development environment on OS X
===============================

You'll need [XCode](https://developer.apple.com/xcode/) installed.

Install Ruby 1.9.3 through [RVM](http://rvm.io/):

    $ curl -L https://get.rvm.io | bash -s stable --ruby

Install dependencies through [Homebrew](http://mxcl.github.com/homebrew/):

_This list may be incomplete. Please add any missing libs you find._

    $ brew install git mysql imagemagick

Getting started:
================

    $ git clone git://github.com/holderdeord/hdo-site.git
    $ cd hdo-site
    $ gem install bundler
    $ [sudo] bundle install
    $ bundle exec rake db:setup
    $ bundle exec rails server

Data
====

Import data for development:
----------------------------

* A subset from [data.stortinget.no](http://data.stortinget.no):

        $ bundle exec rake import:dev

Data model
----------

To generate an entity-relationship diagram from the database:

        $ bundle exec rake erd

        # or

        $ bundle exec rake erd title="HDO Data Model"

This will generate `ERD.pdf`.


Set up images:
==============

To set everything up, run

    $ bundle exec rake images:all

This will download representative images and associate party logos with the imported parties.


Running specs:
==============

To run all specs and buster.js tests:

    $ bundle exec rake spec:all

To run all Ruby specs:

    $ bundle exec rake spec

To run only JS tests:

    $ bundle exec rake spec:js

You can also run specific specs, i.e. model, controller or request specs with e.g.:

    $ bundle exec rake spec:models

Run affected specs automatically when files change:

    $ bundle exec guard

JavaScript:
===========

Testing
-------

We use [buster.js](http://busterjs.org/) for JavaScript testing.

To run the tests you need to have buster.js installed.
Buster.JS on the command-line requires Node 0.6.3 or newer and NPM.
Node 0.6.3 and newer comes with NPM bundled on most platforms.

Install buster and autolint:

    $ npm install -g buster autolint

To run the tests once:

    $ bundle exec rake js:test

You can also run the buster server in the background and capture
 your local browser:

    $ buster server &

Then open [http://localhost:1111](localhost:1111) in your favorite browser.

To add more tests, update the config in spec/buster.js.

Linting
-------

    $ npm install -g autolint
    $ bundle exec rake js:lint
