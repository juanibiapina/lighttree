if exists("g:loaded_nerdtree_ui_glue_autoload")
    finish
endif
let g:loaded_nerdtree_ui_glue_autoload = 1

function! lighttree#ui_glue#createDefaultBindings()
    let s = '<SNR>' . s:SID() . '_'

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapActivateNode, 'scope': "DirNode", 'callback': s."activateDirNode" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapActivateNode, 'scope': "FileNode", 'callback': s."activateFileNode" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapActivateNode, 'scope': "all", 'callback': s."activateAll" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapOpenRecursively, 'scope': "DirNode", 'callback': s."openNodeRecursively" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapUpdir, 'scope': "all", 'callback': s."upDirCurrentRootClosed" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapUpdirKeepOpen, 'scope': "all", 'callback': s."upDirCurrentRootOpen" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapChangeRoot, 'scope': "Node", 'callback': s."chRoot" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapChdir, 'scope': "Node", 'callback': s."chCwd" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapCWD, 'scope': "all", 'callback': "lighttree#ui_glue#chRootCwd" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapRefreshRoot, 'scope': "all", 'callback': s."refreshRoot" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapRefresh, 'scope': "Node", 'callback': s."refreshCurrent" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapHelp, 'scope': "all", 'callback': s."displayHelp" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapToggleHidden, 'scope': "all", 'callback': s."toggleShowHidden" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapToggleFilters, 'scope': "all", 'callback': s."toggleIgnoreFilter" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapToggleFiles, 'scope': "all", 'callback': s."toggleShowFiles" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapCloseDir, 'scope': "Node", 'callback': s."closeParentDir" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapCloseChildren, 'scope': "DirNode", 'callback': s."closeChildren" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapMenu, 'scope': "Node", 'callback': s."showMenu" })

    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapJumpParent, 'scope': "Node", 'callback': s."jumpToParent" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapJumpRoot, 'scope': "all", 'callback': s."jumpToRoot" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapJumpNextSibling, 'scope': "Node", 'callback': s."jumpToNextSibling" })
    call NERDTreeAddKeyMap({ 'key': g:LightTreeMapJumpPrevSibling, 'scope': "Node", 'callback': s."jumpToPrevSibling" })
endfunction


"SECTION: Interface bindings {{{1
"============================================================

"handle the user activating a tree node
function! s:activateDirNode(node)
    call a:node.activate()
endfunction

"handle the user activating a tree node
function! s:activateFileNode(node)
    call a:node.activate()
endfunction

function! s:chCwd(node)
    try
        call a:node.path.changeToDir()
    catch /^NERDTree.PathChangeError/
        call lighttree#echoWarning("could not change cwd")
    endtry
endfunction

" changes the current root to the selected one
function! s:chRoot(node)
    call b:NERDTree.changeRoot(a:node)
endfunction

" changes the current root to CWD
function! lighttree#ui_glue#chRootCwd()
    try
        let cwd = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("current directory does not exist.")
        return
    endtry
    call s:chRoot(g:NERDTreeDirNode.New(cwd, b:NERDTree))
endfunction

" closes all childnodes of the current node
function! s:closeChildren(node)
    call a:node.closeChildren()
    call b:NERDTree.render()
    call a:node.putCursorHere(0)
endfunction

