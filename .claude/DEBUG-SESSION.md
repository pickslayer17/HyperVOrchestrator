# Debug session notes

## Что сделано (кратко)

- **GuestSetup переразложен** в 4 шага + чеки: `00-Grant-Access`, `01-Disable-Services`,
  `02-Remove-Bloat`, `03-Set-Registry` (в `scripts/10-GuestSetup/`).
- **Хелперы и данные вынесены** в `scriptHelpers/` и `scriptData/` (рядом со `scripts/`,
  не сканируются движком как шаги). Чеки и сет-скрипты работают из одного источника данных.
- **Инъекция helper/data** в скрипт через `<<inject:path>>` — новый слой `core/ScriptInjector.cs`,
  разворачивается ДО интерполяции `@@...@@`. Порядок в ScriptRunner: Read → Inject → Interpolate → WrapForVm → Run.
- **Фикс exit-кодов VM-скриптов**: `exit N` внутри `Invoke-Command -ScriptBlock` наружу не проходил.
  Теперь чеки делают `return N`, а обёртка `WrapForVm` ловит `$__rc = Invoke-Command ...; exit $__rc`.
  Чек-коды: `return 2` = уже сделано (зелёный, скип), `return 0` = делать, `return 1` = нельзя/смоук-фейл.
- **Запуск из VS Code**: `.vscode/launch.json` + `tasks.json`, `console: integratedTerminal`.
  `Ui.Clear()` глотает IOException (нет буфера консоли).
- **Все комментарии убраны** из `core/*.cs`.

## Текущая проблема — машина сама выключается через ~1 час

- **TestRunner2** каждый ~час сама выключается. Hyper-V лог: `18508 "shut down by the guest OS"`
  (гость сам себя гасит, не крэш, не Hyper-V).
- Сначала думали Windows Update — отключили. Не помогло.
- Потом думали sleep/hibernate — применили powercfg-таймауты (standby/hibernate/monitor/disk = 0,
  SCHEME_MIN, /h off, HiberbootEnabled=0). **ВСЁ РАВНО сдохла через час.**
- Значит причина НЕ в стандартных powercfg-таймаутах. Кандидаты: групповая политика питания,
  unattended-sleep таймаут, задача в планировщике, или что-то ещё гасит гостя.

## Следующий шаг

- Из обычного (не-админ) процесса нет прав на Hyper-V (`Get-VM` → "You do not have the required permission").
- **Юзер перезапускает VS Code ОТ АДМИНА**, машина TestRunner2 запущена.
- Дальше: `Invoke-Command -VMName TestRunner2` внутрь гостя и подёргать значения —
  активную схему питания (реальные индексы standby/hibernate/unattended), sleepstudy,
  планировщик задач, power policy из GPO — найти что именно гасит машину через час.
