# 執行摘要  
本報告提出為 Flutter 應用開發一套原生「App 代理人（Agent）」的可重用框架，讓大型語言模型 (LLM) 能透過 Widget 樹/無障礙 (accessibility) 介面來操作 UI。此架構不透過 WebView，而是直接利用 Flutter 的 **語義 (Semantics) 樹** 描述 UI 元件，並結合 LLM 的函數呼叫能力生成操作指令。代理核心週期性地**感知**當前 UI 狀態、**規劃**行動方案、**執行**操作，並透過**驗證**回饋保持同步。報告涵蓋目標與用例、目標平台、API 設計、資料模型、架構設計、LLM 整合、資安隱私、效能、開發者體驗、測試 QA、封裝發佈等，並提供示意圖、API 列表、路線圖、安全檢查表及程式碼範例。此方案鼓勵開發者以 `Semantics` widget 和角色 (如 list、button 等) **語意化**元件【5†L678-L686】【7†L14-L17】；使用 `ActionRegistry` 等機制註冊可呼叫的動作；並設計包含節點識別、動作描述與選擇器等資料結構，方便 LLM 透過 function-calling 控制 UI。整體架構如後圖所示：  

```mermaid
flowchart LR
    UI[Flutter UI（Widget/Semantics 樹）]
    SemanticDesc["語意描述 (Semantic Descriptors)"]
    Planner[規劃器 (LLM 提示生成)]
    LLM[LLM 模型 (函數呼叫)]
    Executor[執行器 (Action 執行)]
    Verifier[驗證器 (結果檢查)]
    UI --> SemanticDesc
    SemanticDesc --> Planner
    Planner --> LLM
    LLM --> Executor
    Executor --> UI
    Executor --> Verifier
    Verifier --> Planner
```  

## 目標與用例  
- **自動化操作 (Automation)**：透過自然語言或預定腳本，讓代理自動完成重複性任務（如表單填寫、導航、多步驟流程），類似 RPA (Robotic Process Automation)。  
- **無障礙輔助 (Accessibility)**：為有障礙的使用者提供更自然的 UI 操作方式，例如語音指令或觀察式交互，由 LLM 分析意圖後執行對應動作。  
- **測試輔助 (Testing)**：結合 LLM 生成的測試案例，自動化驗證 UI 行為；或提供巨集 (Macro) 機制由 LLM 聚合多步驟操作以加速測試。  
- **巨集動作 (Macro actions)**：允許使用者錄製或定義多步驟指令串，由 LLM 學習並重放，如「將資料從 A 輸入至 B，再點擊確認」。  

## 平台與版本  
假設目標為 Android/iOS 雙平台，採用 Flutter 最新穩定版本（截至撰寫時約為 **3.41.2**【33†L717-L720】）。Flutter 持續支援新系統（如 Android 17/iOS 新版）【29†L207-L214】。此 Agent 以 Flutter 內部機制實現，無需 WebView，因此具備與平台 UI 深度整合的優勢。若需跨平台擴充，可考慮未來支援桌面。 

## API 設計  
- **公開 API**：提供單一 `Agent` 或 `AgentCore` 類別作為入口，供應用程式在啟動時呼叫初始化 (如 `AgentCore.initialize()`)，並註冊回調或監聽應用生命週期。  
- **語義註冊**：允許開發者使用 Flutter 的 `Semantics` widget 或註解 (annotation) 為自訂元件指定語意資訊和角色 (role)【5†L678-L686】。例如標示按鈕角色或為自訂清單使用 `SemanticsRole.list/listItem` 等。  
- **動作註冊 (Action Registration)**：提供 `ActionRegistry` 類別，可註冊（`register("名稱", Function)`) 各種動作函式。動作名稱與參數會暴露給 LLM，使之產生結構化的 function 呼叫。開發者可註冊預設動作（例如 tap, scroll, inputText）或自訂工具函式。  
- **生命週期與權限**：代理啟用時，需先由使用者顯式同意（opt-in），可透過設定開關或使用對話 (「允許代理人控制 UI？」)。對於需要系統層級許可的操作（如 Android 上可能需要「可及性服務」權限才能模擬手勢），則必須提示用戶至設定頁面開啟。一般而言，控制同一 App 的 UI 無需額外權限；但建議在操作前詢問用戶確認以避免意外行為。  
- **開放及封閉性**：API 設計時需平衡**易用性**與**安全性**。公開的類、方法須清晰命名並附註功能；若未來需替代或移除功能，應預留棄用機制並保持向後相容。  

## 資料模型  
- **語義描述 (Semantic Widget Descriptor)**：定義描述 UI 元件的結構，包括節點唯一 ID、類型 (role)、文字標籤 (label)、提示 (hint)、值 (value)、可操作動作列表等，以及子節點清單。這可對應 Flutter 的 `SemanticsNode` 屬性【17†L47-L53】。例如：  
  ```dart
  class WidgetDescriptor {
    final String id;               // 節點唯一識別
    final String role;             // 元件語意角色 (e.g. "button", "list")
    final String label;            // 用於無障礙的文字標籤
    final String hint;             // 補充說明
    final String value;            // 當前值（如滑桿位置、輸入框內容）
    final List<WidgetDescriptor> children; // 子節點列表
    ...
  }
  ```  
- **節點樹 (Node Tree Schema)**：將上述 `WidgetDescriptor` 組織成樹狀結構，即完整的 UI 語意樹。代理人在每個決策週期會遍歷 Flutter 的 `Semantics` 樹（可透過 `WidgetsBinding.instance.pipelineOwner.semanticsOwner` 取得【35†L83-L92】）並構造這個結構，以便向 LLM 描述當前介面。  
- **動作描述 (Action Descriptor)**：定義可執行的操作，包括動作名稱 (如 `"tap"`, `"enterText"`, `"scroll"`)、目標節點或範圍 (透過選擇器)、以及參數 (如文本內容)。例如：  
  ```dart
  class ActionDescriptor {
    final String actionName;            // 動作名稱
    final Map<String, dynamic> args;    // 參數 (例如座標、文本等)
    // 也可包含用於選擇目標節點的 Selector 定義
  }
  ```  
- **選擇器 (Selector)**：在 Action 中標記目標節點，可支援多種方式，例如以語意標籤 (label)、角色 (role)、Key 或節點路徑定位。比方說 `{ "by": "label", "value": "提交" }` 表示選取標籤為「提交」的按鈕；或 `{ "by": "id", "value": "node123" }` 指定具體節點。這類結構能對應到 Flutter 的部件 Key 或 Semantics ID，以準確定位目標。 

## 執行時架構  
整體架構由多個模組組成，如下圖所示：  

```mermaid
flowchart LR
    UI[Flutter UI（Widget/Semantics 樹）]
    SemanticDesc["語意描述 (Semantic Descriptors)"]
    Planner[規劃器 (LLM 提示生成)]
    LLM[LLM 模型 (函數呼叫)]
    Executor[執行器 (Action 執行)]
    Verifier[驗證器 (結果檢查)]
    UI --> SemanticDesc
    SemanticDesc --> Planner
    Planner --> LLM
    LLM --> Executor
    Executor --> UI
    Executor --> Verifier
    Verifier --> Planner
```

