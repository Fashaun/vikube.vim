
let g:kubernetes_resource_types = [
      \  'certificatesigningrequests',
      \  'clusterrolebindings',
      \  'clusterroles',
      \  'clusters',
      \  'componentstatuses',
      \  'configmaps',
      \  'controllerrevisions',
      \  'cronjobs',
      \  'customresourcedefinition',
      \  'daemonsets',
      \  'deployments',
      \  'endpoints',
      \  'events',
      \  'horizontalpodautoscalers' ,
      \  'ingresses' ,
      \  'jobs',
      \  'limitranges' ,
      \  'namespaces' ,
      \  'networkpolicies' ,
      \  'nodes' ,
      \  'persistentvolumeclaims' ,
      \  'persistentvolumes' ,
      \  'poddisruptionbudgets' ,
      \  'podpreset',
      \  'pods' ,
      \  'podsecuritypolicies' ,
      \  'podtemplates',
      \  'replicasets' ,
      \  'replicationcontrollers' ,
      \  'resourcequotas' ,
      \  'rolebindings',
      \  'roles',
      \  'secrets',
      \  'serviceaccounts' ,
      \  'services',
      \  'statefulsets',
      \  'storageclasses',
      \ ]

let g:kubernetes_common_resource_types = [
      \"pods", 
      \"persistentvolumeclaims", 
      \"persistentvolumes", 
      \"statefulset", 
      \"replicasets",
      \"deployments", 
      \"endpoints", 
      \"replicasets", 
      \"service", 
      \"serviceaccount"]

let g:vikube_search_prefix = '> '


fun! g:KubernetesNamespaceCompletion(lead, cmd, pos)
  let entries = vikube#get_namespaces()
  cal filter(entries , 'v:val =~ "^' .a:lead. '"')
  return entries
endf

fun! g:KubernetesResourceTypeCompletion(lead, cmd, pos)
  let entries = g:kubernetes_resource_types
  cal filter(entries , 'v:val =~ "^' .a:lead. '"')
  return entries
endf

fun! s:source()
  let cmd = "kubectl get " . b:resource_type
  if b:wide
    let cmd = cmd . " -o wide"
  endif
  if b:all_namespace
    let cmd = cmd . " --all-namespaces"
  else
    let cmd = cmd . " --namespace=" . b:namespace
  endif
  redraw | echomsg cmd
  return system(cmd . "| awk 'NR == 1; NR > 1 {print $0 | \"sort -b -k1\"}'")
endf

fun! s:header()
  return "Kubernetes namespace=" . b:namespace . " resource=" . b:resource_type . " wide=" . b:wide
endf

fun! s:help()
  cal g:Help.reg(s:header(),
    \" ]]    - Next resource type\n".
    \" [[    - Previous resource type\n".
    \" }}    - Next namespace\n".
    \" {{    - Previous namespace type\n".
    \" u     - Update List\n" .
    \" w     - Toggle wide option\n" .
    \" N     - Toggle all namespaces\n" .
    \" n     - Switch namespace view\n" .
    \" r     - Switch resource type view\n" .
    \" D     - Delete " . b:resource_type . "\n" .
    \" s     - Describe " . b:resource_type . "\n" .
    \" Enter - Describe " . b:resource_type . "\n"
    \,1)
endf

fun! s:canonicalizeRow(row)
  return substitute(a:row, '^\*\?\s*' , '' , '')
endf

fun! s:fields(row)
  let matched = s:canonicalizeRow(a:row)
  return split(matched, '\s\+')
endf

fun! s:namespace(row)
  let fields = s:fields(a:row)
  if b:all_namespace
    return fields[0]
  else
    return b:namespace
  endif
endf

fun! s:key(row)
  let fields = s:fields(a:row)
  if b:all_namespace
    return fields[1]
  endif
  return fields[0]
endf

fun! s:handleUpdate()
  redraw | echomsg "Updating pod list ..."
  let b:source_changed = 1
  cal s:render()
