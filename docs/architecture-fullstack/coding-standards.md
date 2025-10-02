# Coding Standards
- **ASCII-Only Everything:** All strings, filenames, comments, and logs must be plain ASCII; reject or sanitize any Unicode.
- **Use Shared DTOs:** Only use structs in `Include/fairPriceMP/DTO` for state or config exchange.
- **Wrap MT5 API Calls:** Always use provided wrappers (`TradeProxy`, `DrawPrimitives`, `StructuredLogger`) instead of raw APIs.
- **Normalize Values Explicitly:** Normalize every price or lot with `_Digits` or `_Point` before trade submission.
- **Check Return Codes:** Capture `GetLastError()` or result retcodes and log via `StructuredLogger` on failure.
- **Schedule Safely:** Route time-based work through the shared scheduler; no ad-hoc `Sleep` loops or direct timer calls.
- **Config Validation First:** Call and validate `LoadConfig` before any engine starts; halt init on validation failure.
- **Snapshots Are Canonical:** Use `PersistenceManager` for all persistence; do not write arbitrary files or alter schemas without updating docs and tests.

| Element           | Frontend (Dashboard/UI) | Backend (Engines/Services) | Example                      |
|-------------------|-------------------------|-----------------------------|------------------------------|
| Modules/Files     | PascalCase              | PascalCase                  | `DashboardRenderer.mqh`      |
| Functions         | camelCase               | camelCase                   | `renderDashboard()`          |
| Structs/DTOs      | PascalCase              | PascalCase                  | `SymbolRuntimeState`         |
| Constants/Enums   | UPPER_SNAKE_CASE        | UPPER_SNAKE_CASE            | `MAX_SYMBOLS`, `ENUM_MODULE` |
| Global Variables  | g_PrefixCamelCase       | g_PrefixCamelCase           | `g_Config`, `g_SnapshotPath` |
| Logger Event Codes| UPPER_SNAKE (<=10 chars)| UPPER_SNAKE (<=10 chars)    | `SIG_UPD`, `CORR_FAIL`       |