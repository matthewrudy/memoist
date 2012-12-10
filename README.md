Memoist
=============

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

You can even do it with a method that takes arguments.


    class Person
      def taxes_due(income)
        income * 0.40
      end
      memoize :taxes_due
    end

This will only be calculated once per value of income.

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

License
=======

Released under the [MIT License](http://www.opensource.org/licenses/MIT), just as Ruby on Rails is.
