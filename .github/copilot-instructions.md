# Copilot Instructions

## Project Guidelines
- Пользователь категорически против overkill-решений: не создавать интерфейсы/абстракции «на вырост», не закрывать все возможные случаи. Выделять конечные состояния и делать минимально достаточное.
- Строго держаться поставленной задачи: никаких побочных предложений и попыток решить всё сразу. При обсуждении существующего нумерованного списка проблем сохранять оригинальную нумерацию пользователя.
- Архитектура и история решений: см. `Orchestrator/docs/copilot-context.md` — читать перед работой над архитектурой.
- Перед внесением изменений в код сначала опишите предполагаемое редактирование и дождитесь явного одобрения пользователя. После явного одобрения конкретной правки нужно реализовать её, а не считать завершённой только потому, что был выполнен другой ранее активный план. Предпочитайте минимальные решения на PowerShell и избегайте кода interop/helper, когда достаточно прямого обновления переменной окружения.
- Если terminal-команда проверки повторно отменяется, не зависать и не повторять её снова; перейти к доступной IDE-проверке и завершить задачу.
- Не использовать количество сетевых адаптеров как способ определить контекст host/VM и не вводить инвариант «в госте ровно один адаптер» без явного требования.
- Ожидайте краткие, ориентированные на реализацию планы, которые перечисляют точные этапы и включают только конкретные блокировки или сбои; избегайте длинных архитектурных комментариев, непрошенных мнений и просьб к пользователю разрешить согласование контрактов/типов, которое можно определить из кодовой базы.
- Keep workspace context gathering minimal and token-efficient; PythonServer must remain a data-only model with no methods, while PythonExecutor must remain stored inside the PythonServer model and return connection FS data rather than mutating or constructing the application state model. SetupNetwork assigns the retrieved state to the model.
- Во время глубокого этапа разработки проекта сохранять существующие методы/модели и избегать очистки или удаления, если это не было явно одобрено; спрашивать перед удалением API, таких как GetNetworkInfo/GetVmInfo/GetFreePort. Executors должны только выполнять запросы и возвращать модели FS, в то время как код оркестрации сопоставляет и назначает состояние. Сбор контекста и ответы должны быть максимально компактными.
- Executors only communicate with real external systems and return FS models; Initializer and NetworkSetup own orchestration, idempotent checks, mapping, and application-model assignment. PythonExecutor is accessed as host.PythonServer.PythonExecutor. SingBoxExecutor must read config data for both load and NetworkSetup; VM display state uses SOCKS/proxy and DNS data from SingBox config вместо старого пересылаемого порта.
- VM хранит прокси и DNS SingBox как значения IPEndPoint плюс SingBoxRunning. SingBoxExecutor.GetConfig возвращает выделенную модель SingBoxConfigFSModel, содержащую только ключевые значения, возвращает пустую модель, когда конфигурация отсутствует, и выдает исключение, когда существующая конфигурация недействительна.

## PowerShell Provisioning Guidelines
- Для PowerShell provisioning scripts ожидаемые идемпотентные условия и несущественные сбои очистки не должны приводить к сбою шага, в то время как сбои основной операции должны оставаться фатальными и видимыми.
- Grant-Access существует для того, чтобы позволить настроенному пользователю VM создавать и работать с папками в C:\; не нужно переписывать ACL рекурсивно по существующим системным файлам Windows. Предпочтительно использовать наследуемый ACL на корне для нового контента.

## HyperVOrchestrator Hardening Work
- Intentionally defer items 1 (Stop-Here), 8 (free-port race), and 9 (persistent PSSession/reconnect); focus only on items 2 through 7. При запросе решений предоставлять конкретные варианты реализации и рекомендуемый подход, а не повторять проблему.
- Host connection collections are visualization-only. Before creating any proxy or forwarding listener, query Python for current live connections. Python is an ephemeral holder of active listeners, persists nothing across restarts, and existing listeners should not be deleted. Each VM may keep its own proxy for simplicity.
- Apply SOLID and KISS principles pragmatically; implement carefully rather than quickly, and thoroughly re-check that related behavior and the build are not broken.
