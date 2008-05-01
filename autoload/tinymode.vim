" Vim autoload plugin - provide "tiny modes" for Normal mode
" File:         tinymode.vim
" Created:      2008 Apr 29
" Last Change:  2008 May 01
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	0.1

" Description:
"   A "tiny mode" (or "sub mode") is almost like any other Vim mode.
"
"   It has a name that identifies it, mappings that enter the mode, mappings
"   defined within the mode.  There can be a permanent mode message in the
"   command-line that indicates the active mode and can show the available
"   keys.
"
"   Leaving is different: Any key not mapped in the mode goes back to Normal
"   mode and executes there.  The mode is also left automatically when not
"   pressing a key for 'timeoutlen' ms (and 'timeout' is on).  The escape
"   key just leaves the mode.
"
"   tinymode.vim is friendly to your mappings, they aren't touched in any
"   way.  getchar() is not used, the cursor doesn't move to the command-line
"   waiting for a character.
"
" Examples:
"   see tinym_ex.vim

" Installation:
"   copy file into your ~\vimfiles\autoload folder (or a similar autoload
"   folder)
"
" Usage:
" - call the functions
"	tinymode#EnterMap()
"	tinymode#ModeMsg()
"	tinymode#Map()
"   from your vimrc or interactively to define any number of new tiny modes.
" - increase 'timeoutlen' if 1 second is too short

" TODO
" - key(s) for leaving the mode tinymode#LeaveMap()
" - commands to execute when leaving the mode
" - timeout after N x 'timeoutlen', 0 disables timeout
" ? count
" ? recursive modes
" ? enter a tiny mode from other Vim modes
"
" Bugs:
" + Map() cannot map keycodes, the timeout doesn't work

" Misc:
"   :h vim-modes
" - keys in a mode are not mapped directly to a command, the same key might
"   be reused by another mode; we need to either copy or dereference {rhs}s

" Init: "{{{
nn <sid>do :<c-u>call <sid>action
nn <silent> <sid>clean :call <sid>clean()<cr>
let s:quitnormal = 1
nmap <sid>r <sid>_

" nn <sid>_ <sid>_
" let mp = maparg("<sid>_")

if !exists("g:tinymode#modes")
    let g:tinymode#modes = {}
endif
"}}}

func! tinymode#enter(tmode, startkey) "{{{
    nn <script> <sid>_ <sid>clean
    nn <script> <sid>_<esc> <sid>clean

    if s:quitnormal
	let s:sav_sc = &sc
    endif
    set noshowcmd
    let s:quitnormal = 0

    let s:curmode = g:tinymode#modes[a:tmode]
    for key in keys(s:curmode.map)
	exec "nn <script><silent> <sid>_".key '<sid>do("'.s:esclt(key).'")<cr><sid>r'
    endfor
    call <sid>action(a:startkey)
endfunc "}}}

func! <sid>action(key) "{{{
    exec get(s:curmode.map, a:key, "")
    if has_key(s:curmode, "redraw") && s:curmode.redraw
	redraw
    endif
    if has_key(s:curmode, "msg")
	echohl ModeMsg
	echo s:curmode.msg 
	echohl none
    endif
endfunc "}}}

func! <sid>clean() "{{{
    let &sc = s:sav_sc
    exec "norm! :\<c-u>"
    call tinymode#MapClear()
    let s:quitnormal = 1
endfunc "}}}

func! s:esclt(key) "{{{
    return substitute(a:key, "<", "<lt>", "g")
endfunc "}}}

" Interface:
" mode is an arbitrary, unique name to identify the mode
" the following functions can be called in any order

" Map a Normal mode {key} that enters the new {mode}.  {startkey} can
" simulate an initial keypress in the new mode.
func! tinymode#EnterMap(mode, key, ...) "{{{
    " a:1 -- startkey
    " a:2 -- leavekey (command to execute when leaving)
    let startkey = a:0>=1 ? escape(a:1, '\"') : ""
    let mode = escape(a:mode, '\"')
    exec "nn <script>" a:key ':<c-u>call tinymode#enter("'.mode.'", "'.s:esclt(startkey).'")<cr><sid>r'

    if startkey == ""
	return
    endif
    try
	let g:tinymode#modes[a:mode].map[startkey] = ""
    catch
	if !has_key(g:tinymode#modes, a:mode)
	    let g:tinymode#modes[a:mode] = {"map": {startkey : ""}}
	else
	    let g:tinymode#modes[a:mode].map = {startkey : ""}
	endif
    endtry
endfunc "}}}

" Define a permanent {message} for the command-line, useful to know which
" {mode} you are in; if your commands overwrite the message, try setting
" {redraw} to 1
func! tinymode#ModeMsg(mode, message, ...) "{{{
    " a:1 -- redraw (1 or default 0)
    let redraw = a:0>=1 ? a:1 : 0
    try
	let g:tinymode#modes[a:mode].msg = a:message
    catch
	let g:tinymode#modes[a:mode] = {"msg": a:message}
    endtry
    if redraw
	let g:tinymode#modes[a:mode].redraw = 1
    endif
endfunc "}}}

" Map a {key} to an Ex-{command} within the new {mode}.  You can use
" ":normal" to execute Normal mode commands from the mapping and to control
" remapping of keys.
func! tinymode#Map(mode, key, command) "{{{
    try
	let g:tinymode#modes[a:mode].map[a:key] = a:command
    catch
	if !has_key(g:tinymode#modes, a:mode)
	    let g:tinymode#modes[a:mode] = {"map": {a:key : a:command}}
	else
	    let g:tinymode#modes[a:mode].map = {a:key : a:command}
	endif
    endtry
endfunc "}}}

com! -bar LeaveMode call feedkeys("\e")

" like :mapclear for {mode}
func! tinymode#MapClear(...) "{{{
    try
	if a:0 >= 1
	    let mode = a:1
	    let klist = keys(g:tinymode#modes[mode].map)
	else
	    let klist = keys(s:curmode.map)
	endif
	for key in klist
	    exec "sil! unmap <sid>_". key
	endfor
    catch
	echo v:exception
	return
    endtry
endfunc "}}}

" vim:set fdm=marker:
