# ci

獨立的 CI 檢驗工具箱。把 `.ci/` 資料夾放進(或指向)任何專案,它會自動偵測目標專案是前端(Node.js/Vue/React/Electron)還是後端(Node.js/Python),再執行對應的檢查項目。標準是**最嚴格模式:只要出現任何 warning 或未達門檻,就直接 exit code 1、立刻終止流程**。

同時遵守另一條原則:**「工具/套件沒裝」不算「驗證失敗」**。如果某項檢查需要的工具或設定在目標專案裡根本不存在,腳本會印出清楚的原因並以 SKIP(exit 0)結束,不會擋你的 CI;只有工具真的有裝、真的執行、而且真的抓到問題,才會 FAIL(exit 1)。

## 使用方法

### 方式一:直接執行 entrypoint.sh

```bash
.ci/entrypoint.sh /path/to/your-project
```

不帶參數時,預設檢查目前所在的工作目錄:

```bash
cd /path/to/your-project
/path/to/ci-repo/.ci/entrypoint.sh
```

也可以用環境變數指定目標目錄(優先權高於參數):

```bash
TARGET_DIR=/path/to/your-project .ci/entrypoint.sh
```

預設是「一旦有任何一項 FAIL,立刻停止」(fail-fast)。如果想讓所有檢查都跑完、最後一次看完整報告:

```bash
CI_FAIL_FAST=false .ci/entrypoint.sh /path/to/your-project
```

### 方式二:寫進 package.json 的 scripts

把 `.ci/` 資料夾複製進你的前端/Node 後端專案根目錄後,可以這樣接:

**做法 A——獨立的 `ci` script,自己決定何時跑(建議)**

```json
{
  "scripts": {
    "build": "vite build",
    "ci": "bash .ci/entrypoint.sh ."
  }
}
```

本機開發用 `npm run build` 不會被擋,需要驗證時手動 `npm run ci`;CI 平台(GitHub Actions 等)則明確呼叫 `npm run ci`。

**做法 B——掛在 build 前自動觸發**

npm 支援 `pre<script>` 慣例,`prebuild` 會在 `npm run build` 之前自動執行:

```json
{
  "scripts": {
    "prebuild": "bash .ci/entrypoint.sh .",
    "build": "vite build"
  }
}
```

`npm run build` 就會自動先跑完整套 CI 驗證,沒過(exit 1)不會繼續 build。缺點是本機開發也會被拖慢(SCA/SAST 這類檢查通常比較久),所以一般建議用做法 A,只在 CI 平台上才強制跑。

> Windows 環境下 `bash` 需要在 PATH 裡(Git for Windows 安裝後預設就有)。純 Linux/macOS CI runner 通常也是 bash 環境,不需要額外設定。

### 常用環境變數

| 變數                                  | 用途                                                                                                                                |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `TARGET_DIR`                          | 要檢查的專案路徑,優先權高於位置參數                                                                                                 |
| `CI_FAIL_FAST`                        | 設為 `false` 時,跑完所有檢查再統一回報失敗清單,而不是碰到第一個 FAIL 就停(預設 `true`)                                              |
| `CI_COPYRIGHT_NOTICE`                 | [28-license-header.js](.ci/scripts/28-license-header.js) 要求每個 `.ts`/`.go`/`.py`/`.tsx` 檔案開頭必須包含的文字(預設 `Copyright`) |
| `CI_LOCALES_DIR`, `CI_PRIMARY_LOCALE` | [07-i18n-check.js](.ci/scripts/07-i18n-check.js) 的多語系資料夾與主語言(預設 `locales`、`en`)                                       |
| `CI_OPENAPI_BASE`, `CI_OPENAPI_PR`    | [19-api-contract.sh](.ci/scripts/19-api-contract.sh) 要比對的 OpenAPI spec 檔(預設 `openapi-base.yaml`、`openapi-pr.yaml`)          |
| `CI_DB_COMPOSE`                       | [20-db-migration.sh](.ci/scripts/20-db-migration.sh) 用來啟動測試資料庫的 docker-compose 檔(預設 `.ci/db.yml`)                      |
| `CI_K6_SCRIPT`                        | [23-api-performance.sh](.ci/scripts/23-api-performance.sh) 的 k6 壓測腳本路徑(預設 `.ci/perf/script.js`)                            |
| `PR_BODY` / `CI_PR_BODY_FILE`         | [26-pr-template.js](.ci/scripts/26-pr-template.js) 要驗證的 PR 描述文字(通常由 CI 平台帶入)                                         |
| `CI_IMAGE_LIMIT_BYTES`                | [22-image-size.js](.ci/scripts/22-image-size.js) 的圖片大小上限(預設 300KB)                                                         |

