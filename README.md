Memoist
=============

[![Build Status](https://travis-ci.org/matthewrudy/memoist.png?branch=master)](https://travis-ci.org/matthewrudy/memoist)

Memoist is an extraction of ActiveSupport::Memoizable.

Since June 2011 ActiveSupport::Memoizable has been deprecated.
But I love it,
and so I plan to keep it alive.

Usage
-----

Just extend with the Memoist module

    require 'memoist'
    class Person
      extend Memoist

      def social_security
        decrypt_social_security
      end
      memoize :social_security
    end

And person.social_security will only be calculated once.

Every memoized function (which initially was not accepting any arguments) has a ```(reload)```
argument you can pass in to bypass and reset the memoization:

    def some_method
      Time.now
    end
    memoize :some_method

Calling ```some_method``` will be memoized, but calling ```some_method(true)``` will rememoize each time.

You can even memoize method that takes arguments.


    class Person
      def taxes_due(income)
        income * 0.40
      end
      memoize :taxes_due
    end

This will only be calculated once per value of income.

You can also memoize class methods.

    class Person

      class << self
        extend Memoist
        def with_overdue_taxes
          # ...
        end
        memoize :with_overdue_taxes
      end

    end


Reload
------

Each memoized function comes with a way to flush the existing value.

    person.social_security       # returns the memoized value
    person.social_security(true) # bypasses the memoized value and rememoizes it

This also works with a memoized method with arguments

    person.taxes_due(100_000)       # returns the memoized value
    person.taxes_due(100_000, true) # bypasses the memoized value and rememoizes it

If you want to flush the entire memoization cache for an object

    person.flush_cache

Authors
===========

Everyone who contributed to it in the rails repository.

* Joshua Peek
* Tarmo Tänav
* Jeremy Kemper
* Eugene Pimenov
* Xavier Noria
* Niels Ganser
* Carl Lerche & Yehuda Katz
* jeem
* Jay Pignata
* Damien Mathieu
* José Valim
* Matthew Rudy Jacobs

Contributing
============

1. Fork it ( http://github.com/<my-github-username>/memoist/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

License
=======

Released under the [MIT License](http://www.opensource.org/licenses/MIT), just as Ruby on Rails is.
