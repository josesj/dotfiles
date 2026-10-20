" GitHub Light Default y GitHub Dark Dimmed con la paleta actual de Primer, la
" misma de la que salen los temas de Kitty. 'background' elige la variante. Los colores son los
" de @primer/primitives (los que usa github-nvim-theme y, en VS Code, GitHub
" Light Default y GitHub Dark Dimmed); los semitransparentes están ya mezclados
" sobre el fondo.
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'github_primer'

if &background ==# 'dark'
  " GitHub Dark Dimmed.
  let s:c = {
        \ 'bg': '#22272e', 'bg_subtle': '#2d333b', 'bg_inset': '#1c2128',
        \ 'fg': '#adbac7', 'fg_muted': '#768390', 'fg_subtle': '#636e7b',
        \ 'border': '#444c56', 'border_muted': '#373e47', 'cursorline': '#2d333b',
        \ 'visual': '#2e4c77', 'search': '#5a4924', 'neutral': '#3c434d',
        \ 'accent': '#539bf5', 'success': '#57ab5a', 'attention': '#c69026',
        \ 'severe': '#cc6b2c', 'danger': '#e5534b', 'done': '#986ee2',
        \ 'diff_add': '#273832', 'diff_delete': '#362b31', 'diff_change': '#37342a',
        \ 'diff_text': '#5a4924',
        \ 'comment': '#768390', 'constant': '#6cb6ff', 'entity': '#dcbdfb',
        \ 'tag': '#8ddb8c', 'keyword': '#f47067', 'string': '#96d0ff',
        \ 'variable': '#f69d50', 'heading': '#316dca', 'list': '#eac55f',
        \ }
else
  " GitHub Light Default.
  let s:c = {
        \ 'bg': '#ffffff', 'bg_subtle': '#f6f8fa', 'bg_inset': '#f6f8fa',
        \ 'fg': '#1f2328', 'fg_muted': '#656d76', 'fg_subtle': '#6e7781',
        \ 'border': '#d0d7de', 'border_muted': '#d8dee4', 'cursorline': '#f6f8fa',
        \ 'visual': '#bbdfff', 'search': '#eedcab', 'neutral': '#eff1f3',
        \ 'accent': '#0969da', 'success': '#1a7f37', 'attention': '#9a6700',
        \ 'severe': '#bc4c00', 'danger': '#d1242f', 'done': '#8250df',
        \ 'diff_add': '#dafbe1', 'diff_delete': '#ffebe9', 'diff_change': '#fff8c5',
        \ 'diff_text': '#eedcab',
        \ 'comment': '#57606a', 'constant': '#0550ae', 'entity': '#6639ba',
        \ 'tag': '#116329', 'keyword': '#cf222e', 'string': '#0a3069',
        \ 'variable': '#953800', 'heading': '#0550ae', 'list': '#3b2300',
        \ }
endif

" s:hi(grupo, texto, fondo[, atributos[, subrayado]]); '' deja el valor en NONE.
function! s:hi(group, fg, bg, ...) abort
  let l:attr = get(a:, 1, '')
  let l:sp = get(a:, 2, '')
  execute 'highlight' a:group
        \ 'guifg=' . (empty(a:fg) ? 'NONE' : s:c[a:fg])
        \ 'guibg=' . (empty(a:bg) ? 'NONE' : s:c[a:bg])
        \ 'gui=' . (empty(l:attr) ? 'NONE' : l:attr)
        \ 'cterm=' . (empty(l:attr) ? 'NONE' : l:attr)
        \ 'guisp=' . (empty(l:sp) ? 'NONE' : s:c[l:sp])
endfunction

" Interfaz.
call s:hi('Normal', 'fg', 'bg')
call s:hi('NormalFloat', 'fg', 'bg_subtle')
call s:hi('EndOfBuffer', 'bg', '')
call s:hi('NonText', 'border', '')
call s:hi('SpecialKey', 'border', '')
call s:hi('Whitespace', 'border', '')
call s:hi('Conceal', 'fg_subtle', '')
call s:hi('LineNr', 'fg_subtle', '')
call s:hi('LineNrAbove', 'fg_subtle', '')
call s:hi('LineNrBelow', 'fg_subtle', '')
call s:hi('CursorLineNr', 'fg', '', 'bold')
call s:hi('CursorLine', '', 'cursorline')
call s:hi('CursorColumn', '', 'cursorline')
call s:hi('ColorColumn', '', 'bg_subtle')
call s:hi('SignColumn', 'fg_subtle', '')
call s:hi('FoldColumn', 'fg_subtle', '')
call s:hi('Folded', 'fg_muted', 'bg_subtle')
call s:hi('VertSplit', 'border', '')
highlight! link WinSeparator VertSplit
call s:hi('StatusLine', 'fg', 'bg_subtle')
call s:hi('StatusLineNC', 'fg_muted', 'bg_subtle')
call s:hi('StatusLineTerm', 'fg', 'bg_subtle')
call s:hi('StatusLineTermNC', 'fg_muted', 'bg_subtle')
call s:hi('TabLine', 'fg_muted', 'bg_subtle')
call s:hi('TabLineFill', '', 'bg_inset')
call s:hi('TabLineSel', 'fg', 'bg', 'bold')
call s:hi('Visual', '', 'visual')
call s:hi('VisualNOS', '', 'visual')
call s:hi('Search', 'fg', 'search')
call s:hi('CurSearch', 'bg', 'attention', 'bold')
call s:hi('IncSearch', 'bg', 'attention', 'bold')
call s:hi('MatchParen', '', 'visual', 'bold')
call s:hi('Pmenu', 'fg', 'bg_subtle')
call s:hi('PmenuSel', 'fg', 'visual', 'bold')
call s:hi('PmenuSbar', '', 'bg_subtle')
call s:hi('PmenuThumb', '', 'border')
call s:hi('WildMenu', 'fg', 'visual', 'bold')
call s:hi('Directory', 'accent', '')
call s:hi('Title', 'accent', '', 'bold')
call s:hi('Question', 'success', '')
call s:hi('MoreMsg', 'success', '')
call s:hi('ModeMsg', 'fg_muted', '')
call s:hi('WarningMsg', 'attention', '')
call s:hi('ErrorMsg', 'danger', '', 'bold')
call s:hi('Error', 'danger', '', 'undercurl', 'danger')
call s:hi('Todo', 'attention', '', 'bold')
call s:hi('QuickFixLine', '', 'visual')
call s:hi('SpellBad', '', '', 'undercurl', 'danger')
call s:hi('SpellCap', '', '', 'undercurl', 'attention')
call s:hi('SpellRare', '', '', 'undercurl', 'done')
call s:hi('SpellLocal', '', '', 'undercurl', 'accent')
call s:hi('DiffAdd', '', 'diff_add')
call s:hi('DiffDelete', 'danger', 'diff_delete')
call s:hi('DiffChange', '', 'diff_change')
call s:hi('DiffText', '', 'diff_text', 'bold')
call s:hi('ToolbarLine', 'fg', 'bg_subtle')
call s:hi('ToolbarButton', 'fg', 'border', 'bold')

