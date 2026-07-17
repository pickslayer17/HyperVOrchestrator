# TestRunner — VM provisioning

Детали (архитектура, маркеры, сеть, готчи) → `docs/CONTEXT.md`. Читать при работе над областью; в контекст автоматически НЕ грузится.

## Проект
Автоматизация развёртывания Win11 ВМ на Hyper-V под автотесты FlaUI. 2-4 ВМ параллельно на хосте. Цикл: VHDX из ISO → создать VM → дебладинг → сеть → .NET/Office/agent → cleanup. Полуручной режим через консольный TUI. Пользователь — сильный программист, sysadmin/DevOps впервые; хочет структуру, а не «кучу скриптов».

## Стек
- **C#** (`Orchestrator/`, .NET 8) — запуск шагов, статусы, меню, C#-сеть.
- **PowerShell** (`scripts/`) — рецепты (host/VM).
- **Python** (`Python/`) — сетевой агент на хосте: HTTP-прокси для гостей + TCP-форвард (RDP наружу).

## Механика скриптов (нужна постоянно)
- Суиты = папки `scripts/{SetupVM,InstallSoft}/NN-Area/`, шаги по порядку, стоп на первом Failed.
- Шаг = `Verb-Noun.ps1` + `Verb-Noun.check.ps1` (проверка ДО: exit 0=делать, 2=уже сделано, 1=нельзя).
- Скрипты — чистые функции: значения приходят интерполяцией `@@key@@` (config+state), не дотсорсят.
- `$ScriptTarget="Host"|"VM"` — где исполнять (VM = PSDirect `Invoke-Command -VMName -Credential`, не SSH). `$RootPriviledges=$true` — тело в SYSTEM-таске.
- Config: `default.config.json` (git) + `local.config.json` (gitignored) поверх. Рантайм-значения (IP, порты) — discover в чеках, не в конфиге.

## Не делать
Async · SSH · SQLite/БД для state · тесты (xUnit) · переписывать Python на C# · DI-контейнер · Serilog · Packer/Ansible/Terraform · абсолютные пути · **комментарии в коде** · трогать реальный NIC хоста · менять не то, что просили.

## Стиль
Русский. Терсе, конкретика, минимально необходимое. Не overthink, не эссе, не survey опций — рекомендация. Не повторять решённое, не льстить, не извиняться без нужды. Код/имена — английский. Меньше tool-каллов, действовать когда фактов хватает.

## Текущее состояние
- **Сеть:** работает, VM проходит все стадии.
- **Agent** (`InstallSoft/70-Agent`): интегрирован — `$ScriptTarget=VM`, `@@agent.*@@`, чек по маркеру `.agent`, имя `{COMPUTERNAME}-{office.apps[0]}-desktop-{N}` (N из живого пула Azure DevOps). Заполнить `orgUrl`/`pool`/`token` в `local.config.json`.
- **Сейчас:** SQL из VM не идёт — HTTP-прокси гонит только HTTP/HTTPS, сырой TCP (1433, БД `*.qa1-eastus.azure.com`, нужен Cato) идёт мимо. Тестируем **Proxifier** (форс всего трафика через хост-прокси). Proxifier 4.14 стоит на TestRunner2, не настроен. Дальше: профиль `.ppx` (proxy `192.168.100.1:52514`, Any→proxy, remote DNS), потом ресет системного прокси в VM. Детали → `docs/CONTEXT.md`.
