local term = {}
term.index = 2

function term.getViewport()
  return 50,16,0,0,1,2
end

function term.clearLine()
  return true
end

function term.clear()
  return true
end

function term.pull()
  res = term.index
  term.index = term.index + 1
  return "key_down","stuff","things",res
end
return term