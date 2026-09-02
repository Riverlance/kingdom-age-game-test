function translateNetworkError(errcode, connecting, errdesc)
  local text

  if errcode == 111 then
    text = loc'${CorelibNetInfoConnectionServerOffOrRestarting}'
  elseif errcode == 110 then
    text = loc'${CorelibNetInfoConnectionFailingOrServerOff}'
  elseif errcode == 1 then
    text = loc'${CorelibNetInfoConnectionServerAddressNotFound}'
  elseif connecting then
    text = loc'${CorelibNetInfoConnectionFailed}'
  else
    text = loc'${CorelibNetInfoConnectionFailingOrServerOff}'
  end

  text = f(loc'%s ${CorelibInfoError}: %d', text, errcode)

  return text
end