## 完整檢查清單

「必要套件/工具」欄位裡,**獨立執行檔**代表要另外裝到 PATH(不是 npm 套件);**node_modules**代表要裝在目標專案的 `devDependencies` 裡,`npx` 才找得到。「無套件時行為」統一都是 **SKIP**(exit 0,不擋 CI),只有工具真的裝了、真的執行、真的抓到問題才會 FAIL。

### 通用檢查(前端/後端都會跑)

| 檢查項目                                                          | 驗證目標                                                   | 必要套件/工具                                                                              | 無套件時行為                                      |
| ----------------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| [05 機密資訊掃描](.ci/scripts/05-secrets-scan.sh)                 | 原始碼裡不能有 API Key、私鑰、JWT、Token                   | `gitleaks` 或 `trufflehog`(獨立執行檔)                                                     | SKIP「兩者都沒裝」                                |
| [06 錯別字檢查](.ci/scripts/06-spelling.sh)                       | 註解/變數/文件拼字                                         | `cspell` 或 `codespell`(獨立執行檔)                                                        | SKIP「兩者都沒裝」                                |
| [08 Markdown 排版](.ci/scripts/08-markdown-lint.sh)               | 標題階層、連結有效性、格式                                 | `markdownlint`(全域)或 `markdownlint-cli`(node_modules);`markdown-link-check` 選配         | SKIP「未安裝」                                    |
| [16 PII 個資洩漏](.ci/scripts/16-pii-check.js)                    | 禁止 `console.log`/`print` 等直接印出 email/phone/ssn 欄位 | 無(純 Node 邏輯)                                                                           | 永遠執行,不會 SKIP                                |
| [25 Commit Message 規範](.ci/scripts/25-commit-message.sh)        | Conventional Commits + JIRA 單號                           | 需為 git repo;有 `commitlint` 設定就用它,否則用內建 regex(無額外依賴)                      | SKIP「非 git repo」                               |
| [26 PR Template 檢查](.ci/scripts/26-pr-template.js)              | PR 描述字數門檻 + checklist 全勾                           | 環境變數 `PR_BODY` 或 `CI_PR_BODY_FILE`(由 CI 平台帶入)                                    | SKIP「沒有 PR body,不在 PR context 裡」           |
| [27 Supply Chain / Typosquatting](.ci/scripts/27-supply-chain.sh) | 偵測疑似模仿知名套件的惡意套件名                           | 有 `socket` CLI 就用它,否則用內建 Levenshtein heuristic(無額外依賴,僅比對約 30 個知名套件) | 內建 heuristic 一律會跑;無 `package.json` 才 SKIP |
| [28 Header License Notice](.ci/scripts/28-license-header.js)      | 每個 `.ts`/`.tsx`/`.go`/`.py` 檔頭要有版權宣告             | 無(純 Node 邏輯);用 `CI_COPYRIGHT_NOTICE` 設定要比對的文字                                 | 永遠執行,不會 SKIP                                |
| [29 Git History Hygiene](.ci/scripts/29-git-history.sh)           | 禁止 >5MB 大檔進歷史、禁止殘留 merge conflict 標記         | 需為 git repo;有 `git-sizer` 就用它,否則用內建邏輯(無額外依賴)                             | SKIP「非 git repo」                               |
| [30 Environment / Node Version](.ci/scripts/30-env-version.sh)    | 本機/CI runtime 版本需與 `.nvmrc`/`.python-version` 一致   | 對應版本檔存在時才檢查;`node`/`python3` 需在 PATH                                          | SKIP「找不到版本檔」                              |

### 程式碼品質(前端/後端共用邏輯,依專案語言自動切換工具)