endf

fun! s:handleDelete()
  let key = s:key(getline('.'))
  let cmd = 'kubectl delete ' . b:resource_type . ' ' . shellescape(key)
  redraw | echomsg cmd
  let out = system(cmd)
  redraw | echomsg split(out, "\n")[0]
  let b:source_changed = 1
  cal s:render()
endf


func s:handleNamespaceChange()
  cal inputsave()
  let new_namespace = input('Namespace:', '', 'customlist,KubernetesNamespaceCompletion')
  cal inputrestore()
  if len(new_namespace) > 0
    let b:namespace = new_namespace
  endif
  let b:source_changed = 1
  cal s:render()
endf

func s:handleNextNamespace()
  let namespaces = vikube#get_namespaces()
  let x = index(namespaces, b:namespace) + 1
  if x >= len(namespaces)
    let x = 0
  endif
  let b:namespace = namespaces[x]
  let b:source_changed = 1
  cal s:render()
endf

func s:handlePrevNamespace()
  let namespaces = vikube#get_namespaces()
  let x = index(namespaces, b:namespace) - 1
  if x < 0
    let x = len(namespaces) - 1
  endif
  let b:namespace = namespaces[x]
  let b:source_changed = 1
  cal s:render()
endf

func s:handleResourceTypeChange()
  cal inputsave()
  let new_resource_type = input('Resource Type:', '', 'customlist,KubernetesResourceTypeCompletion')
  cal inputrestore()
  if len(new_resource_type) > 0
    let b:resource_type = new_resource_type
  endif
  let b:source_changed = 1
  cal s:render()
endf


fun! s:handlePrevResourceType()
  let x = index(g:kubernetes_common_resource_types, b:resource_type)
  let x = x - 1
  if x < 0
    let x = len(g:kubernetes_common_resource_types) - 1
  endif
  let b:resource_type = g:kubernetes_common_resource_types[x]

  let b:source_changed = 1
  cal s:render()
endf


fun! s:handleNextResourceType()
  let x = index(g:kubernetes_common_resource_types, b:resource_type)
  let x = x + 1
  if x >= len(g:kubernetes_common_resource_types)
    let x = 0
  endif
  let b:resource_type = g:kubernetes_common_resource_types[x]

  let b:source_changed = 1
  cal s:render()
endf

fun! s:handleToggleAllNamepsace()
  if b:all_namespace == 1
    let b:all_namespace = 0
  else
    let b:all_namespace = 1
  endif

  let b:source_changed = 1
  cal s:render()
endf

fun! s:handleToggleWide()
  if b:wide == 1
    let b:wide = 0
  else
    let b:wide = 1
  endif

  let b:source_changed = 1
  cal s:render()
endf

fun! s:handleApplySearch()
  let b:current_search = getline(2)
  cal s:render()
endf


fun! s:handleStartSearch()
  let t:search_enabled = 1
  let b:current_search = ""
  setlocal updatetime=1000
  cal s:render()
endf

fun! s:handleStopSearch()
  let t:search_enabled = 0
  setlocal updatetime=5000
  cal s:render()
endf

fun! s:handleDescribe()
  let line = getline('.')
  let namespace = s:namespace(line)
  let key = s:key(line)
  let resource_type = b:resource_type
  let cmd = 'kubectl describe ' . resource_type . ' --namespace=' . namespace . ' ' . key
  redraw | echomsg cmd

  let out = system(cmd)
  botright new
  silent exec "file " . key
  setlocal noswapfile nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile bufhidden=wipe
  setlocal modifiable
  silent put=out
  redraw
  silent normal ggdd
  silent exec "setfiletype kdescribe" . resource_type
  setlocal nomodifiable

  nnoremap <script><buffer> q :q<CR>

  syn match Label +^\S.\{-}:+ 
  syn match Error +Error+ 
endf


