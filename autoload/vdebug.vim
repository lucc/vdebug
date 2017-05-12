
" Do not source this script when python is not compiled in.
if !has('python')
    finish
endif

" Nice characters get screwed up on windows
if has('win32') || has('win64')
    let s:force_ascii = 1
elseif has('multi_byte') == 0
    let s:force_ascii = 1
else
    let s:force_ascii = 0
end

if !exists('g:vdebug#options')
    let g:vdebug#options = {}
endif

if !exists('g:vdebug#keymap')
    let g:vdebug#keymap = {}
endif

if !exists('g:vdebug#features')
    let g:vdebug#features = {}
endif

if !exists('g:vdebug#leader_key')
    let g:vdebug#leader_key = ""
endif

let s:keymap_defaults = {
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

let s:options_defaults = {
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
if s:force_ascii == 1
    let s:options_defaults["marker_default"] = '*'
    let s:options_defaults["marker_closed_tree"] = '+'
    let s:options_defaults["marker_open_tree"] = '-'
endif