- **Agent Core (代理核心)**：協調整個流程。依序執行「感知 → 規劃 → 執行 → 驗證」循環。感知時從 UI 生成 `WidgetDescriptor` 樹；規劃時組裝提示 (Prompt) 供 LLM 呼叫；執行時將 LLM 回傳的動作逐一套用；驗證時確認 UI 狀態改變符合預期。  
- **Planner (規劃器)**：生成 LLM 提示詞 (prompt)，其中包含當前介面描述、用戶意圖以及可用動作函式定義（參考 OpenAI 函數呼叫格式【25†L623-L631】）。規劃器解析 LLM 的輸出，將其轉為 `ActionDescriptor` 列表。  
- **LLM (大型模型)**：如 ChatGPT、Claude、Gemini 或 on-device 模型 (如 Google FunctionGemma【21†L108-L116】)，支援函數呼叫格式返回結構化動作。  
- **Executor (執行器)**：負責將 `ActionDescriptor` 轉換為對 Flutter UI 的實際操作。此處可使用 Flutter 的事件系統或語意服務：例如透過 `WidgetsBinding.instance.pipelineOwner.semanticsOwner.performAction(id, SemanticsAction.tap)` 來模擬點擊【39†L17-L25】【35†L83-L92】；或直接操作對應 Widget 的函式。執行後可暫停/等待 UI 更新，以便驗證。  
- **Verifier (驗證器)**：檢查每次執行結果，可重新讀取語意樹或檢視特定元件狀態，判定動作是否達到預期，並決定是否繼續下一步，或在必要時修正錯誤 (例如重新規劃)。  
- **沙盒與併發**：執行器應在安全範圍內操作，只允許預先註冊的安全動作，避免任務失控。LLM 呼叫與執行過程建議在隔離執行緒或非 UI 執行緒中進行，以防阻塞介面。可考慮使用 Dart `Isolate` 進行並發處理。  

## LLM 整合  
- **函數呼叫模式 (Function-Calling)**：採用 OpenAI 風格的 function-calling 或類似模式，將可用動作定義 (JSON schema) 傳遞給模型【25†L623-L631】。如同 OpenAI 文件所述，將工具 (function) 列表與提示一起發送給模型，模型若判斷需要執行動作，會返回一個工具呼叫 (tool call) 的 JSON 物件【25†L667-L676】【25†L684-L692】。系統讀取此輸出，對應到 `ActionDescriptor` 並執行。  
- **提示模板 (Prompt Template)**：提示內容應包含目標「函式」（可對應到 Action 名稱與參數），以及清楚描述當前 UI 狀態（節點屬性與結構）。例如：  
  > “**Available actions**: tap(nodeID), inputText(nodeID, text), scroll(direction). **UI**: A form with fields ‘名稱’，‘年齡’，and a button ‘提交’. **Task**: 點擊 ‘提交’ 按鈕。請以 JSON `{action: ..., args:{...}}` 格式返回。”  
  此類模板可確保模型輸出符合預期結構，且根據語意節點 ID 進行操作。  
