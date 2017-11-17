mon = peripheral.wrap('left')
term.redirect(mon)
rednet.open('right')
rednet.host('mine','mineman')
rednet.broadcast('mine 50', 'mine')

while true do 
  id, msg, prot = rednet.receive('mine')
  out = id .. ': ' .. msg
  print(out)
  handle = fs.open('/disk/log','a')
  handle.writeLine(msg)
  handle.close()
end