" closes the parent dir of the current node
function! s:closeParentDir(node)
    let parent = a:node.parent

    if !(parent ==# {})
        call parent.close()
        call b:NERDTree.render()
        call parent.putCursorHere(0)
    endif
endfunction

" toggles the help display
function! s:displayHelp()
    call b:NERDTree.ui.toggleHelp()
    call b:NERDTree.render()
endfunction

function! s:findAndRevealPath()
    try
        let p = g:NERDTreePath.New(expand("%:p"))
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("no file for the current buffer")
        return
    endtry

    if p.isUnixHiddenPath()
        let showhidden=g:LightTreeShowHidden
        let g:LightTreeShowHidden = 1
    endif

    try
        let rootDir = g:NERDTreePath.New(getcwd())
    catch /^NERDTree.InvalidArgumentsError/
        call lighttree#echo("current directory does not exist.")
        let rootDir = p.getParent()
    endtry

    if p.isUnder(rootDir)
        call g:NERDTreeCreator.RestoreOrCreateBuffer(rootDir.str())
    else
        call g:NERDTreeCreator.RestoreOrCreateBuffer(p.getParent().str())
    endif

    let node = b:NERDTree.root.reveal(p)
    call b:NERDTree.render()
    call node.putCursorHere(1)

    if p.isUnixHiddenFile()
        let g:LightTreeShowHidden = showhidden
    endif
endfunction

"this is needed since I cant figure out how to invoke dict functions from a
"key map
function! lighttree#ui_glue#invokeKeyMap(key)
    call g:NERDTreeKeyMap.Invoke(a:key)
endfunction

" Move the cursor to the parent of the specified node. At the root, do
" nothing.
function! s:jumpToParent(node)
    let l:parent = a:node.parent

    if !empty(l:parent)
        call l:parent.putCursorHere(1)
    else
        call lighttree#echo('could not jump to parent node')
    endif
endfunction

" moves the cursor to the root node
function! s:jumpToRoot()
    call b:NERDTree.root.putCursorHere(1)
endfunction

function! s:jumpToNextSibling(node)
    call s:jumpToSibling(a:node, 1)
endfunction

function! s:jumpToPrevSibling(node)
    call s:jumpToSibling(a:node, 0)
endfunction

" moves the cursor to the sibling of the current node in the given direction
"
" Args:
" forward: 1 if the cursor should move to the next sibling, 0 if it should
" move back to the previous sibling
function! s:jumpToSibling(currentNode, forward)
    let sibling = a:currentNode.findSibling(a:forward)

    if !empty(sibling)
        call sibling.putCursorHere(1)
    endif
endfunction

function! s:openNodeRecursively(node)
    call lighttree#echo("Recursively opening node. Please wait...")
    call a:node.openRecursively()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Recursively opening node. Please wait... DONE")
endfunction

" Reloads the current root. All nodes below this will be lost and the root dir
" will be reloaded.
function! s:refreshRoot()
    call lighttree#echo("Refreshing the root node. This could take a while...")
    call b:NERDTree.root.refresh()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Refreshing the root node. This could take a while... DONE")
endfunction

" refreshes the root for the current node
function! s:refreshCurrent(node)
    let node = a:node
    if !node.path.isDirectory
        let node = node.parent
    endif

    call lighttree#echo("Refreshing node. This could take a while...")
    call node.refresh()
    call b:NERDTree.render()
    redraw
    call lighttree#echo("Refreshing node. This could take a while... DONE")
endfunction

function! lighttree#ui_glue#setupCommands()
    command! -n=? -complete=dir -bar LightTree :call g:NERDTreeCreator.RestoreOrCreateBuffer('<args>')
    command! -n=0 -bar LightTreeFind call s:findAndRevealPath()
endfunction

" Function: s:SID()   {{{1
function s:SID()
    if !exists("s:sid")
        let s:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:sid
endfun

function! s:showMenu(node)
    let mc = g:NERDTreeMenuController.New(g:NERDTreeMenuItem.AllEnabled())
    call mc.showMenu()
endfunction

function! s:toggleIgnoreFilter()
    call b:NERDTree.ui.toggleIgnoreFilter()
endfunction

function! s:toggleShowFiles()
    call b:NERDTree.ui.toggleShowFiles()
endfunction

" toggles the display of hidden files
function! s:toggleShowHidden()
    call b:NERDTree.ui.toggleShowHidden()
endfunction

"moves the tree up a level
"
"Args:
"keepState: 1 if the current root should be left open when the tree is
"re-rendered
function! lighttree#ui_glue#upDir(keepState)
    let cwd = b:NERDTree.root.path.str({'format': 'UI'})
    if cwd ==# "/" || cwd =~# '^[^/]..$'
        call lighttree#echo("already at top dir")
    else
        if !a:keepState
            call b:NERDTree.root.close()
        endif

        let oldRoot = b:NERDTree.root

        if empty(b:NERDTree.root.parent)
            let path = b:NERDTree.root.path.getParent()
            let newRoot = g:NERDTreeDirNode.New(path, b:NERDTree)
            call newRoot.open()
            call newRoot.transplantChild(b:NERDTree.root)
            let b:NERDTree.root = newRoot
        else
            let b:NERDTree.root = b:NERDTree.root.parent
        endif

        call b:NERDTree.render()
        call oldRoot.putCursorHere(0)
    endif
endfunction

function! s:upDirCurrentRootOpen()
    call lighttree#ui_glue#upDir(1)
endfunction

function! s:upDirCurrentRootClosed()
    call lighttree#ui_glue#upDir(0)
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
