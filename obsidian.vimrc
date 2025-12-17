" Inspirations:
" - https://github.com/chrisgrieser/.config/blob/main/obsidian/vimrc/obsidian-vimrc.vim
" - https://notes.bauer.codes/Obsidian#Obsidian+vim+window+controls


" Navigate back
exmap back obcommand app:go-back
nmap <C-o> :back<CR>

" Navigate forward
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>

" Previous/Next Tab
exmap tabnext obcommand workspace:next-tab
nmap gt :tabnext<CR>
exmap tabprev obcommand workspace:previous-tab
nmap gT :tabprev<CR>

" Emulate Folding https://vimhelp.org/fold.txt.html#fold-commands
exmap togglefold obcommand editor:toggle-fold
nmap zo :togglefold<CR>
nmap zc :togglefold<CR>
nmap za :togglefold<CR>

exmap unfoldall obcommand editor:unfold-all
nmap zR :unfoldall<CR>

exmap foldall obcommand editor:fold-all
nmap zM :foldall<CR>

" visual line navigation fails navigating notes with embeds - MAY NEED TO
" DISABLE
" Have j and k navigate visual lines rather than logical ones, normal mode
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" use logical line navigation in visual mode
vnoremap j j
vnoremap k k
" vnoremap gj j
" vnoremap gk k

" Yank to system clipboard
set clipboard=unnamed
set tabstop=4

" [z]pelling [l]ist (emulates `z=`)
exmap contextMenu obcommand editor:context-menu
nnoremap z= :contextMenu<CR>

" <Esc> clears highlights
nnoremap <Esc> :nohl<CR>

" Move line up/down in visual mode
" TODO: doesn't work with selecting multiple lines
" exmap moveLineDown obcommand editor:swap-line-down
" exmap moveLineUp obcommand editor:swap-line-up
" vnoremap J :moveLineDown<CR>gv=gv
" vnoremap K :moveLineUp<CR>gv=gv

" [M]erge Lines
" the merge from Code Editor Shortcuts plugin is smarter than just using `J`
" since it removes stuff like list prefixes
exmap mergeLines obcommand obsidian-editor-shortcuts:joinLines
unmap J
nnoremap J :mergeLines<CR>
