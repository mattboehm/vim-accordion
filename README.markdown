accordion.vim
=============

Got too many vsplits? Accordion will squish all of them except the one
currently focused and a configurable number of its neighbors on each side.

Version 0.2.0

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


Screenshots
----------

Reguar usage:

[<img src="http://i.imgur.com/POkMUNv.gif" width="395"/>](http://i.imgur.com/POkMUNv.gif)

Diff mode:

[<img src="http://i.imgur.com/6N9haPt.gif" width="395"/>](http://i.imgur.com/6N9haPt.gif)

Related Plugins
---------------
I was inspired to write this after using [MultiWin](http://www.vim.org/scripts/script.php?script_id=1083) and wanting a similar approach that allows for more than one window to be visible at a time.

If you want to quickly maximize a single window, take a look at [ZoomWin](http://www.vim.org/scripts/script.php?script_id=508) or try using `:tab sp`.

License
-------
Copyright (c) Matthew Boehm.  Distributed under the same terms as Vim itself.
See `:help license`.