- **串流與延遲**：對於大型模型可考慮使用串流 (streaming) 輸出，以便部分動作可以隨時執行而不需等待完整響應。若本地模型延遲過高，可設定超時或降級機制：例如先行使用預設策略、或提醒用戶等待、並在背後接續處理。  
- **本地 vs 雲端模型**：可選擇在裝置本地運行模型或使用雲端 API。**本地方案**例如採用 [FunctionGemma](https://ai.google.dev/models/functiongemma) 模型與 `flutter_gemma` 插件，使 LLM 在裝置上運行【21†L60-L64】。這可大幅降低延遲、費用與隱私風險【21†L60-L64】。**雲端方案**則利用 OpenAI、Anthropic 等 API，優點是更強大的模型與計算資源，缺點是網路依賴及延遲較高。可支援混合模式：若本地失敗或需要更精確回答時，再切換雲端。  
- **模型選擇**：針對行動裝置，可使用輕量模型；[21†L108-L116]提到 FunctionGemma 270M 約 288MB（僅 int8）且可嵌入 App 中執行。若採用雲端，則可用 GPT-4o、Claude Sonnet 等最新模型。根據應用場景平衡模型大小、精度、成本與延遲。  

## 安全與隱私  
- **動作權限與同意**：代理人執行操作前須獲得使用者明確同意，可在 UI 顯示許可提示或設定頁面開關。若涉及跨應用的自動化操作（Android Accessibility Service），則需使用者手動允許無障礙服務。建議限制代理只能操作當前應用內已註冊的動作函式，並限制關鍵 API（例如結帳、刪除資料）的使用權限。  
- **敏感資料處理**：UI 可能包含個人資料（如姓名、電子郵件等），不應將此類敏感資訊直接發送給外部 LLM。可在構造提示前**脫敏**：例如用泛稱或 id 替代真實名字，僅提供必要的上下文。若使用雲端 API，亦需使用 TLS/HTTPS 保護傳輸。遵守 GDPR、CCPA 等規範，並在隱私政策中告知資料用途。  
- **稽核日誌 (Audit Log)**：代理人應記錄所執行的每個動作（含時間、動作名稱、參數），以便後續檢查與回溯。這有助於發現誤操作，並可提供「還原」或「取消」機制。  
- **模型誤用風險**：LLM 可能產生錯誤或不當的動作呼叫【41†L16-L19】。需在系統層面檢查 LLM 回傳是否符合已定義格式（例如只從 `ActionRegistry` 清單中選取動作），並避免執行未知動作。對於安全性高的操作，可要求額外確認（例如二次確認提示）。  
- **隔離與沙盒**：將 LLM 呼叫與 UI 執行隔離，避免惡意提示影響系統穩定。例如，可以在獨立執行緒處理 LLM 輸出，確保主 UI 執行緒安全。  

## 效能考量  
- **運算與記憶體開銷**：在裝置本地執行 LLM 模型會占用大量記憶體（[21†L108-L116]指出FunctionGemma執行需約551MB RAM）和計算資源；雲端調用則產生網路延遲及 API 費用。應依硬體資源選擇適當模型並進行必要量化優化 (如 Int8 量化)。  
- **電池消耗**：持續地語音辨識或連續對話模型會耗電；應在不需要時暫停 LLM 運算，並在操作過程中批次處理模型呼叫以降低切換成本。  
- **UI 影響**：代理運作時切勿卡住主執行緒。UI 狀態獲取和更新可在下游執行緒完成；可使用 Flutter 的 **無障礙樹** 來增量獲取狀態，避免頻繁重建完整樹。  
- **併發與同步**：如需同時監聽多項輸入（例如語音指令與界面事件），須謹慎處理同步。建議將 LLM 交互設為事件驅動 (event-driven)，並使用併發控制 (如 Dart Futures 或 Streams) 來管理多個動作。  

## 開發者體驗  
- **整合步驟**：開發者在 `pubspec.yaml` 加入本套件依賴，並在 `main()` 中或應用啟動流程中呼叫初始化。例如：  
  ```dart
  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    AgentCore.initialize(config: AgentConfig(...));
    runApp(MyApp());
  }
  ```  
- **元件註解與標記**：鼓勵開發者使用 `Semantics(label: "...")` 或自訂的註解包裹 Widget，提供代理人語意參考。如在按鈕上加上 `Semantics(button: true, label: "提交")`，讓代理人能辨識。可提供註解生成工具 (Annotation) 或 IDE 插件，減少手動重複標記負擔。  
- **開發與偵錯工具**：在開發階段可提供**偵錯模式**，例如在畫面上顯示語意節點、動作日誌或提示輸出，方便開發者調整提示詞格式與註冊的動作。也可整合 DevTools，提供「一步步執行代理動作」的功能。  
- **遷移說明**：若應用已使用 WebView Page Agent 等解決方案，需重新對應選擇器與資料模式：將 CSS/XPath 選擇器改為對應的語意 ID 或 Key，將 DOM 事件改為對應的語意操作 (如 tap)。開發者可利用 Page Agent 的提示邏輯和訊息，再套用到語意框架下。  
- **運行時模式切換**：預設應允許在「開發模式」關閉代理功能，以免影響常規操作；需明確開啟才能啟動 LLM 交互。  

## 測試與 QA  
- **單元測試**：對代理的邏輯元件（如 Planner、ActionRegistry、Executor）撰寫單元測試，例如針對固定的提示與 UI 狀態驗證是否產生預期動作。可用假資料模擬 `WidgetDescriptor`，檢查解析結果與行為呼叫。  
- **整合測試**：使用 Flutter 的 widget/integration_test 進行端對端測試。可模擬用戶操作並檢查代理人響應，例如在測試用例中模擬語音/文字指令，驗證代理完成指定任務。亦可加入對主要動作函式的覆寫驗證（mock）以捕捉被呼叫參數。  
- **無障礙測試**：運用 Flutter 的無障礙檢測 API 來驗證介面設計。Flutter 提供 Accessibility Guideline API，可用 `meetsGuideline` 進行自動化測試【33†L659-L668】。例如驗證點擊目標是否具備適當大小與標籤、文字對比度等【33†L659-L668】。  
- **模糊測試 (Fuzzing)**：對提示與 UI 狀態輸入執行模糊測試，包括隨機生成或變異提示詞、不同語意標籤配置，以測試代理的魯棒性，確保不會因意料外輸入崩潰。  
- **持續整合 (CI)**：將上述測試整合進 CI 管道，保證每次提交能通過核心功能測試，並對模型或提示更新進行回歸檢測。  

## 封裝與發行  
- **Package 結構**：此專案建議以 Flutter Plugin (而非純 Dart package) 形式實作，以便未來如需使用平台通道 (Platform Channels) 調用原生無障礙功能或其他系統 API。基本結構包括：  
  - `lib/`：核心 Dart API 代碼。  
  - `example/`：示範整合範例。  
  - `android/`、`ios/`：若需要原生支援 (可及性服務、Gesture 模擬等)。  
  - `pubspec.yaml`：標明支援的 Flutter/Dart SDK 版本與相依套件。  
  - `test/`：包含單元與 widget 測試。  

- **相依與平台渠道**：若只使用 Flutter 原生 API（Semantics 等）即可實現，可不需額外原生程式碼。但如需進一步控制 (如擷取當前 App 截圖、開啟系統對話框等)，則可在 `android/src`、`ios/Runner` 中實作對應功能，並透過 `MethodChannel` 暴露給 Dart。發布時註明支援的平台 (Android/iOS 版本)。  
- **版本管理**：遵循 [語義版本](https://semver.org/lang/zh-TW/) (Semantic Versioning)。小更新 (新增功能、不破壞相容性) 提升 minor 版號，重大更新 (破壞相容性) 則更新 major 版號並詳述遷移指南。所用各模型與函式呼叫標準也應明確定義並同步對應更新。  
- **Example 示範**：在套件中提供完整的例程 (example)，示範如何標註 Widget、註冊動作、呼叫代理等，幫助開發者快速上手。  

## 公共 API 概覽  

| 類別/函數         | 角色            | 功能說明                                          |
| ------------------| ---------------| ----------------------------------------------- |
| `AgentCore`       | 主要控制器      | 管理代理生命周期，整合語意樹、LLM、ActionRegistry，啟動/停止代理。     |
| `WidgetDescriptor`| 資料模型        | 表示 UI 元件的語意節點，包括 id、role、label、value、子節點等屬性。   |
| `ActionDescriptor`| 資料模型        | 定義可執行動作，包括動作名稱和參數。                    |
| `Selector`        | 資料模型        | 節點選擇條件，例如依標籤、Key 或路徑定位目標節點。                |
| `ActionRegistry`  | 管理註冊        | 註冊並管理可呼叫的動作函數 (名稱→Function)，供代理執行。        |
| `Planner`         | 規劃器          | 根據當前語意樹和任務目標，生成並發送 prompt 給 LLM，解析回傳動作序列。 |
| `Executor`        | 執行器          | 根據 `ActionDescriptor` 執行對應 UI 操作 (如 tap、scroll、輸入文字等)。  |
| `Verifier`        | 驗證器          | 檢查動作執行結果是否符合預期，更新內部狀態或指示重試/結束。        |
| `LLMClient`       | LLM 介面層      | 封裝與 LLM API (本地或雲端) 的通訊，包括提示發送和回應處理。        |

## MVP 路線圖  

| 里程碑              | 描述                                   | 優先級  | 預估工作量 |
| -------------------| --------------------------------------| -------|--------- |
| 原型架構搭建         | 實作基礎 `AgentCore`、語意樹擷取與簡單 LLM 呼叫    | 高      | 1 人月    |
| 語意描述與樹構建     | 完成 `WidgetDescriptor` 構造，解析並儲存 UI 語意樹 | 高      | 1 人月    |
| 動作與註冊系統       | 建立 `ActionDescriptor` 與 `ActionRegistry`，實作常見動作 (tap、輸入、滾動) | 高      | 1 人月    |
| LLM 函數呼叫整合     | 整合 Function-Calling 模式 (OpenAI 或本地 Gemma)，處理 JSON 格式輸入/輸出 | 高      | 1.5 人月  |
| 性能與並發處理       | 優化執行緒與非同步邏輯，確保介面順暢、引入串流 (streaming) 支援  | 中      | 0.5 人月  |
| 安全權限機制         | 實作用戶同意提示、稽核日誌、敏感資料處理與動作白名單       | 中      | 1 人月    |
| 完整測試與文件       | 補齊單元/整合測試、Accessibility 測試；撰寫使用說明與範例     | 高      | 0.5 人月  |
| 發佈與版本管控       | 準備發佈至 pub.dev (或 GitHub)，建立發行週期與相容性策略    | 低      | 0.5 人月  |

## 安全/隱私檢查表  
- ✅ **用戶同意**：代理功能需透過界面開關或許可對話明確啟用，不可在未授權情況下操作。  
- ✅ **最小許可原則**：只給予代理人必要動作權限，避免操作敏感功能 (如金融交易)；對潛在危害功能要求額外確認。  
- ✅ **敏感資料遮罩**：在與外部模型通訊前，移除或模糊任何個人/機敏資訊，確保隱私。  
- ✅ **稽核記錄**：完整記錄每步動作（動作名、參數、時間戳），便於事後稽核和錯誤復原。  
- ✅ **動作白名單**：代理人只能呼叫 `ActionRegistry` 中註冊的動作，忽略未知或不安全的指令，防止惡意或錯誤輸出。  
- ✅ **隔離執行**：將 LLM 處理與 UI 更新分離（如使用 Isolate 或後台執行緒），避免界面卡頓或系統崩潰。  
- ✅ **加密通訊**：若使用雲端 API，必須採 HTTPS 傳輸並保護 API 金鑰，符合服務商隱私政策。  
- ✅ **符合標準**：遵循如 WCAG 等無障礙與隱私法規。  

## 核心程式碼範例  

**語意描述 (Semantic Descriptor)：**  
```dart
class WidgetDescriptor {
  final String id;
  final String role;
  final String label;
  final String hint;
  final String value;
  final List<WidgetDescriptor> children;

  WidgetDescriptor({
    required this.id,
    required this.role,
    required this.label,
    this.hint = '',
    this.value = '',
    this.children = const [],
  });
}

// 範例：將 Flutter 的 SemanticsNode 轉換為上述 Descriptor
WidgetDescriptor fromSemanticsNode(SemanticsNode node) {
  return WidgetDescriptor(
    id: node.id.toString(),
    role: node.recognizedValue ?? '',
    label: node.label,
    hint: node.hint,
    value: node.value,
    children: node.children?.map(fromSemanticsNode).toList() ?? [],
  );
}
```

**動作註冊 (Action Registry)：**  
```dart
typedef ActionFunction = Future<void> Function(Map<String, dynamic> args);

class ActionRegistry {
  final Map<String, ActionFunction> _actions = {};

  void register(String name, ActionFunction fn) {
    _actions[name] = fn;
  }

  Future<void> execute(String name, Map<String, dynamic> args) async {
    final action = _actions[name];
    if (action != null) {
      await action(args);
    } else {
      print("未註冊的動作: $name");
    }
  }
}

// 註冊範例
final registry = ActionRegistry();
registry.register('tap', (args) async {
  String nodeId = args['id'];
  // 使用 SemanticsOwner 執行點擊
  WidgetsBinding.instance.pipelineOwner.semanticsOwner
      .performAction(int.parse(nodeId), SemanticsAction.tap);
});
registry.register('enterText', (args) async {
  // 實作文本輸入...
});
```

**LLM 呼叫 Stub：**  
```dart
Future<Map<String, dynamic>> callLLM({
  required String prompt,
  List<Map<String, dynamic>>? functions,
}) async {
  // 示意：呼叫 OpenAI API 或本地模型
  // response 中包含 model 回傳的 function call JSON
  final response = await yourLlmApi.send(
    prompt: prompt,
    functions: functions,
  );
  return response.toMap(); // 假設回傳解析為 Map
}

// 呼叫範例
final prompt = "UI: 按鈕 Submit; Task: 點擊 Submit.";
final functions = [
  {
    'name': 'tap',
    'parameters': {'type': 'object', 'properties': {'id': {'type': 'string'}}}
  }
];
final llmResult = await callLLM(prompt: prompt, functions: functions);
// llmResult['name'] => 'tap', llmResult['arguments'] => {'id': '123'}
```

**執行迴圈 (Executor Loop)：**  
```dart
Future<void> runAgentLoop() async {
  while (true) {
    // 1. 擷取最新 UI 語意並生成 prompt
    String prompt = buildPromptFromUI();
    // 2. 向 LLM 要動作計劃
    final result = await callLLM(prompt: prompt, functions: actionFunctions);
    // 3. 解析並執行動作
    String actionName = result['name'];
    Map<String, dynamic> args = result['arguments'] ?? {};
    await registry.execute(actionName, args);
    // 4. 檢查是否完成任務
    if (shouldStop(result)) break;
  }
}
```

## 從 Page Agent 遷移路徑  
WebView-based Page Agent 一般透過 DOM 標籤/XPath 操作網頁元素；遷移到原生 Flutter 代理時，**核心邏輯可重用**（例如任務分解、提示詞策略），但**UI 層面需重寫**：將原有的 DOM 選擇規則改為對應的語意節點定位 (如 `label` 或 `key`)，將網頁事件 (click、input) 改為對 Flutter 視圖執行相應 Semantics 動作。遷移步驟包括：在 App 中加入 `Semantics` 標註元件，確保代理能識別關鍵元件；重新編寫測試或腳本，使用新 API 註冊和執行動作；並驗證流程在原生 UI 上的執行結果。遷移過程中可編寫兼容層：如設計一組函式介面，同時支持 DOM 操作和 Flutter 操作，逐步替換。

## 風險與限制  
- **模型幻覺 (Hallucination)**：LLM 可能生成錯誤或不相關的動作指令【41†L16-L19】，導致異常操作。需在系統層面檢驗輸出格式，並儘量細化提示詞和訓練（如針對函數呼叫微調）以降低此風險。  
- **可及性依賴**：此方案高度倚賴正確的 `Semantics` 標註。若開發者疏忽標註或使用非標準元件，代理可能無法識別元件。需良好的訓練與驗證機制，確保 UI 的可及性覆蓋率。  
- **平台差異**：Android、iOS 的無障礙與事件系統不完全相同。如需跨平台支援，可能要分別處理。例如，模擬點擊的方法在 iOS 上可能需要不同的 API。  
- **效能限制**：手機端資源有限，大模型運行可能太慢或耗電；云端接口則受限於網絡品質和延遲。必須在實際設備上測試瓶頸，並調整模型與時間預算。  
- **隱私與合規**：使用外部 LLM 會將 UI 資訊傳送到服務端，需注意合規與用戶隱私（如 GDPR）。若 App 涉及敏感領域（金融、醫療），可能需要額外審查。  

## 授權與相容性  
建議使用 **寬鬆的開源授權**（例如 MIT 或 BSD 3-Clause），以鼓勵社群採用並避免相容性問題。Flutter 官方範例程式碼即採用 BSD 3-Clause License【3†L746-L748】，與此相容性高，且便於商業用途。若整合外部模型或工具（如 OpenAI SDK），請注意其授權要求，並在 LICENSE 檔中說明所有相依套件的授權。  

**參考來源：** 本設計參考了 Flutter 官方文件（如 [Semantics 類別和無障礙指南]【3†L699-L701】【5†L678-L686】【7†L14-L17】【33†L659-L668】），以及 LLM 函數呼叫相關文檔【25†L623-L631】【41†L16-L19】。同時參照了現有技術動向，如 FunctionGemma 本地模型【21†L60-L64】【21†L108-L116】和 Flutter AI agent 路線圖【29†L143-L152】以確保方案前瞻性。各段的細節與範例程式碼綜合現有資源及設計推導，確保完整性與實用性。