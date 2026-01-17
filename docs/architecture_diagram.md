# Agentic Executables Architecture Diagram

```mermaid
graph TB
    subgraph "AI Agent"
        Agent["AI Agent<br/>(Executor)"]
    end
    
    subgraph "MCP Server"
        Server["MCPServer<br/>(Strategic Guidance)"]
        Tools["5 Core Tools"]
        Resources["Resources<br/>(AE Documents)"]
    end
    
    subgraph "Tools"
        GetDef["get_agentic_executable_definition"]
        GetInst["get_ae_instructions"]
        Verify["verify_ae_implementation"]
        Evaluate["evaluate_ae_compliance"]
        Registry["manage_ae_registry"]
    end
    
    subgraph "Registry System"
        GitHubReg["GitHub Registry<br/>(ae_use_registry/)"]
        Resolver["RegistryResolver<br/>(Path Resolution)"]
        Fetcher["GitHubRawFetcher<br/>(File Fetch)"]
        AEFiles["AE Files<br/>(install/uninstall/update/use)"]
    end
    
    subgraph "Framework Core"
        Config["AEFrameworkConfig<br/>(Config & Validation)"]
        Validation["AEValidationConfig<br/>(Compliance Rules)"]
        Docs["AEDocuments<br/>(Cache & Loader)"]
        Prompts["Prompts Framework<br/>(context/bootstrap/use)"]
    end
    
    subgraph "Workflows"
        Author["Library Author"]
        Dev["Developer"]
    end
    
    %% Agent to Server
    Agent -->|requests| Server
    Server -->|provides| Tools
    Server -->|loads| Resources
    
    %% Tools
    Tools --> GetDef
    Tools --> GetInst
    Tools --> Verify
    Tools --> Evaluate
    Tools --> Registry
    
    %% Instructions flow
    GetInst -->|uses| Docs
    Docs -->|loads| Prompts
    
    %% Registry flow
    Registry -->|uses| Resolver
    Registry -->|uses| Fetcher
    Resolver -->|validates| Config
    Fetcher -->|fetches| GitHubReg
    GitHubReg -->|stores| AEFiles
    
    %% Validation flow
    Verify -->|uses| Validation
    Evaluate -->|uses| Validation
    Validation -->|references| Config
    
    %% Author workflow
    Author -->|bootstrap| GetInst
    GetInst -->|provides| Prompts
    Author -->|submit| Registry
    Registry -->|generates PR| GitHubReg
    
    %% Developer workflow
    Dev -->|fetch| Registry
    Registry -->|returns| AEFiles
    AEFiles -->|executes| Agent
    
    %% Framework
    Config -->|defines| Prompts
    Config -->|validates| Resolver
    
    %% Styling
    style Agent fill:#e1f5ff
    style Server fill:#fff4e1
    style Tools fill:#e8f5e9
    style GitHubReg fill:#f3e5f5
    style AEFiles fill:#ffe0e0
    style Config fill:#fff9e6
```

## Key Data Flow

### Library Author Workflow
**Bootstrap**: `Author` → `get_ae_instructions(library, bootstrap)` → `AEDocuments.getDocuments()` → `loads ae_bootstrap.md + ae_context.md` → `creates AE files` → `verify_ae_implementation()` → `evaluate_ae_compliance()` → `manage_ae_registry(submit_to_registry)` → `RegistryResolver.getRegistryPath()` → `generates PR instructions`

**Submit**: `manage_ae_registry(submit_to_registry)` → `validates library_id` → `maps files` → `builds registry path` → `generates PR instructions`

### Developer Workflow
**Fetch**: `Developer` → `manage_ae_registry(get_from_registry, library_id, action)` → `RegistryResolver.getRegistryPath()` → `GitHubRawFetcher.fetchFile()` → `returns ae_install.md` → `Agent executes`

**Install**: `Agent receives ae_install.md` → `parses instructions` → `executes steps` → `verify_ae_implementation()` → `confirms success`

### MCP Server Internal Flow
**Document Loading**: `GetAEInstructionsTool.execute()` → `determines files (context+action)` → `AEDocuments.getDocuments()` → `loads from resources/` → `caches` → `returns JSON`

**Registry Fetching**: `ManageAERegistryTool.execute()` → `validates operation` → `RegistryResolver.getRegistryPath()` → `GitHubRawFetcher.fetchFile()` → `fetches from GitHub raw API` → `returns content`

### Validation Flow
**Verification**: `verify_ae_implementation()` → `receives checklist + files` → `AEValidationConfig.validate()` → `checks principles` → `returns pass/fail`

**Compliance**: `evaluate_ae_compliance()` → `receives files + sections + flags` → `calculates LOC score (<500=PASS, 500-800=WARNING, >800=FAIL)` → `evaluates compliance` → `returns score + recommendations`

### Context & Action Mapping
**Contexts**: `"library"` (maintain AE files) | `"project"` (use AE in projects)

**Actions**: `"bootstrap"` (library only) | `"install"` | `"uninstall"` | `"update"` | `"use"`

**File Mapping**:
- `library + bootstrap` → `ae_bootstrap.md + ae_context.md`
- `library + install` → `ae_context.md` (reference)
- `project + install` → `ae_context.md + ae_use.md`
- `project + use` → `ae_context.md + ae_use.md`

### Registry Structure
**Library ID**: `<language>_<library_name>` (e.g., `python_requests`)

**Registry Path**: `ae_use_registry/<library_id>/<ae_file>`

**Required Files**: `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`, `README.md`

**Operations**: `submit_to_registry` | `get_from_registry` | `bootstrap_local_registry`
