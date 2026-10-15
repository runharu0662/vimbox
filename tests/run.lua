vim.opt.rtp:prepend(vim.fn.getcwd())
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, 'p')
local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(kind)
 if kind == 'data' then return temp end
 return original_stdpath(kind)
end
local storage = require('vimbox.storage')
assert(#storage.load() == 0)
local q = require('vimbox.queue')
assert(q.push('first'))
assert(q.push('second'))
assert(not q.rename(0,'bad'))
assert(not q.rename(2,'  '))
require('vimbox').open()
local input = vim.api.nvim_get_current_buf()
local function key(buf, lhs)
 for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf,'n')) do
  if m.lhs == lhs then m.callback(); return end
 end
 error('missing '..lhs)
end
vim.api.nvim_buf_set_lines(input,0,-1,false,{'draft'})
key(input,'<Tab>')
local list = vim.api.nvim_get_current_buf()
vim.api.nvim_win_set_cursor(0,{2,0})
key(list,'r')
assert(vim.api.nvim_buf_get_lines(input,0,-1,false)[1]=='second')
vim.api.nvim_buf_set_lines(input,0,-1,false,{'  corrected  '})
key(input,'<CR>')
assert(q.list()[1]=='first' and q.list()[2]=='corrected')
assert(#q.list()==2)
assert(vim.api.nvim_get_current_buf()==list)
assert(vim.api.nvim_buf_get_lines(input,0,-1,false)[1]=='draft')
key(list,'r')
vim.api.nvim_buf_set_lines(input,0,-1,false,{'   '})
key(input,'<CR>')
assert(q.list()[2]=='corrected')
key(input,'<Tab>')
key(list,'d')
assert(#q.list()==2)
key(input,'<Esc>')
assert(q.list()[2]=='corrected')
assert(vim.api.nvim_buf_get_lines(input,0,-1,false)[1]=='draft')
package.loaded['vimbox.queue']=nil
assert(require('vimbox.queue').list()[2]=='corrected')
key(list,'q')
q = require('vimbox.queue')
assert(q.pop() == 'first')
assert(q.pop() == 'corrected')
assert(q.pop() == nil)
assert(not q.push('  '))
assert(q.push('keep'))
local original_writefile = vim.fn.writefile
local original_notify = vim.notify
local errors = 0
vim.notify = function(_, level)
 if level == vim.log.levels.ERROR then errors = errors + 1 end
end
vim.fn.writefile = function() error('simulated write failure') end
assert(not q.push('lost'))
assert(not q.rename(1, 'lost'))
assert(q.pop() == nil)
assert(q.list()[1] == 'keep' and #q.list() == 1)
vim.fn.writefile = original_writefile
assert(storage.load()[1] == 'keep')
assert(errors == 3)
local original_readfile = vim.fn.readfile
vim.fn.readfile = function() error('simulated read failure') end
assert(not pcall(storage.load))
vim.fn.readfile = original_readfile
local path = temp .. '/vimbox_queue.json'
vim.fn.writefile({'broken JSON'}, path)
assert(not pcall(storage.load))
assert(vim.fn.readfile(path)[1] == 'broken JSON')
vim.fn.writefile({'{"unexpected":true}'}, path)
assert(not pcall(storage.load))
vim.notify = original_notify
vim.fn.stdpath = original_stdpath
vim.fn.delete(temp, 'rf')
print('PASS: FIFO, rename, persistence, UI, cancellation, draft restoration, error paths')
vim.cmd('qa!')