| 檢查項目                                                | 驗證目標                                                                                          | 必要套件/工具                                                                                               | 無套件時行為                                     |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [01 Coding Style](.ci/scripts/01-coding-style.sh)       | Lint + 格式化,`--max-warnings 0`                                                                  | 需有 `.eslintrc.*`/`eslint.config.*` + `eslint`(node_modules);`prettier` 選配;Python 用 `black`(獨立執行檔) | SKIP「無設定檔」或 SKIP「缺少套件 eslint」       |
| [02 Type Check](.ci/scripts/02-type-check.sh)           | TS `--strict` / Python `mypy --strict`                                                            | 需有 `tsconfig.json` + `typescript`(node_modules);Python 需 `mypy`(獨立執行檔)                              | SKIP「無型別設定」或 SKIP「缺少套件 typescript」 |
| [03 Dead Code](.ci/scripts/03-dead-code.sh)             | 未使用變數/imports、重複程式碼                                                                    | `knip` 或 `jscpd`(node_modules);Python 用 `vulture`(獨立執行檔)                                             | SKIP「兩者都沒裝」                               |
| [04 Complexity](.ci/scripts/04-complexity.sh)           | 單一函數圈複雜度 ≤ 10                                                                             | 同 01(共用 eslint 設定);Python 用 `radon`(獨立執行檔)                                                       | SKIP「無可用工具」                               |
| [11 危險 API 禁用](.ci/scripts/11-dangerous-api.sh)     | 禁用 `eval()`/`innerHTML=`/`console.log`/`no-eval`;Python 禁用 `eval/exec/os.system/pickle.loads` | 需有 eslint 設定檔 + `eslint`(node_modules);Python 分支免額外套件(純 grep)                                  | SKIP「缺少套件 eslint」                          |
| [13 SCA 套件漏洞掃描](.ci/scripts/13-sca-scan.sh)       | 依賴套件已知高/嚴重漏洞                                                                           | `npm`(隨 Node 內建)+ **必須有 `package-lock.json`**;Python 用 `pip-audit`(獨立執行檔)                       | SKIP「缺少 lockfile」或 SKIP「pip-audit 未安裝」 |
| [14 SAST 靜態資安分析](.ci/scripts/14-sast-scan.sh)     | SQL Injection / XSS 等安全漏洞掃描                                                                | `semgrep`(獨立安裝,`pip install semgrep`)                                                                   | SKIP「semgrep 未安裝」                           |
| [15 開源授權合規](.ci/scripts/15-license-compliance.sh) | 擋 GPL/AGPL 等具傳染性授權                                                                        | `license-checker`(node_modules);Python 用 `pip-licenses`(獨立執行檔)                                        | SKIP「缺少套件 license-checker」                 |
| [17 單元/整合測試](.ci/scripts/17-unit-test.sh)         | 所有測試 100% Pass                                                                                | `package.json` 需定義 `"test"` script;Python 用 `pytest`(獨立執行檔)                                        | SKIP「未定義 test script」                       |
| [18 測試覆蓋率](.ci/scripts/18-test-coverage.sh)        | 整體覆蓋率 ≥ 80%                                                                                  | 自動偵測 `vitest` 或 `jest`(node_modules,擇一實際安裝者);Python 用 `pytest` + `pytest-cov`(獨立執行檔)      | SKIP「Jest/Vitest 皆未設定」或 SKIP「缺少套件」  |

### 前端專屬(偵測到 React/Vue/Angular/Svelte/Next/Nuxt/Vite 時才會加跑)

| 檢查項目                                                    | 驗證目標                                               | 必要套件/工具                                                                                                    | 無套件時行為                  |
| ----------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| [07 i18n 多語系完整性](.ci/scripts/07-i18n-check.js)        | 主語言新增的 key,其他語系檔要 100% 同步                | 無(純 Node 邏輯);需有 `locales/*.json`(路徑可用 `CI_LOCALES_DIR` 調整)                                           | SKIP「找不到 locales 資料夾」 |
| [12 設計系統 Token](.ci/scripts/12-design-token.sh)         | CSS/SCSS 禁止寫死 hex color                            | 需有 `.css`/`.scss` 檔才會跑;有 `.stylelintrc` 就用 `stylelint`,否則用內建 regex(無額外依賴)                     | SKIP「找不到 CSS/SCSS 檔」    |
| [21 Bundle 體積限制](.ci/scripts/21-bundle-size.sh)         | 打包後單檔大小門檻                                     | `size-limit`(+ `.size-limit.json`)或 `bundlesize`(node_modules,擇一)                                             | SKIP「兩者都沒設定」          |
| [22 圖片體積限制](.ci/scripts/22-image-size.js)             | 單張圖片 >300KB 擋下(可用 `CI_IMAGE_LIMIT_BYTES` 調整) | 無(純 Node 邏輯)                                                                                                 | 永遠執行,不會 SKIP            |
| [31 Visual Regression](.ci/scripts/31-visual-regression.sh) | 無頭瀏覽器截圖比對,抓 UI 跑版                          | `@playwright/test`(node_modules)+ 檔名需符合 `*.visual.spec.*`;Percy/Chromatic 需外部服務 token,目前僅提示不代跑 | SKIP「未設定視覺回歸工具」    |

