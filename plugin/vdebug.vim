" Vdebug: Powerful, fast, multi-language debugger client for Vim.
"
" Script Info  {{{
"=============================================================================
"    Copyright: Copyright (C) 2012 Jon Cairns
"      Licence:	The MIT Licence (see LICENCE file)
" Name Of File: vdebug.vim
"  Description: Multi-language debugger client for Vim (PHP, Ruby, Python,
"               Perl, NodeJS)
"   Maintainer: Jon Cairns <jon at joncairns.com>
"      Version: 1.4.1
"               Inspired by the Xdebug plugin, which was originally written by
"               Seung Woo Shin <segv <at> sayclub.com> and extended by many
"               others.
"        Usage: Use :help Vdebug for information on how to configure and use
"               this script, or visit the Github page http://github.com/joonty/vdebug.
"
"=============================================================================
" }}}

" Allow the user to disable loading of the plugin.
if exists('g:vdebug_loaded') && g:vdebug_loaded
    finish
endif
let g:vdebug_loaded = 1

" Do not source this script when python is not compiled in.
if !has("python")
    echomsg ":python is not available, vdebug will not be loaded."
    finish
endif

silent doautocmd User VdebugPre

execute 'pyfile' fnamemodify(expand('<sfile>'), ':p:h:h') . '/pythonx/start_vdebug.py'

" Nice characters get screwed up on windows
if has('win32') || has('win64')
    let g:vdebug_force_ascii = 1
elseif has('multi_byte') == 0
    let g:vdebug_force_ascii = 1
else
    let g:vdebug_force_ascii = 0
end

if !exists("g:vdebug_options")
    let g:vdebug_options = {}
endif

if !exists("g:vdebug_keymap")
    let g:vdebug_keymap = {}
endif

if !exists("g:vdebug_features")
    let g:vdebug_features = {}
endif

if !exists("g:vdebug_leader_key")
    let g:vdebug_leader_key = ""
endif

let g:vdebug_keymap_defaults = {
\    "run" : "<F5>",
\    "run_to_cursor" : "<F9>",
\    "step_over" : "<F2>",
\    "step_into" : "<F3>",
\    "step_out" : "<F4>",
\    "close" : "<F6>",
\    "detach" : "<F7>",
\    "set_breakpoint" : "<F10>",
\    "get_context" : "<F11>",
\    "eval_under_cursor" : "<F12>",
\    "eval_visual" : "<Leader>e"
\}

let g:vdebug_options_defaults = {
\    "port" : 9000,
\    "timeout" : 20,
\    "server" : '',
\    "on_close" : 'stop',
\    "break_on_open" : 1,
\    "ide_key" : '',
\    "debug_window_level" : 0,
\    "debug_file_level" : 0,
\    "debug_file" : "",
\    "path_maps" : {},
\    "watch_window_style" : 'expanded',
\    "marker_default" : '⬦',
\    "marker_closed_tree" : '▸',
\    "marker_open_tree" : '▾',
\    "continuous_mode"  : 1,
\    "background_listener" : 1,
\    "auto_start" : 1,
\    "window_commands" : {
\        "DebuggerWatch" : "vertical belowright new",
\        "DebuggerStack" : "belowright new",
\        "DebuggerStatus" : "belowright new"
\    },
\    "window_arrangement" : ["DebuggerWatch", "DebuggerStatus", "DebuggerStack"]
\}

" Different symbols for non unicode Vims
if g:vdebug_force_ascii == 1
    let g:vdebug_options_defaults["marker_default"] = '*'
    let g:vdebug_options_defaults["marker_closed_tree"] = '+'
    let g:vdebug_options_defaults["marker_open_tree"] = '-'
endif

" Create the top dog
python debugger = vdebug.debugger_interface.DebuggerInterface()

" Commands
command!                                                 VdebugStart      python debugger.run()
command!                                                 VdebugStop       python debugger.close()
command! -nargs=? -bang                                  VdebugEval       python debugger.handle_eval('<bang>', <q-args>)
command!                                                 VdebugVEval      python debugger.handle_visual_eval()
command! -nargs=+ -complete=customlist,s:OptionNames     VdebugOpt        python debugger.handle_opt(<f-args>)
command! -nargs=?                                        VdebugTrace      python debugger.handle_trace(<q-args>)
command! -nargs=? -complete=customlist,s:BreakpointTypes Breakpoint       python debugger.set_breakpoint(<q-args>)
command! -nargs=?                                        BreakpointRemove python debugger.remove_breakpoint(<q-args>)
command!                                                 BreakpointWindow python debugger.toggle_breakpoint_window()

if hlexists("DbgCurrentLine") == 0
    hi default DbgCurrentLine term=reverse ctermfg=White ctermbg=Red guifg=#ffffff guibg=#ff0000
end
if hlexists("DbgCurrentSign") == 0
    hi default DbgCurrentSign term=reverse ctermfg=White ctermbg=Red guifg=#ffffff guibg=#ff0000
