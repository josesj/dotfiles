" Lightline para github_primer: los modos usan los colores de estado de Primer
" (azul normal, verde inserción, morado visual, rojo reemplazo) y la barra el
" fondo secundario de GitHub. lightline vuelve a leer este archivo al cambiar de
" tema, así que sigue a 'background' como el esquema de colores.
if &background ==# 'dark'
  let s:bg = '#22272e' | let s:subtle = '#2d333b' | let s:border = '#444c56'
  let s:fg = '#adbac7' | let s:muted = '#768390' | let s:on = '#cdd9e5'
  let s:normal = '#316dca' | let s:insert = '#347d39' | let s:visual = '#8256d0'
  let s:replace = '#c93c37' | let s:error = '#e5534b' | let s:warning = '#c69026'
else
  let s:bg = '#ffffff' | let s:subtle = '#f6f8fa' | let s:border = '#d0d7de'
  let s:fg = '#1f2328' | let s:muted = '#656d76' | let s:on = '#ffffff'
  let s:normal = '#0969da' | let s:insert = '#1f883d' | let s:visual = '#8250df'
  let s:replace = '#cf222e' | let s:error = '#d1242f' | let s:warning = '#9a6700'
endif

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

let s:p.normal.left = [[s:on, s:normal, 'bold'], [s:fg, s:border]]
let s:p.normal.middle = [[s:muted, s:subtle]]
let s:p.normal.right = [[s:fg, s:border], [s:muted, s:subtle]]
let s:p.normal.error = [[s:on, s:error]]
let s:p.normal.warning = [[s:bg, s:warning]]

let s:p.insert.left = [[s:on, s:insert, 'bold'], [s:fg, s:border]]
let s:p.visual.left = [[s:on, s:visual, 'bold'], [s:fg, s:border]]
let s:p.replace.left = [[s:on, s:replace, 'bold'], [s:fg, s:border]]

let s:p.inactive.left = [[s:muted, s:subtle], [s:muted, s:subtle]]
let s:p.inactive.middle = [[s:muted, s:subtle]]
let s:p.inactive.right = [[s:muted, s:subtle], [s:muted, s:subtle]]

let s:p.tabline.left = [[s:muted, s:subtle]]
let s:p.tabline.tabsel = [[s:fg, s:bg, 'bold']]
let s:p.tabline.middle = [[s:muted, s:subtle]]
let s:p.tabline.right = [[s:fg, s:border]]

let g:lightline#colorscheme#github_primer#palette = lightline#colorscheme#fill(s:p)