" Sintaxis, con los colores que GitHub usa al resaltar código.
call s:hi('Comment', 'comment', '', 'italic')
call s:hi('Constant', 'constant', '')
call s:hi('String', 'string', '')
call s:hi('Character', 'string', '')
call s:hi('Number', 'constant', '')
call s:hi('Boolean', 'constant', '')
call s:hi('Float', 'constant', '')
call s:hi('Identifier', 'fg', '')
call s:hi('Function', 'entity', '')
call s:hi('Statement', 'keyword', '')
call s:hi('Conditional', 'keyword', '')
call s:hi('Repeat', 'keyword', '')
call s:hi('Label', 'keyword', '')
call s:hi('Operator', 'keyword', '')
call s:hi('Keyword', 'keyword', '')
call s:hi('Exception', 'keyword', '')
call s:hi('PreProc', 'keyword', '')
call s:hi('Include', 'keyword', '')
call s:hi('Define', 'keyword', '')
call s:hi('Macro', 'entity', '')
call s:hi('PreCondit', 'keyword', '')
call s:hi('Type', 'variable', '')
call s:hi('StorageClass', 'keyword', '')
call s:hi('Structure', 'keyword', '')
call s:hi('Typedef', 'keyword', '')
call s:hi('Special', 'constant', '')
call s:hi('SpecialChar', 'constant', '')
call s:hi('Tag', 'tag', '')
call s:hi('Delimiter', 'fg', '')
call s:hi('SpecialComment', 'comment', '', 'italic')
call s:hi('Debug', 'variable', '')
call s:hi('Underlined', 'accent', '', 'underline')
call s:hi('Ignore', 'fg_subtle', '')

" Marcado, HTML y diff, como en las vistas de GitHub.
call s:hi('htmlTag', 'fg', '')
call s:hi('htmlEndTag', 'fg', '')
call s:hi('htmlTagName', 'tag', '')
call s:hi('htmlArg', 'constant', '')
call s:hi('markdownH1', 'heading', '', 'bold')
call s:hi('markdownH2', 'heading', '', 'bold')
call s:hi('markdownH3', 'heading', '', 'bold')
call s:hi('markdownHeadingDelimiter', 'heading', '', 'bold')
call s:hi('markdownListMarker', 'list', '')
call s:hi('markdownCode', 'constant', '')
call s:hi('markdownCodeBlock', 'constant', '')
call s:hi('markdownUrl', 'string', '', 'underline')
call s:hi('markdownLinkText', 'accent', '')
call s:hi('diffAdded', 'success', '')
call s:hi('diffRemoved', 'danger', '')
call s:hi('diffChanged', 'attention', '')
call s:hi('diffFile', 'accent', '', 'bold')
call s:hi('diffLine', 'done', '')
call s:hi('gitcommitSummary', 'fg', '', 'bold')
call s:hi('gitcommitOverflow', 'danger', '')

" Complementos: GitGutter y ALE.
call s:hi('GitGutterAdd', 'success', '')
call s:hi('GitGutterChange', 'attention', '')
call s:hi('GitGutterDelete', 'danger', '')
call s:hi('GitGutterChangeDelete', 'severe', '')
call s:hi('ALEErrorSign', 'danger', '')
call s:hi('ALEWarningSign', 'attention', '')
call s:hi('ALEInfoSign', 'accent', '')
call s:hi('ALEError', '', '', 'undercurl', 'danger')
call s:hi('ALEWarning', '', '', 'undercurl', 'attention')
call s:hi('ALEInfo', '', '', 'undercurl', 'accent')

" Colores del :terminal, los mismos de Kitty.
if &background ==# 'dark'
  let g:terminal_ansi_colors = [
        \ '#545d68', '#f47067', '#57ab5a', '#c69026', '#539bf5', '#b083f0', '#39c5cf', '#909dab',
        \ '#636e7b', '#ff938a', '#6bc46d', '#daaa3f', '#6cb6ff', '#dcbdfb', '#56d4dd', '#cdd9e5',
        \ ]
else
  let g:terminal_ansi_colors = [
        \ '#24292f', '#cf222e', '#116329', '#4d2d00', '#0969da', '#8250df', '#1b7c83', '#6e7781',
        \ '#57606a', '#a40e26', '#1a7f37', '#633c01', '#218bff', '#a475f9', '#3192aa', '#8c959f',
        \ ]
endif

delfunction s:hi
unlet s:c
