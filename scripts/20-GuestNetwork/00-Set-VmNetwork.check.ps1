#:target vm
# check для 00-Set-VmNetwork: достаточно, чтобы ВМ была доступна по PSDirect.
# Сам факт успешного Invoke (его делает оркестратор) = ВМ запущена и доступна.
# Недоступна -> оркестратор словит ошибку и пометит check провалившимся.
Write-Host "VM reachable via PSDirect."
