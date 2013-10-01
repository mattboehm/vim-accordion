accordion.vim
=============

Accordion is a vim window manager for people who love vsplits. Vsplits can be great for viewing levels of a call stack or versions of a file side-by-side, but if there are more than a few, they become too thin to comfortably read.

Accordion lets you set the maximum number of vsplits you want to see, and shrinks the rest to be one column wide. 

If you want to view changes to a file over time, it's got a fancy diff mode. Even if you're not big on vsplits, you may want to consider Accordion for this feature alone.

Version 0.3.0

But I Don't Use Splits!
-----------------------
If you don't typically use a lot of splits, there are a few other use cases where accordion can be helpful:

* after viewing stack traces with [unstack](https://github.com/mattboehm/vim-unstack)
* for the diff mode described and demoed below to view changes to a file over time

If you're not interested in any of these use cases then no worries; keep using vim in whatever way works best for you =).

Usage
-----
For a much more detailed guide, please type `:help accordion` or read [doc/accordion.txt](doc/accordion.txt).

To enforce that the current tab always shows at most 3 vsplits, run `:Accordion 3`. Accordion will give you a viewport of 3 vsplits and shrink all splits outside the viewport. As you bump against the edges of the viewport, it will move with you. You can stop Accordion by running `:AccordionStop`

While Accordion is running, use `:AccordionZoomIn` and `AccordionZoomOut` to change the size of the viewport.

Accordion also has a special diff mode that you can start by running `:AccordionDiff`.
Try this when you have many versions of the same file side-by-side in chronological order.
Accordion will shrink all but two vsplits, and visible vsplits will be diffed against each other.
The easiest way to open versions of a file is to run [fugitive](https://github.com/tpope/vim-fugitive)'s `:Glog --reverse`, highlight the desired changes in the quickfix list, and hit the [unstack](https://github.com/mattboehm/vim-unstack) shortcut.
See the [screenshots](#Screenshots) below for an example of diff mode in action.

There are also commands to temporarily change the layout without starting/stopping. To learn more about these, type `:help accordion-running-once`.

Screenshots
-----------

:Accordion 3
(Please ignore the fact that it's :AccordionStart at the bottom, I renamed the command.)

[<img src="http://i.imgur.com/POkMUNv.gif" width="395"/>](http://i.imgur.com/POkMUNv.gif)

:AccordionDiff

[<img src="http://i.imgur.com/6N9haPt.gif" width="395"/>](http://i.imgur.com/6N9haPt.gif)

Related Plugins
---------------
I was inspired to write this after using [MultiWin](http://www.vim.org/scripts/script.php?script_id=1083) and wanting a similar approach that allows for more than one window to be visible at a time.

If you want to quickly maximize a single window, take a look at [ZoomWin](http://www.vim.org/scripts/script.php?script_id=508) or try using `:tab sp`.

License
-------
Copyright (c) Matthew Boehm.  Distributed under the same terms as Vim itself.
See `:help license`.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/mattboehm/vim-accordion/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

