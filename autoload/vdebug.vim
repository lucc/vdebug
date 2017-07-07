" Autoload functions for the Vdebug Vim plugin.
" vim: sw=4

let s:running = 0
function! vdebug#start() abort
    call s:init()
    python debugger.run()
    let s:running = 1
endfunction

function! vdebug#stop() abort
    if !s:running
	return
    endif
    python debugger.close()
    let s:running = 0
endfunction

let s:initialized = 0
function! s:init() abort
    if s:initialized
	return
    endif
    let s:initialized = 1
    execute 'pyfile' fnamemodify(expand('<sfile>'), ':p:h') . '/pythonx/start_vdebug.py'
    python debugger = vdebug.debugger_interface.DebuggerInterface()
    autocmd VimLeavePre * call vdebug#stop()
    call s:load_options(g:vdebug_options)
    call s:load_keymaps(g:vdebug_keymap)
endfunction

" Reload options dictionary, by merging with default options.
"
" This should be called if you want to update the options after vdebug has
" been loaded.
function! s:load_options(options) abort
    " Merge options with defaults
    let g:vdebug_options = extend(g:vdebug_options_defaults, a:options)

    " Override with single defined params ie. g:vdebug_options_port
    let single_defined_params = s:get_options()
    let g:vdebug_options = extend(g:vdebug_options, single_defined_params)

    python debugger.reload_options()
endfunction

" Get options defined outside of the vdebug_options dictionary
"
" This helps for when users might want to define a single option by itself
" without needing the dictionary ie. vdebug_options_port = 9000
function! s:get_options() abort
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
function! s:load_keymaps(keymaps)
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
    exe "noremap ".g:vdebug_keymap["run"]." :call vdebug#start()<cr>"
    exe "noremap ".g:vdebug_keymap["close"]." :call vdebug#stop()cr>"
    exe "noremap ".g:vdebug_keymap["set_breakpoint"]." :Breakpoint<cr>"

    " Exceptional case for visual evaluation
    exe "vnoremap ".g:vdebug_keymap["eval_visual"]." :VdebugVEval<cr>"
    python debugger.reload_keymappings()
endfunction

function! vdebug#breakpoint(args)
    call s:init()
    execute 'python debugger.set_breakpoint(' . a:args . ')'
endfunction

function! vdebug#remove_breakpoint(args)
    if !s:initialized
	return
    endif
    execute 'python debugger.remove_breakpoint(' . a:args . ')'
endfunction

function! vdebug#eval(force, args)
    call s:init()
    python debugger.handle_eval(vim.eval('a:force'), vim.eval('a:args'))
endfunction

function! vdebug#veval()
    call s:init()
    python debugger.handle_visual_eval()
endfunction

function! vdebug#opt(...)
    call s:init()
    python debugger.handle_opt(*vim.eval('a:000'))
endfunction

function! vdebug#trace(args)
    call s:init()
    python debugger.handle_trace(vim.eval('a:args'))
endfunction

function! vdebug#breakpoint_window()
    if !s:initialized
	echomsg 'No breakpoints.'
	return
    endif
    python debugger.toggle_breakpoint_window()
endfunction
