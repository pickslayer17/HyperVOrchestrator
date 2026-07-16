# Copilot Instructions

## Project Guidelines
- Пользователь категорически против overkill-решений: не создавать интерфейсы/абстракции «на вырост», не закрывать все возможные случаи. Выделять конечные состояния и делать минимально достаточное.
- Строго держаться поставленной задачи: никаких побочных предложений и попыток решить всё сразу. При обсуждении существующего нумерованного списка проблем сохранять оригинальную нумерацию пользователя.
- Архитектура и история решений: см. `Orchestrator/docs/copilot-context.md` — читать перед работой над архитектурой.
- Перед внесением изменений в код сначала опишите предполагаемое редактирование и дождитесь явного одобрения пользователя. После явного одобрения конкретной правки нужно реализовать её, а не считать завершённой только потому, что был выполнен другой ранее активный план. Предпочитайте минимальные решения на PowerShell и избегайте кода interop/helper, когда достаточно прямого обновления переменной окружения.
- Если terminal-команда проверки повторно отменяется, не зависать и не повторять её снова; перейти к доступной IDE-проверке и завершить задачу.
- Не использовать количество сетевых адаптеров как способ определить контекст host/VM и не вводить инвариант «в госте ровно один адаптер» без явного требования.

## PowerShell Provisioning Guidelines
- Для PowerShell provisioning scripts ожидаемые идемпотентные условия и несущественные сбои очистки не должны приводить к сбою шага, в то время как сбои основной операции должны оставаться фатальными и видимыми.
- Grant-Access существует для того, чтобы позволить настроенному пользователю VM создавать и работать с папками в C:\; не нужно переписывать ACL рекурсивно по существующим системным файлам Windows. Предпочтительно использовать наследуемый ACL на корне для нового контента.

## HyperVOrchestrator Hardening Work
- Intentionally defer items 1 (Stop-Here), 8 (free-port race), and 9 (persistent PSSession/reconnect); focus only on items 2 through 7. При запросе решений предоставлять конкретные варианты реализации и рекомендуемый подход, а не повторять проблему.
- Host connection collections are visualization-only. Before creating any proxy or forwarding listener, query Python for current live connections. Python is an ephemeral holder of active listeners, persists nothing across restarts, and existing listeners should not be deleted. Each VM may keep its own proxy for simplicity.
- Apply SOLID and KISS principles pragmatically; implement carefully rather than quickly, and thoroughly re-check that related behavior and the build are not broken.
