# TestRunner — VM provisioning

Детали (архитектура, маркеры, сеть, готчи) → `docs/CONTEXT.md`. Читать при работе над областью; в контекст автоматически НЕ грузится.

## Проект
Автоматизация развёртывания Win11 ВМ на Hyper-V под автотесты FlaUI. 2-4 ВМ параллельно на хосте. Цикл: VHDX из ISO → создать VM → дебладинг → сеть → .NET/Office/agent → cleanup. Полуручной режим через консольный TUI. Пользователь — сильный программист, sysadmin/DevOps впервые; хочет структуру, а не «кучу скриптов».

## Стек
- **C#** (`Orchestrator/`, .NET 8) — TUI-меню, запуск шагов, статусы, C#-сеть, Azure-агент-менеджмент.
- **PowerShell** (`scripts/`) — рецепты (host/VM).
- **Python** (`Python/`) — сетевой агент на хосте: SOCKS5-прокси (`proxy_socks.py`, TCP+UDP) + TCP-форвард (RDP внутрь) + UDP DNS-форвардер (`dns_forwarder.py`). HTTP-прокси (`proxy.py`) — legacy, не используется.

## Механика суит-скриптов (нужна постоянно)
- Суиты = папки `scripts/{SetupVM,InstallSoft}/NN-Area/`, шаги `NN-Verb-Noun.ps1` по порядку, стоп на первом Failed.
- Шаг = `Verb-Noun.ps1` + `Verb-Noun.check.ps1` (проверка ДО main: exit 0=делать, 2=уже сделано, 1=нельзя/fail).
- **Таргетинг (суит-скрипты):** `$ScriptTarget="Host"|"VM"`. `VM` → раннер сам оборачивает тело в PSDirect `Invoke-Command -VMName -Credential` (не SSH), НЕ пиши Invoke руками. `Host` → выполняется на хосте (там же New-PSSession в гость руками, если надо копировать `-ToSession`).
- `$RootPriviledges=$true` — тело исполняется мгновенной SYSTEM-таской (но SYSTEM-таска НЕ ждёт результат — fire-and-forget; для reboot/ожиданий делай host-side + свой мониторинг).
- **Интерполяция `@@key@@`** — из `ConfigFlattener.Flatten(AppConfig)` (сериализованный AppConfig, camelCase→dot-path) + `StateKeeper.TryGet` (`@@state.host.*@@`, `@@state.vm.*@@` — reflection по модели, `.ToString()`; enum отдаёт имя). **Ключ работает ТОЛЬКО если есть свойство в AppConfig-классе** — добавил в json, добавь и в `AppConfig.cs`, иначе «Placeholder missing».
- **`<<inject::scriptHelpers/X.ps1>>`** — вставка файла-хелпера ДО интерполяции (значит `@@..@@` внутри хелпера тоже раскрываются). PSScriptAnalyzer ругается на `<<` — игнор.
- Config: `default.config.json` (git) + `local.config.json` (gitignored, содержит имя VM/креды/token) поверх. Массивы в конфиге мержатся по индексам (local не заменяет целиком) — для «пустого по умолчанию» ставь `[]`, не `""`.

## C#-архитектура (Orchestrator)
- **AppConfig** (`Config/AppConfig.cs`) — читается ОДИН раз при старте (`Load`→`Current`), правка local.config без перезапуска не подхватится. `PathsConfig.ResolveAgainst` резолвит host-пути против repoRoot; **гостевые пути (`C:\...` внутри VM) НЕ резолвить** (иначе `D:\VMs\C:\...`).
- **Executors** (`Executors/*.cs`, напр. HyperVExecutor/NetExecutor/AzureExecutor) — роль httpClient: гоняют скрипты из `scripts/_system/<ExecutorName>/*.ps1` через `BaseExecutor.RunScript`. **Таргетинг здесь — через `ExecutorTarget` в конструкторе** (Host/VM), НЕ через `$ScriptTarget`. Параметры → `Dictionary<string,string>` → `param()` в скрипте (не интерполяция). Вывод скрипта = JSON → десериализация в **FSModel** (`FSModels/*.cs`).
- **Models** (`Models/NetWorkModels`, `Models/Azure`) — доменные модели в памяти (VM, Host, AgentPool/Agent). **StateKeeper** держит `CurrentHost`/`CurrentVm`/`AgentPool` — источник для `@@state.*@@`.
- **Initializer** (`App/Initializer.cs`) — `LoadHost`/`LoadVmInfo`/`LoadAgentPool`: создают модели, дёргают executors для заполнения, кладут в StateKeeper. `LoadVmInfo` парсит `vm.OfficeApp` из `vm.Name` (`Enum.TryParse ignoreCase`).
- **Меню** (`App/Orchestrator.cs`): SelectHost (+ Add Host заглушка, Azure Management) → VmLoop (Create=выбор OfficeApp-enum, имя VM = app) → VmActionsLoop (Setup/Network/InstallSoft/FullSetup/Remove Machine). Подтверждение необратимого — `_viewer.ConfirmInHeader`.
- **OfficeApp** (`Enums/OfficeApp.cs`): Excel/Word/PowerPoint/Outlook. Одна VM = одно приложение; имя VM = `OfficeApp.ToString()`. В скрипты идёт как `@@state.vm.officeApp@@`.

