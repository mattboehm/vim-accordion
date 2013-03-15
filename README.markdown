accordion.vim
=============

Got too many vsplits? Accordion will squish all of them except the one
currently focused and a configurable number of its neighbors on each side.

Version 0.0.3

No backwards compatability is guaranteed at this time.


Usage
-----

Accordion can either be used to adjust the layout once or to continually
enforce the layout for the current tab or all tabs.

To adjust the layout one time, run `:Accordion 3` where 3 is the number of 
vsplits you want to be limited to seeing. To restore your layout to normal,
run `:AccordionClear`.

If you want accordion to continually enforce a layout, try `:AccordionStart 3`
or `:AccordionStartTab 3` (only applies to one tab). Every time you split or 
switch windows, accordion will re-layout to enforce that you never have too 
many vsplits crowding your screen. To turn this off, run `:AccordionStop`.


Screenshot
----------
<img src="http://i.imgur.com/H62uwZ3.png" width="800"/>


License
-------
Copyright (c) Matthew Boehm.  Distributed under the same terms as Vim itself.
See `:help license`.
