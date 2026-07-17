# TestRunner — детали проекта

Справочник. НЕ грузится в контекст автоматически (CLAUDE.md ссылается обычной ссылкой, не `@import`). Читать при работе над соответствующей областью.

---

## Оркестратор (C#, `Orchestrator/`, .NET 8)

- `ScriptModelFactory` строит дерево суитов из папок `scripts/` (сорт по имени), гонит шаги по порядку, **стоп на первом Failed**.
- Раннер: `powershell.exe -File` (pwsh7 если есть, иначе 5.1). Пути — относительно корня репо (от расположения exe). Никаких абсолютных `D:\VMs`.
- Граница C#/PowerShell — **по наличию ветвления**, не по технологии: линейные фазы = PS+check; сетевая настройка с комбинаторным состоянием = C# (`NetworkSetup` + экзекьюторы).
- Верхний уровень: `SetupVM` · `ConfigureNetwork` · `InstallSoft` · `Full Setup` (всё подряд, стоп на фейле).
- TUI: хост → `Initializer.LoadHost()` → список VM → `LoadVmInfo` → меню. Вывод только через `ConsoleModelViewer` (`ShowMenu`/`ShowTree`) — потом заменяемо на WinForms.
- Config: `AppConfig` (типизированный класс) → `ConfigFlattener` сериализует его в dot-ключи (`agent.orgUrl`). Новая секция в JSON без класса в `AppConfig` во flatten НЕ попадёт.
- `InterpolateDecorator` **бросает**, если `@@key@@` пуст и в config, и в state (секреты пусты в default, реальные — в local).

## Структура `scripts/`

- `SetupVM/00-CreateAndWinInstall`, `SetupVM/10-GuestSetup` — установка/настройка Windows.
- `InstallSoft/40-GuestDotnet`, `50-GuestOffice`, `60-Cleanup`, `70-Agent`.
- `_system/{NetExecutor,PythonExecutor,HyperVExecutor}/*.ps1` — атомарные задачи для C#-сети, JSON на выходе → FSModels.
- `VM/20-HostNetwork`, `VM/30-GuestNetwork` — **легаси** (были до C#-сети).
- `scriptData/`, `scriptHelpers/`.

## Шаги и маркеры

- Шаг = `Verb-Noun.ps1` + `Verb-Noun.check.ps1`. Чек ДО шага: exit **0**=делать, **2**=уже сделано, **1**=нельзя. Фабрика парит `X.ps1` ↔ `X.check.ps1`.
- Чек снимает реальную картину и решает по ней, не по узкому «а существует ли».
- Скрипты — чистые функции: не знают про корень/соседей, не дотсорсят; значения — интерполяцией.
- Маркеры (обрабатываются до запуска, **порядок важен**): `@@key@@` интерполяция ДО `SystemVariablesReader` (иначе `$ScriptTarget` не подставится и VM-скрипт уйдёт на хост); `<<set::k=v>>`; `<<inject::path>>`; `<<ver::5=x,7=y>>`; `$ScriptTarget="Host"|"VM"`; `$RootPriviledges=$true` (тело в SYSTEM-таске). Литеральный `@@key@@` без ключа и `$ScriptTarget` не строго `Host`/`VM` — БРОСАЕТ (защита от улёта VM-скриптов в хост).
- Сканируется весь файл, включая комменты.

## Конфиг / артефакты

- `default.config.json` (git, структура + пустые креды/пути) + `local.config.json` (gitignored, реальные) мерджится поверх.
- Рантайм-значения (IP, занятые порты) — не из конфига, а discover/verify/record в чеках. Конфиг = константы.
- `Artifacts/` (gitignored): ISO, vhdx, office, unattend, state.json.

## Копирование host → VM

PSDirect (не SSH): `New-PSSession -VMName -Credential` → `Copy-Item -ToSession`. Эталон: `50-GuestOffice/00-Copy-OfficeArchive.ps1`. Креды — из `local.config.json`, не хардкод.

## Сеть (факты, снятые вживую)

- **Хост:** Cato SDP. Адаптер `CatoNetworks` (Cato Tunnel), дефолт-маршрут через Cato (`169.254.254.1`, metric 0), Cato DNS `10.254.254.1`. Физ. NIC `Ethernet` (Intel I219-LM) на корп `192.168.200.x` — **НЕ ТРОГАТЬ** (VM-скрипты дважды туда протекали; цель только `vEthernet(NATSwitch)`).
- **NAT:** `Get-NetNat VMNat = 192.168.50.0/24`. ⚠ Не совпадает с реальной VM-сетью `192.168.100.x` — подозрение, что сырой NAT-egress вообще не работает (нет NAT-правила под 100.0/24); HTTP жив только потому, что идёт на локальный `192.168.100.1` (прокси на NATSwitch, NAT не нужен). Проверить при возврате к сети.
- **VM TestRunner2:** ip `192.168.100.2`, gw `192.168.100.1`, dns `8.8.8.8`. Прокси в госте: `192.168.100.1:52514` на всех уровнях (winhttp + WinINET machine/user + env `HTTP(S)_PROXY`).
- **`Python/`:** `proxy.py` — HTTP-прокси (CONNECT + plain), исходящий сокет создаётся **с хоста** → попадает в Cato (потому HTTPS/Word работает). `forwarder.py` — сырой TCP-форвард (сейчас RDP наружу), коннект к таргету тоже с хоста. IPC — loopback TCP `127.0.0.1:47653` (не named pipe).
- **DB-таргеты тестов (единственное, чему нужен Cato):** `db-dcqaar11f01` / `db-dcqar11f1` / `db-dcqarc11f1` `.qa1-eastus.azure.com`, порт 1433. Вероятно резолвятся только через Cato-DNS.
- **Проблема:** `SqlClient` HTTP-прокси не умеет → SQL (1433) идёт мимо прокси по дефолтному маршруту → не через Cato → фейл. Прочий трафик (API-запросы) идёт в любой сети.

## Proxifier (в процессе проверки)

- Идея: форс **всего** TCP+DNS приложений через хост-прокси → реоригинация с хоста → Cato. Закрывает дыру HTTP-only прокси.
- Установлен **4.14** в `C:\Program Files (x86)\Proxifier\` на TestRunner2. Silent: инсталлятор **Inno Setup**, флаги `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` (NSIS-флаг `/S` НЕ работает — висит GUI).
- Осталось: профиль `.ppx` в `%APPDATA%\Proxifier4\Profiles\` (proxy `192.168.100.1:52514` тип HTTPS/CONNECT, rule **Any→proxy**, **resolve hostnames through proxy**); запуск Proxifier в интерактивной сессии TestUser (тесты идут там). **Потом** ресет системного прокси в VM (winhttp/WinINET/env) — иначе HTTP-петля (клиент лезет на адрес прокси, Proxifier перехватывает и заворачивает в прокси же).
- Страховка при ресете: PSDirect идёт по VMBus, не по сети — VM без интернета всё равно достижима для отката.

## Готчи

- Персистентная PSSession + reconnect после ребута VM — не реализовано.
- RDP-форвард биндит `0.0.0.0` намеренно (внешние клиенты через Cato VPN); харденинг позже.