end
if hlexists("DbgBreakptLine") == 0
    hi default DbgBreakptLine term=reverse ctermfg=White ctermbg=Green guifg=#ffffff guibg=#00ff00
end
if hlexists("DbgBreakptSign") == 0
    hi default DbgBreakptSign term=reverse ctermfg=White ctermbg=Green guifg=#ffffff guibg=#00ff00
end

" Signs and highlighted lines for breakpoints, etc.
sign define current text=-> texthl=DbgCurrentSign linehl=DbgCurrentLine
sign define breakpt text=B> texthl=DbgBreakptSign linehl=DbgBreakptLine

function! s:BreakpointTypes(A,L,P)
    let arg_to_cursor = strpart(a:L,11,a:P)
    let space_idx = stridx(arg_to_cursor,' ')
    if space_idx == -1
        return filter(['conditional ','exception ','return ','call ','watch '],'v:val =~ "^".a:A.".*"')
    else
        return []
    endif
endfunction

" Reload options dictionary, by merging with default options.
"
" This should be called if you want to update the options after vdebug has
" been loaded.
function! Vdebug_load_options(options)
    " Merge options with defaults
    let g:vdebug_options = extend(g:vdebug_options_defaults, a:options)

    " Override with single defined params ie. g:vdebug_options_port
    let single_defined_params = s:Vdebug_get_options()
    let g:vdebug_options = extend(g:vdebug_options, single_defined_params)

    python debugger.reload_options()
endfunction

" Get options defined outside of the vdebug_options dictionary
"
" This helps for when users might want to define a single option by itself
" without needing the dictionary ie. vdebug_options_port = 9000
function! s:Vdebug_get_options()
    let param_namespace = "g:vdebug_options_"
    let param_namespace_len = strlen(param_namespace)

    " Get the paramter names and concat the g:vdebug_options namespace
    let parameters = map(keys(g:vdebug_options_defaults), 'param_namespace.v:val')

    " Only use the defined parameters
    let existing_params = filter(parameters, 'exists(v:val)')

    " put into a dictionary for use with extend()
    let params = {}
    for name in existing_params
      let val = eval(name)

      " Remove g:vdebug_options namespace from param
      let name = strpart(name, param_namespace_len)
      let params[name] = val
    endfor
    if !empty(params)
      echoerr "Deprication Warning: The options g:vdebug_options_* are depricated.  Please use the g:vdebug_options dictionary."
    endif
    return params
endfunction

" Assign keymappings, and merge with defaults.
"
" This should be called if you want to update the keymappings after vdebug has
" been loaded.
function! Vdebug_load_keymaps(keymaps)
    " Unmap existing keys, if applicable
    if has_key(g:vdebug_keymap, "run")
        exe "silent! nunmap ".g:vdebug_keymap["run"]
    endif
    if has_key(g:vdebug_keymap, "set_breakpoint")
        exe "silent! nunmap ".g:vdebug_keymap["set_breakpoint"]
    endif
    if has_key(g:vdebug_keymap, "eval_visual")
        exe "silent! vunmap ".g:vdebug_keymap["eval_visual"]
    endif

    " Merge keymaps with defaults
    let g:vdebug_keymap = extend(g:vdebug_keymap_defaults, a:keymaps)

    " Mappings allowed in non-debug mode
    exe "noremap ".g:vdebug_keymap["run"]." :VdebugStart<cr>"
    exe "noremap ".g:vdebug_keymap["close"]." :VdebugStop<cr>"
    exe "noremap ".g:vdebug_keymap["set_breakpoint"]." :Breakpoint<cr>"

    " Exceptional case for visual evaluation
    exe "vnoremap ".g:vdebug_keymap["eval_visual"]." :VdebugVEval<cr>"
    python debugger.reload_keymappings()
endfunction

function! s:OptionNames(A,L,P)
    let arg_to_cursor = strpart(a:L,10,a:P)
    let space_idx = stridx(arg_to_cursor,' ')
    if space_idx == -1
        return filter(keys(g:vdebug_options_defaults),'v:val =~ a:A')
    else
        let opt_name = strpart(arg_to_cursor,0,space_idx)
        if has_key(g:vdebug_options,opt_name)
            return [g:vdebug_options[opt_name]]
        else
            return []
        endif
    endif
endfunction

function! Vdebug_get_visual_selection()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, "\n")
endfunction

function! Vdebug_edit(filename)
    try
        execute 'buffer' fnameescape(a:filename)
    catch /^Vim\%((\a\+)\)\=:E94/
        execute 'silent view' fnameescape(a:filename)
    endtry
endfunction

function! Vdebug_statusline()
    return pyeval("debugger.status_for_statusline()")
endfunction

silent doautocmd User VdebugPost
autocmd VimLeavePre * VdebugStop

call Vdebug_load_options(g:vdebug_options)
call Vdebug_load_keymaps(g:vdebug_keymap)