### 後端專屬(偵測到 Express/Koa/Fastify/NestJS 或找不到前端框架標記時才會加跑)

| 檢查項目                                                    | 驗證目標                            | 必要套件/工具                                                                                       | 無套件時行為                                              |
| ----------------------------------------------------------- | ----------------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| [19 API 契約測試](.ci/scripts/19-api-contract.sh)           | 前後端 API Schema 無破壞性變更      | `oasdiff`(獨立安裝)+ 兩份 OpenAPI spec 檔(`CI_OPENAPI_BASE`/`CI_OPENAPI_PR`)                        | SKIP「找不到 spec 檔」或 SKIP「oasdiff 未安裝」           |
| [20 DB Migration 可逆性](.ci/scripts/20-db-migration.sh)    | migration 能 up 也能乾淨 down       | `docker-compose` + `.ci/db.yml`(`CI_DB_COMPOSE`)+ `package.json` 需定義 `migrate:up`/`migrate:down` | SKIP「找不到 compose 檔」或 SKIP「未定義 migrate script」 |
| [23 API 效能基準測試](.ci/scripts/23-api-performance.sh)    | 關鍵 API 回應時間 < 200ms           | `k6`(獨立安裝)+ 壓測腳本(`CI_K6_SCRIPT`,預設 `.ci/perf/script.js`)                                  | SKIP「找不到壓測腳本」或 SKIP「k6 未安裝」                |
| [24 Dockerfile 最佳實踐](.ci/scripts/24-dockerfile-lint.sh) | 禁 root 帳號執行、禁用 `latest` tag | `hadolint`(獨立安裝)+ 專案內要有 `Dockerfile`                                                       | SKIP「找不到 Dockerfile」或 SKIP「hadolint 未安裝」       |

> 目前完全沒有 C#/.NET 專屬支援(尚待補上)。前端/後端的判斷邏輯與各檢查腳本細節,見 [.ci/entrypoint.sh](.ci/entrypoint.sh) 與 [.ci/scripts/](.ci/scripts/)。

## Layout

- `.ci/entrypoint.sh` — 偵測專案類型(frontend / backend / fullstack),並派發對應的檢查腳本。
- `.ci/scripts/NN-*.sh` / `.js` — 每個檢查項目一支腳本,對應 [`docs/CI檢驗.csv`](docs/CI檢驗.csv)。每支腳本:
  - PASS 或 SKIP 都是 exit **0**(不擋 CI),
  - 只有真的執行且找到問題才是 exit **1**(嚴格、零容忍)。
- `.ci/scripts/lib/common.sh` — 共用 bash helper:`ci_pass`/`ci_fail`/`ci_skip`、`skip_check`/`fail_check`/`pass_check`、`has_cmd`/`has_dep`/`has_npm_script`、`require_cmd_or_skip`(缺獨立執行檔時 SKIP)、`require_dep_or_skip`(缺 npm 套件時 SKIP)、`require_npm_script_or_skip`(缺 package.json script 時 SKIP)。

## Adding a new check

1. 建立 `.ci/scripts/NN-your-check.sh`(或 `.js`),照現有腳本的模式寫:`source lib/common.sh`、判斷適用性、工具/套件沒裝就用 `require_cmd_or_skip`/`require_dep_or_skip`/`require_npm_script_or_skip` SKIP,真的執行到才用 `fail_check` 擋下任何 warning。
2. 在 `.ci/entrypoint.sh` 的 `COMMON_CHECKS`、`SHARED_CODE_CHECKS`、`FRONTEND_ONLY_CHECKS` 或 `BACKEND_ONLY_CHECKS` 其中一個陣列裡註冊它。