## Не делать
Async · SSH · SQLite/БД для state · тесты (xUnit) · переписывать Python на C# · DI-контейнер · Serilog · Packer/Ansible/Terraform · абсолютные пути · **комментарии в коде** · трогать реальный NIC хоста · менять не то, что просили.

## Стиль
Русский. Терсе, конкретика, минимально необходимое. Не overthink, не эссе, не survey опций — рекомендация. Не повторять решённое, не льстить, не извиняться без нужды. Код/имена — английский. Меньше tool-каллов, действовать когда фактов хватает.

## Текущее состояние
**Работает весь путь от нуля до «агент слушает сессию».** Осталось: **активация Office** (единственная незакрытая часть; есть черновик `50-GuestOffice/04-Office-Activate(not valid).ps1` — OAuth device-code, не финализирован).

**Сеть (готово):** VM без прямого инета. sing-box (TUN, Wintun) в VM ловит весь трафик → SOCKS5 на хост (`192.168.100.1:socksPort`) → питон. DNS отдельно: sing-box шлёт DNS на `192.168.100.1:dnsPort` (без detour) → питон-`dns_forwarder` резолвит хостовым DNS. TCP/UDP/DNS через хост (Cato). sing-box — **таска at-logon под юзером-админом** (НЕ служба: под SYSTEM DNS не резолвит, а голый `sc create` SCM убивает — служба отвергнута). Порты socks/dns discover'ятся, не в дефолт-конфиге.
- Ключевой баг, который решён: UDP-релей в питоне бил исходящим сокетом в NAT-адрес → наружу не шло; развели на два сокета (клиентский на NAT + `out` без бинда).
- Скачивание в VM: `Invoke-WebRequest` в PSDirect-сессии **виснет на прогресс-баре** — использовать `curl.exe` (или `$ProgressPreference='SilentlyContinue'`). Канал быстрый (~155МБ/6с).

**Готовые шаги InstallSoft:** `00-Setup-SingBox` (таска), `20-WinSDK` (mage.exe для подписи — Windows SDK через winsdksetup.exe из Artifacts, ставит `NETFX 4.8.1 Tools`, копируем в `4.8 Tools` т.к. скрипты подписи ищут этот путь), `30-Chrome` (Enterprise MSI + default browser via DISM), `40-GuestDotnet`, `50-GuestOffice`, `60-Agent`, `70-Cleanup` (graceful reboot через `RebootHelpers.ps1`).

**Agent (`InstallSoft/60-Agent`):** copy zip из Artifacts (`@@paths.agentZip@@`, качаем НЕ в VM) → config (не служба, интерактивно, с `config.cmd remove` если уже настроен) → env-var `{OfficeApp}=True` → таска at-logon (консоль видна, для UI-тестов агент ДОЛЖЕН быть в интерактивной сессии, не в session 0). Имя `{COMPUTERNAME}-desktop-{N}`. Токену нужны Manage-права на пул. После ребута ~минуту `already has active session` — штатно, переподключается.

**Azure-менеджмент:** `AzureExecutor` + `_system/AzureExecutor/*.ps1` (ADO REST через token из конфига) — список/вкл-выкл/удаление агентов пула из меню Azure Management. `Running`=enabled (участие), `Online`=connection (коннект).

**Тестируется вручную:** пользователь пишет свой desktop-WebDriver (Selenium-подобный, поверх UIA/FlaUI) для автоматизации Office-аддинов. FlaUI ищет окно Word по title `<file>.docx - Word` — на VM нужен `HideFileExt=0` юзеру (иначе title без расширения). .NET: 3.5 из ISO (`sources\sxs`, DISM offline), 8 Desktop Runtime из инета.
