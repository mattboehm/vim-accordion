accordion.vim
=============

Got too many vsplits? Accordion will squish all of them except the one
currently focused and a configurable number of its neighbors on each side.

Version 0.0.1

No backwards compatability is guaranteed at this time.


Usage
-----

To use Accordion, call AccordionStart with the total number of vsplits you want to
see passed in as an argument. AccordionStart(3) would squish all vsplits except the
currently active one and one on each side (left/right). To disable the plugin,
call AccordionStop().


Screenshot
----------
<img src="http://i.imgur.com/H62uwZ3.png" width="800"/>


License
-------
Copyright (c) Matthew Boehm.  Distributed under the same terms as Vim itself.
See `:help license`.