fun! s:render()
  let save_cursor = getcurpos()
  if b:source_changed || !exists('b:source_cache')
    let b:source_cache = s:source()
    let b:source_changed = 0
  endif

  if t:search_enabled
    let lines = split(b:source_cache, "\n")
    let rows = lines[1:]
    let current_search = getline(2)
    let s = strpart(current_search, len(g:vikube_search_prefix))
    cal filter(rows, 'v:val =~ "' . s . '"')
    let out = join(lines[:0] + rows, "\n")
  else
    let out = b:source_cache
  endif

  setlocal modifiable

  " clear the buffer
  normal ggdG

  " draw the result
  put=out

  " remove the first empty line
  normal ggdd

  " prepend the help message
  cal s:help()

  if t:search_enabled
    cal append(1, "")
    if !exists('b:current_search') || len(b:current_search) < len(g:vikube_search_prefix)
      cal setline(2, g:vikube_search_prefix)
    else
      cal setline(2, b:current_search)
    endif
    let save_cursor[1] = 2
    if save_cursor[2] < len(g:vikube_search_prefix) + 1
      let save_cursor[2] = len(g:vikube_search_prefix) + 1
    endif
    call setpos('.', save_cursor)
    set modifiable
    startinsert
  else
    call setpos('.', save_cursor)
    " trigger CursorHold event
    if exists("g:vikube_autoupdate")
      call feedkeys("\e")
    endif
    set nomodifiable
  endif

endf


fun! s:Vikube(resource_type)
  tabnew
  let t:search_enabled = 0
  let t:result_window_buf = bufnr('%')

  let b:namespace = "default"
  let b:source_changed = 1
  let b:current_search = ""
  let b:wide = 1
  let b:all_namespace = 0
  let b:resource_type = a:resource_type
  exec "silent file VikubeExplorer"
  setlocal noswapfile  
  setlocal nobuflisted nowrap cursorline nonumber fdc=0 buftype=nofile bufhidden=wipe
  setlocal cursorline
  setlocal updatetime=5000
  cal s:render()
  silent exec "setfiletype vikube-" . b:resource_type

  " default local bindings
  nnoremap <script><buffer> /     :cal <SID>handleStartSearch()<CR>
  nnoremap <script><buffer> D     :cal <SID>handleDelete()<CR>
  nnoremap <script><buffer> u     :cal <SID>handleUpdate()<CR>
  nnoremap <script><buffer> <CR>  :cal <SID>handleDescribe()<CR>
  nnoremap <script><buffer> s     :cal <SID>handleDescribe()<CR>
  nnoremap <script><buffer> w     :cal <SID>handleToggleWide()<CR>
  nnoremap <script><buffer> N     :cal <SID>handleToggleAllNamepsace()<CR>
  nnoremap <script><buffer> n     :cal <SID>handleNamespaceChange()<CR>
  nnoremap <script><buffer> r     :cal <SID>handleResourceTypeChange()<CR>

  nnoremap <script><buffer> ]]     :cal <SID>handleNextResourceType()<CR>
  nnoremap <script><buffer> [[     :cal <SID>handlePrevResourceType()<CR>

  nnoremap <script><buffer> }}     :cal <SID>handleNextNamespace()<CR>
  nnoremap <script><buffer> {{     :cal <SID>handlePrevNamespace()<CR>

  au! InsertEnter  <buffer> :cal <SID>handleStartSearch()
  au! InsertLeave  <buffer> :cal <SID>handleStopSearch()
  au! CursorMovedI <buffer> :cal <SID>handleApplySearch()

  syn match Comment +^#.*+ 
  syn match CurrentPod +^\*.*+
  syn region Search start="^> .*" end="$"
  hi link CurrentPod Identifier

endf

com! VikubePodList :cal s:Vikube("pods")
com! Vikube :cal s:Vikube("pods")

if exists("g:vikube_autoupdate")
  au! CursorHold VikubeExplorer :cal <SID>render()
endif
