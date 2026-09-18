# Harvest Twin --- Technical Architecture & Agent Handoff

**Status:** Technical source of truth\
**Product:** Harvest Twin\
**Backend:** Supabase\
**Client:** Flutter\
**Purpose:** Give any engineer or AI coding agent enough technical and
product context to continue implementation without needing the original
conversation history.\
**Architecture posture:** Hackathon-fast, production-shaped,
explainable, offline-tolerant, and deliberately narrow.

------------------------------------------------------------------------

## 0. How to use this document

This document is the technical companion to the non-technical **Harvest
Twin Solution Context**. The product document remains authoritative for
*what the product is and why it exists*. This document is authoritative
for *how we should build it*.

When implementation details conflict with the product principles,
preserve the product principles and change the implementation.

An incoming coding agent should read, in order:

1.  **Non-negotiable product invariants**
2.  **System architecture**
3.  **Domain model**
4.  **Value Engine**
5.  **Database design**
6.  **Backend functions and provider adapters**
7.  **Flutter architecture**
8.  **Monitoring**
9.  **Security**
10. **Implementation roadmap**
11. **Agent operating rules**

Do not interpret this as a requirement to build every component
immediately. The architecture is intentionally larger than the first
hackathon slice so that the first implementation does not become a dead
end.

------------------------------------------------------------------------

# 1. Product in one technical paragraph

Harvest Twin is a farmer-first post-harvest decision-support system. A
farmer creates a structured **Harvest Case** describing a real batch:
crop, quantity, harvest status, urgency, farmer-assessed condition,
current/usual plan, location, and practical constraints. The backend
enriches that case with external context such as market prices,
alternative buyers, storage, route/distance economics, weather, and
documented crop-loss/perishability parameters. A deterministic **Value
Engine** generates feasible actions, estimates their expected net value,
compares them with the farmer's baseline plan, and returns one primary
recommendation plus a small number of alternatives. The system keeps the
case active for a limited period and recomputes when relevant external
conditions change. The farmer is alerted only when a change is
materially actionable.

The core product principle is:

> **The farmer knows the crop. The system watches the world around the
> crop.**

The application is not an "AI agronomist." It is a **post-harvest
opportunity and decision engine**.

------------------------------------------------------------------------

# 2. Non-negotiable product invariants

Every implementation and every AI agent modifying the repository must
preserve these unless the team explicitly changes the product direction.

## 2.1 Farmer judgment is first-class data

The system must not silently override the farmer's assessment of
maturity, urgency, visible quality, handling history, or operational
feasibility.

Computer vision, LLM extraction, or other AI may **assist**, but
machine-derived observations must be distinguishable from
farmer-confirmed facts.

If a farmer says a batch must move today, the engine treats that as a
hard constraint unless the farmer changes it.

## 2.2 The decision engine is not an LLM

The numerical recommendation must come from explicit, testable logic.

LLMs may be used for: - converting natural speech/text into a proposed
structured Harvest Case; - translating/localizing explanations; -
simplifying technical reasons into farmer-understandable language; -
optional conversational interaction.

LLMs must not be the source of: - market prices; - weather values; -
distances; - storage capacity; - crop decay parameters; - monetary
calculations; - scenario ranking.

The same structured inputs and context snapshot should produce the same
deterministic recommendation, except for explicitly modeled uncertainty
simulations.

## 2.3 One engine, not disconnected features

Harvest timing, routing, storage, waiting, alternative markets,
alternative buyers, and split-routing are not separate advisory
products. They are different scenario types evaluated by the same Value
Engine.

## 2.4 Always preserve the baseline

Every recommendation should be compared with: 1. the farmer's stated
current/usual plan, if provided; otherwise 2. a documented fallback
baseline such as selling the available batch today at the nearest
eligible market.

The farmer-facing value difference is:

`recommended expected net value - baseline expected net value`

Never invent a favorable baseline merely to make the recommendation look
better.

## 2.5 UI returns decisions, not data overload

The primary farmer output is:

**WHAT → WHERE → WHY → VALUE DIFFERENCE**

Do not turn the farmer interface into a price/weather/analytics
dashboard.

Detailed assumptions, data basis, uncertainty, and alternatives are
available through progressive disclosure.

## 2.6 No false precision

All recommendations are estimates.

Use: - "estimated"; - "approximately"; - ranges where appropriate; -
data timestamps; - assumptions; - uncertainty indicators.

Never promise a buyer, price, income, profit, or exact loss reduction.

## 2.7 Localization must not alter the decision

The optimization result is language-independent.

Translation and TTS happen **after** a canonical structured
recommendation exists. English, Telugu, Hindi, or another language must
represent the same recommendation.

## 2.8 Alert only on meaningful change

A new weather reading or ₹1 price movement is not automatically a
notification.

Recompute silently. Notify only if a material-change policy is
satisfied, for example: - primary recommended action changes; -
destination changes; - urgency changes; - expected value advantage
crosses a configured threshold; - a hard constraint is newly
threatened; - a crop-relevant weather event materially affects the
active case.

## 2.9 Offline/demo resilience is mandatory

The recommendation pipeline must not collapse because one external API
is unavailable.

Every external provider is behind an adapter and may return: - live
data; - cached data; - seeded/demo data; - unavailable.

The recommendation records which source/freshness class was used.

------------------------------------------------------------------------

# 3. Chosen technology stack

## 3.1 Client

**Flutter / Dart**

Target Android first for the hackathon while keeping the project
cross-platform.

Recommended client responsibilities: - farmer input and confirmation; -
local UI state; - localization; - audio capture/playback; - network
status; - lightweight local cache; - rendering recommendations and
alternatives; - invoking trusted backend operations.

The Flutter client must not contain secret API keys or authoritative
Value Engine calculations.

## 3.2 Backend platform

**Supabase**

Use Supabase for: - PostgreSQL; - Auth; - Row Level Security; - Edge
Functions; - Storage; - Realtime where useful; - Cron/scheduled work; -
database migrations; - local development and seeded data.

The client may use `supabase_flutter` for authenticated CRUD on
deliberately exposed user-owned resources. Sensitive orchestration and
third-party API access belongs in Edge Functions.

## 3.3 Server-side language

**TypeScript in Supabase Edge Functions** for orchestration and provider
integrations.

Use SQL/PostgreSQL for: - durable state; - constraints; - RLS; -
indexes; - transactional state transitions; - simple deterministic
database-side operations.

Do not prematurely add a Python microservice. The Value Engine
mathematics proposed for the hackathon is simple enough to implement as
a pure TypeScript domain module and unit-test independently.

A Python service becomes justified only if future requirements introduce
substantial scientific/optimization dependencies that are impractical in
the Edge runtime.

## 3.4 State management

Recommended Flutter stack:

-   Riverpod for dependency injection and application state;
-   `go_router` for routing;
-   repository pattern at the data boundary;
-   immutable domain models;
-   feature-first directory structure.

Avoid placing Supabase calls directly inside widgets.

## 3.5 Local/offline storage

Use a small local persistence layer for: - last opened active cases; -
latest recommendation snapshot; - pending draft Harvest Case; -
localization preferences; - seed/reference data version metadata where
useful.

Do not treat local storage as authoritative for server-owned
recommendation state.

------------------------------------------------------------------------

# 4. High-level system architecture

``` text
┌───────────────────────────────────────────────────────────────────────┐
│                         FLUTTER CLIENT                                │
│                                                                       │
│  Form / Voice / Text                                                  │
│        │                                                              │
│        ▼                                                              │
│  Draft Harvest Case → Farmer Confirmation                             │
│        │                                                              │
└────────┼──────────────────────────────────────────────────────────────┘
         │ authenticated request
         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                    SUPABASE EDGE FUNCTIONS                            │
│                                                                       │
│  create/recompute recommendation                                      │
│        │                                                              │
│        ├── Context Orchestrator                                       │
│        │      ├── MarketPriceProvider                                 │
│        │      ├── WeatherProvider                                     │
│        │      ├── DistanceProvider                                    │
│        │      ├── StorageProvider                                     │
│        │      └── BuyerProvider                                       │
│        │                                                              │
│        ├── Scenario Generator                                         │
│        ├── Value Engine                                               │
│        ├── Split Allocator                                            │
│        ├── Uncertainty Evaluator                                      │
│        ├── Baseline Comparator                                        │
│        └── Explanation Builder                                        │
│                                                                       │
└────────┼──────────────────────────────────────────────────────────────┘
         │ transactional persistence
         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                         POSTGRESQL                                    │
│                                                                       │
│  profiles                                                             │
│  harvest_cases                                                        │
│  harvest_case_constraints                                             │
│  crop_configs                                                         │
│  destinations                                                         │
│  market_price_observations                                            │
│  weather_observations                                                 │
│  storage_options                                                      │
│  context_snapshots                                                    │
│  recommendation_runs                                                  │
│  scenario_results                                                     │
│  recommendation_snapshots                                             │
│  alerts                                                               │
│  provider_fetch_logs                                                  │
│                                                                       │
└────────┬──────────────────────────────────────────────────────────────┘
         │
         │ Supabase Cron / scheduled invocation
         ▼
┌───────────────────────────────────────────────────────────────────────┐
│                         CASE MONITOR                                  │
│                                                                       │
│ Find active cases → refresh relevant context → recompute → diff       │
│ → persist silently OR create actionable alert                         │
└───────────────────────────────────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 5. Core domain model

## 5.1 Harvest Case

The **Harvest Case** is the central aggregate. Everything downstream
operates on it.

Canonical shape:

``` text
HarvestCase
  id
  userId
  cropId
  quantityKg
  location
  harvestStatus
  harvestedAt?
  intendedHarvestAt?
  urgency
  farmerCondition
  currentPlan?
  constraints[]
  languagePreference
  status
  activeUntil
  createdAt
  updatedAt
```

### Harvest status

Recommended enum:

``` text
standing
harvest_planned
harvested
partially_sold
completed
cancelled
```

### Case lifecycle

``` text
draft
  ↓
confirmed
  ↓
evaluating
  ↓
active
  ├── recompute → active
  ├── farmer update → evaluating → active
  ├── sold/completed → completed
  ├── expired → expired
  └── cancelled → cancelled
```

A case should not be monitored indefinitely. `active_until` is crop/case
dependent and may be extended explicitly.

## 5.2 Farmer condition

Keep farmer assessment deliberately simple and explainable.

Possible normalized values:

``` text
not_ready
ready
ripe
very_ripe
damaged
mixed
unknown
```

Store the farmer's original text separately when applicable.

Do not convert a camera prediction into `farmer_condition`.

## 5.3 Constraints

Constraints should be structured rather than buried in free text.

Examples:

``` text
must_sell_by
must_harvest_by
max_travel_km
same_day_sale_required
cold_storage_allowed
max_storage_days
minimum_acceptable_price
preferred_destinations
excluded_destinations
transport_available
custom
```

Each constraint should record: - type; - value; - unit if needed; - hard
vs soft; - source (`farmer`, `system`, `demo`); - created_at.

Hard constraints filter scenarios. Soft constraints may influence
ranking or explanation.

------------------------------------------------------------------------

# 6. Context model

A recommendation must be reproducible from the **context snapshot** used
at computation time.

Never recompute an old recommendation against silently updated external
data and pretend it is the same run.

## 6.1 Context Snapshot

A context snapshot references or embeds the exact external observations
used:

``` text
ContextSnapshot
  id
  harvestCaseId
  createdAt
  marketPriceObservationIds[]
  weatherObservationIds[]
  storageOptionIds[]
  destinationIds[]
  routeEstimates[]
  cropConfigVersion
  providerStatuses
  freshnessSummary
```

This gives us: - traceability; - debugging; - demo credibility; -
historical comparison; - deterministic test fixtures.

## 6.2 Provider result contract

Every external-data adapter should normalize to:

``` text
ProviderResult<T>
  data: T
  sourceType: live | cache | seed
  provider: string
  fetchedAt: timestamp
  sourceTimestamp?: timestamp
  expiresAt?: timestamp
  confidence?: string
  warnings: string[]
```

The Value Engine never talks directly to a vendor-specific API response.

------------------------------------------------------------------------

# 7. External provider architecture

Define interfaces first. Pick/change vendors later.

``` text
MarketPriceProvider
  getPrices(crop, location, radius, timeWindow)

WeatherProvider
  getCurrent(location)
  getForecast(location, horizon)

DistanceProvider
  getRoute(origin, destination, transportMode)

StorageProvider
  findStorage(crop, location, radius)

BuyerProvider
  findBuyers(crop, grade, location, radius)
```

## 7.1 Provider precedence

For each provider:

``` text
live provider
   ↓ on timeout/error/stale/unavailable
recent cache
   ↓
seed/demo dataset
   ↓
explicit unavailable state
```

Never silently replace missing data with invented values.

## 7.2 Timeouts

External calls must have short bounded timeouts. One slow provider
should not block the entire recommendation indefinitely.

Use parallel fetches where dependencies allow.

## 7.3 Cache

Cache normalized provider observations in Postgres.

Suggested freshness classes: - weather current: short; - weather
forecast: short/medium; - market prices: according to publication
cadence; - destinations/storage metadata: long; - crop configuration:
versioned static/reference data.

Actual TTLs must be provider-specific and should not be hardcoded across
unrelated data types.

------------------------------------------------------------------------

# 8. The Value Engine

The Value Engine is the technical heart of Harvest Twin.

It must be: - deterministic; - pure where practical; - testable without
Supabase; - independent from Flutter; - independent from
provider-specific JSON; - explainable; - versioned.

Recommended location:

``` text
supabase/functions/_shared/value_engine/
```

Suggested modules:

``` text
types.ts
crop_decay.ts
transport_cost.ts
storage_cost.ts
scenario_generator.ts
feasibility.ts
value_engine.ts
baseline.ts
split_allocator.ts
uncertainty.ts
explanation_facts.ts
version.ts
```

## 8.1 Canonical scenario

``` text
Scenario
  type
  destination
  quantityAllocation[]
  sellAt
  harvestAt?
  storageOption?
  storageDays
  transportMode
  assumptions[]
```

Scenario types:

``` text
sell_now_usual
sell_now_alternative
wait_then_sell
store_then_sell
split_route
harvest_earlier
harvest_later
```

Only generate scenario types that make sense for the case.

## 8.2 Feasibility first

Do not score impossible options.

Before valuation:

``` text
generated scenarios
        ↓
hard constraint filter
        ↓
data sufficiency check
        ↓
value calculation
```

Examples: - reject 70 km destination if farmer max distance is 40 km; -
reject 2-day storage if storage is forbidden; - reject waiting two days
if the case must sell today; - reject destination if required
buyer/capacity is unavailable.

## 8.3 Net value

Base conceptual model:

``` text
saleable_qty =
  original_qty
  × quality_retention(crop, elapsed_time, temperature, condition)

gross_value =
  Σ(allocation.grade_or_lot saleable_qty × destination_price_per_kg)

expected_net_value =
  gross_value
  - transport_cost
  - storage_cost
  - handling_cost
  - other_explicit_costs
```

Do not hide costs merely because they weaken the recommended
alternative.

## 8.4 Temperature-aware decay

Do not use one universal flat "X% loss per day."

Each supported crop has a versioned configuration derived from
documented evidence.

Conceptually:

``` text
base_decay_rate = crop configuration
temperature_multiplier = f(observed_temperature, crop_reference_temperature)
condition_multiplier = f(farmer_condition)
elapsed = time between relevant harvest/sale points

quality_retention = decay(base_decay_rate,
                          temperature_multiplier,
                          condition_multiplier,
                          elapsed)
```

A simple exponential model is sufficient for V1 if documented and
calibrated:

``` text
retention(t) = exp(-k_effective × t)
```

with:

``` text
k_effective = k_base × temperature_factor × condition_factor
```

A Q10-style temperature factor may be used for the prototype:

``` text
temperature_factor = Q10 ^ ((T - T_ref) / 10)
```

This is a modeling assumption, not a claim that every crop follows an
exact universal Q10 law. Store the assumption and model version.

## 8.5 Crop configuration

``` text
crop_configs
  id
  crop_code
  display_name
  config_version
  reference_temperature_c
  base_decay_rate
  q10_factor
  nominal_shelf_life_min_days
  nominal_shelf_life_max_days
  supported_grades
  source_metadata jsonb
  valid_from
  valid_to?
```

Start with a narrow set of crops. The engine must be config-driven so
adding a crop does not require a second algorithm.

## 8.6 Transport cost

V1:

``` text
transport_cost =
  fixed_loading_cost
  + distance_km × cost_per_km
  + optional quantity component
```

Do not pretend the model is universally accurate. Transport assumptions
should be visible in the explanation basis.

Later versions may use actual vehicle/quote data.

## 8.7 Storage cost

``` text
storage_cost =
  storage_rate_per_kg_day
  × quantity_kg
  × days
  + handling/in-out costs
```

Storage is beneficial only when the expected improvement after decay,
price, storage, and transport exceeds the alternatives.

## 8.8 Baseline algorithm

``` text
if farmer.currentPlan is sufficiently specified:
    baseline = normalize(currentPlan)
else:
    baseline = sell available quantity today
               at nearest eligible market
```

The fallback baseline must be labeled as system-defined.

## 8.9 Scenario ranking

Primary V1 ranking:

``` text
maximize expected_net_value
subject to hard constraints
```

Do not add a mysterious weighted "AI score."

If future product needs multiple objectives (risk, travel burden,
certainty), keep them explicit and auditable. Do not bury them in
arbitrary weights without documentation.

## 8.10 Split-routing

Represent a harvest as one or more sub-lots/grades.

V1 algorithm: 1. order sub-lots by urgency / remaining usable life; 2.
calculate marginal expected net value per kg for eligible destinations;
3. allocate to the best feasible destination; 4. respect
destination/storage/capacity/distance constraints; 5. recompute
remaining capacities; 6. compare split result with non-split
alternatives.

This greedy allocator is appropriate for a hackathon prototype.

Keep the allocator behind an interface so a future linear/integer
optimization solver can replace it without changing the rest of the
pipeline.

## 8.11 Uncertainty

The farmer should not receive false precision.

V1 uncertainty can use a deterministic seeded Monte Carlo/sensitivity
process over uncertain parameters such as: - market price; - temperature
forecast; - transport estimate; - decay parameter.

For a recommendation run: - run a small number of perturbations; -
record seed/model version; - compute median/central estimate; - compute
a reasonable range; - calculate whether the winning scenario remains
stable.

Example canonical output:

``` text
expected_net_value: 15900
estimated_range_low: 15100
estimated_range_high: 16500
baseline_expected_net_value: 13800
value_difference: 2100
recommendation_stability: high
```

Do not present statistical confidence terminology unless the model
genuinely supports that interpretation.

------------------------------------------------------------------------

# 9. Recommendation contract

The engine should produce a structured result before any prose is
generated.

``` json
{
  "recommendation_run_id": "uuid",
  "engine_version": "1.0.0",
  "case_id": "uuid",
  "action": "sell_today",
  "destination": {
    "id": "uuid",
    "name": "Market B",
    "distance_km": 37
  },
  "expected_net_value_inr": 15900,
  "range_inr": [15100, 16500],
  "baseline": {
    "label": "Your current plan",
    "expected_net_value_inr": 13800
  },
  "value_difference_inr": 2100,
  "reasons": [
    {"code": "HIGHER_NET_PRICE"},
    {"code": "TRAVEL_COST_JUSTIFIED"},
    {"code": "SAME_DAY_CONSTRAINT_MET"}
  ],
  "assumptions": [],
  "data_freshness": {},
  "alternatives": [],
  "computed_at": "timestamp",
  "computation_ms": 0
}
```

Farmer-facing prose is rendered from this object.

------------------------------------------------------------------------

# 10. Explanation architecture

Prefer deterministic templates for critical claims.

Example:

``` text
WHAT: Sell today
WHERE: Market B, approximately 37 km away
VALUE: Estimated ₹15,900 after modeled transport
DIFFERENCE: Approximately ₹2,100 more than your current plan
WHY:
- Current observed price is higher.
- Estimated transport cost is still worth the difference.
- This option satisfies your same-day sale requirement.
```

An LLM may rewrite/localize this only if: - all numerical facts are
supplied; - it is instructed not to introduce new facts; - canonical
structured output remains stored; - the system can fall back to
deterministic templates.

For the hackathon, deterministic templates plus normal localization
files are safer than making an LLM a runtime dependency.

------------------------------------------------------------------------

# 11. Database architecture

Use UUID primary keys unless a table has a strong reason not to.

Use: - `timestamptz`; - `numeric` for money/precise decimal values; -
check constraints; - foreign keys; - explicit enums or constrained text
where evolution needs are considered; - `created_at`; - `updated_at`
where mutable; - source/version metadata for reference data.

## 11.1 Core tables

### `profiles`

``` text
id uuid PK → auth.users.id
display_name text
preferred_language text
phone text?
created_at timestamptz
updated_at timestamptz
```

### `harvest_cases`

``` text
id uuid PK
user_id uuid FK
crop_id uuid FK
quantity_kg numeric
latitude numeric?
longitude numeric?
location_label text?
harvest_status text
harvested_at timestamptz?
intended_harvest_at timestamptz?
urgency text?
farmer_condition text?
farmer_condition_notes text?
current_plan jsonb?
status text
active_until timestamptz?
language_code text
created_at timestamptz
updated_at timestamptz
```

Location precision should be minimized to what the product needs. Do not
collect exact farm coordinates merely because the device can provide
them.

### `harvest_case_constraints`

``` text
id uuid PK
harvest_case_id uuid FK
constraint_type text
value jsonb
is_hard boolean
source text
created_at timestamptz
```

### `crop_configs`

As defined in the Value Engine section.

### `destinations`

Generic destination abstraction:

``` text
id uuid PK
type text -- mandi | buyer | processor | storage
name text
latitude numeric
longitude numeric
metadata jsonb
source_name text
source_external_id text?
is_demo boolean
updated_at timestamptz
```

### `market_price_observations`

``` text
id uuid PK
crop_id uuid FK
destination_id uuid FK
grade text?
price_per_kg numeric
observed_for timestamptz
fetched_at timestamptz
source_name text
source_type text -- live/cache/seed
raw_reference jsonb?
```

### `weather_observations`

``` text
id uuid PK
harvest_case_id uuid?
location_key text
observation_type text -- current/forecast/event
temperature_c numeric?
humidity_percent numeric?
rain_mm numeric?
wind_kph numeric?
event_codes text[]?
valid_from timestamptz
valid_to timestamptz?
fetched_at timestamptz
source_name text
source_type text
raw_reference jsonb?
```

### `storage_options`

``` text
id uuid PK
destination_id uuid FK
crop_id uuid?
capacity_kg numeric?
rate_per_kg_day numeric?
cold_storage boolean
availability_status text
observed_at timestamptz
source_name text
source_type text
```

### `context_snapshots`

``` text
id uuid PK
harvest_case_id uuid FK
payload jsonb
context_hash text
created_at timestamptz
```

For V1, a JSONB snapshot is intentionally acceptable because it freezes
the normalized input to the engine. Important observations may also
remain normalized in their own tables.

### `recommendation_runs`

``` text
id uuid PK
harvest_case_id uuid FK
context_snapshot_id uuid FK
trigger_type text
engine_version text
status text
started_at timestamptz
completed_at timestamptz?
computation_ms integer?
error_code text?
error_detail text?
created_at timestamptz
```

Trigger types:

``` text
initial
farmer_update
manual_refresh
weather_change
price_change
scheduled_monitor
demo_simulation
```

### `scenario_results`

``` text
id uuid PK
recommendation_run_id uuid FK
scenario_type text
rank integer
is_feasible boolean
infeasibility_reasons text[]
expected_net_value numeric?
range_low numeric?
range_high numeric?
transport_cost numeric?
storage_cost numeric?
estimated_saleable_qty numeric?
payload jsonb
created_at timestamptz
```

Persisting evaluated scenarios makes the system auditable and makes "See
other options" cheap.

### `recommendation_snapshots`

``` text
id uuid PK
recommendation_run_id uuid FK UNIQUE
harvest_case_id uuid FK
primary_scenario_result_id uuid FK
baseline_scenario_result_id uuid FK
action_code text
destination_id uuid?
expected_net_value numeric
range_low numeric?
range_high numeric?
baseline_net_value numeric
value_difference numeric
reason_codes text[]
assumptions jsonb
data_basis jsonb
created_at timestamptz
```

### `alerts`

``` text
id uuid PK
user_id uuid FK
harvest_case_id uuid FK
previous_recommendation_id uuid?
new_recommendation_id uuid FK
alert_type text
severity text
reason_codes text[]
localized_payload jsonb?
status text
created_at timestamptz
read_at timestamptz?
```

### `provider_fetch_logs`

Useful for demo/debugging:

``` text
id uuid PK
provider text
operation text
status text
source_type text
latency_ms integer?
error_code text?
created_at timestamptz
```

Do not store provider secrets or unnecessarily large raw payloads in
logs.

------------------------------------------------------------------------

# 12. Row Level Security

RLS is mandatory on user-owned tables exposed through the Data API.

Principle:

``` text
authenticated user may access rows where row.user_id = auth.uid()
```

For child tables without direct `user_id`, authorize through their
parent Harvest Case.

Examples of user-owned data: - harvest_cases; - constraints; -
recommendations; - scenario results; - alerts.

Reference data such as crop configurations and public destination
metadata may be read-only to authenticated/anonymous clients if the
product needs direct access, but writes remain privileged.

Service-role access is server-side only.

Never ship a service-role/secret key in Flutter.

For operations that require privileged multi-table access, use an
authenticated Edge Function that: 1. validates the caller; 2. confirms
case ownership; 3. performs server-side work; 4. writes with controlled
privileged access.

------------------------------------------------------------------------

# 13. Edge Functions

Recommended initial functions:

``` text
create-harvest-case
evaluate-harvest-case
recompute-harvest-case
simulate-context-change       # demo/dev only
monitor-active-cases          # service-to-service
extract-harvest-input         # optional AI/STT phase
render-recommendation         # optional localization/AI phase
```

Do not create dozens of tiny network functions. Shared domain code
belongs under `_shared`.

## 13.1 `evaluate-harvest-case`

Pseudo-flow:

``` text
authenticate
↓
load + authorize Harvest Case
↓
validate case is confirmed/evaluable
↓
fetch crop config
↓
fetch external contexts concurrently
↓
normalize provider responses
↓
create immutable Context Snapshot
↓
generate scenarios
↓
filter infeasible scenarios
↓
calculate baseline
↓
run Value Engine
↓
run uncertainty evaluation
↓
rank scenarios
↓
persist RecommendationRun + ScenarioResults + RecommendationSnapshot
↓
return canonical recommendation
```

Use an idempotency key or run guard so accidental client retries do not
produce uncontrolled duplicate work.

## 13.2 Failure behavior

Partial context failure does not automatically mean total failure.

Example: - live weather failed; - recent cached weather exists; - market
price live succeeded.

The engine may proceed with explicit warnings if product safety permits.

If required data is unavailable, return a structured
`insufficient_context` result rather than fabricating data.

------------------------------------------------------------------------

# 14. Monitoring architecture

The source product requires active cases to be re-evaluated as the world
changes.

Use **Supabase Cron** to invoke a protected `monitor-active-cases` Edge
Function on a reasonable cadence.

Conceptual flow:

``` text
Cron
  ↓
monitor-active-cases
  ↓
select active cases due for evaluation
  ↓
group/deduplicate external context fetches where practical
  ↓
refresh relevant data
  ↓
recompute recommendation
  ↓
compare old vs new recommendation
  ↓
material change?
  ├── no → persist run, no farmer alert
  └── yes → create alert → push/in-app/voice pathway
```

Do not schedule one cron job per harvest case.

Use one/few scheduler jobs that select due cases.

## 14.1 Material-change policy

Create a single domain function:

``` text
evaluateMaterialChange(previous, next, case) -> MaterialChangeResult
```

Possible rules:

``` text
primary action changed
OR destination changed
OR hard constraint newly at risk
OR abs(value_difference_delta) >= configured INR threshold
OR percentage delta >= configured threshold
OR crop-specific severe weather event intersects relevant time window
```

Thresholds belong in configuration, not scattered through UI code.

## 14.2 Hackathon simulation

The demo should include a protected developer/demo control that injects
a known weather or price change into a demo context.

It must pass through the **same recompute + diff + alert pipeline** as a
real update.

Do not create a fake alert screen disconnected from the engine.

------------------------------------------------------------------------

# 15. Realtime and notifications

Supabase Realtime can be used for: - new recommendation snapshots; -
newly created alerts; - case state changes.

Do not use Realtime as the computation engine.

For a first demo, an in-app alert fed by database changes is enough.

Push notifications can be added later through a provider, invoked from a
trusted server-side path.

Audio playback is an output modality, not a separate recommendation.

------------------------------------------------------------------------

# 16. Voice and language architecture

Target architecture:

``` text
farmer speech
  ↓
speech-to-text
  ↓
natural language extraction
  ↓
PROPOSED structured Harvest Case
  ↓
farmer confirmation/correction
  ↓
canonical Harvest Case
```

Never allow speech extraction to skip confirmation when the extracted
values materially affect the recommendation.

Output:

``` text
canonical RecommendationSnapshot
  ↓
localized deterministic template / optional controlled LLM rendering
  ↓
localized text
  ↓
optional TTS
```

Store canonical reason codes, not only translated prose.

Example:

``` text
HIGHER_NET_PRICE
TRAVEL_COST_JUSTIFIED
WEATHER_RISK_INCREASED
SAME_DAY_CONSTRAINT_MET
STORAGE_NOT_ECONOMIC
BASELINE_OUTPERFORMED
```

Localization maps codes into language-specific phrases.

------------------------------------------------------------------------

# 17. Camera/vision architecture

Camera-based grading is an extension, not a dependency.

If added:

``` text
image
  ↓
Storage private bucket
  ↓
vision analysis
  ↓
machine observation
  ↓
farmer confirms/corrects
  ↓
confirmed structured condition/grade
```

Persist: - machine observation; - confidence/metadata; -
farmer-confirmed value;

as separate fields/entities.

Never silently overwrite farmer judgment.

------------------------------------------------------------------------

# 18. Flutter application architecture

Recommended feature-first structure:

``` text
lib/
  app/
    app.dart
    router.dart
    theme/
    localization/

  core/
    config/
    errors/
    network/
    supabase/
    utils/
    widgets/

  features/
    auth/
      data/
      domain/
      presentation/

    harvest_case/
      data/
        harvest_case_repository.dart
        harvest_case_remote_data_source.dart
      domain/
        harvest_case.dart
        harvest_constraint.dart
      presentation/
        controllers/
        screens/
        widgets/

    recommendation/
      data/
      domain/
      presentation/

    alternatives/
      data/
      domain/
      presentation/

    alerts/
      data/
      domain/
      presentation/

    settings/
      ...

  shared/
    models/
    widgets/

  main.dart
```

## 18.1 Layer rules

### Presentation

Knows: - view state; - user actions; - controllers/providers.

Does not know: - raw Supabase query syntax; - provider API JSON; - Value
Engine formulas.

### Domain

Contains: - app-facing entities; - domain enums; - validation; -
interfaces.

Avoid Flutter UI imports.

### Data

Contains: - Supabase DTO mapping; - repositories; - remote/local data
sources.

## 18.2 Riverpod

Use Riverpod for: - auth session; - active case; - draft case; -
recommendation state; - alerts; - localization; - repositories.

Prefer explicit AsyncValue/error states over boolean soup such as
`isLoading`, `hasError`, `isRetrying` spread across widgets.

------------------------------------------------------------------------

# 19. Farmer-facing screen flow

Minimal coherent V1:

``` text
Launch
  ↓
Language / lightweight identity
  ↓
Home
  ↓
Register Harvest
  ↓
Confirm Harvest Case
  ↓
Evaluating
  ↓
Primary Recommendation
  ├── Why?
  ├── See other options
  └── Listen
  ↓
Active Case
  ↓
Actionable alert if recommendation materially changes
```

## 19.1 Primary recommendation card

Must prioritize:

``` text
YOUR BEST OPTION TODAY

SELL TODAY
Market B • ~37 km

Estimated net value: ~₹15,900
~₹2,100 more than your current plan

WHY
Better net value • travel is worth it • same-day constraint met

[Listen] [Why?] [See other options]
```

The exact figures above are illustrative only.

## 19.2 Alternative view

Show 2--3 relevant alternatives, not dozens.

Each alternative should use the same comparable fields: - action; -
destination; - estimated net value/range; - difference vs baseline; -
key trade-off.

------------------------------------------------------------------------

# 20. Offline and degraded-network behavior

Low-bandwidth support is an architectural concern, not only a UI
concern.

The app should: - cache the last recommendation for active cases; -
clearly label cached/stale results; - allow a draft Harvest Case to
survive connectivity loss; - retry safe operations; - never present
stale data as live; - keep the primary recommendation lightweight.

The backend should: - cache normalized external observations; - fall
back to bundled/seeded demo data where explicitly allowed; - record
source type and timestamps.

For hackathon reliability, include seed datasets in the repository under
a clear path such as:

``` text
supabase/seed/
  crops.csv
  destinations.csv
  market_prices_demo.csv
  storage_demo.csv
  weather_demo.json
```

Seed data must be labeled demo/synthetic where appropriate.

------------------------------------------------------------------------

# 21. Authentication strategy

Architecture supports Supabase Auth, but authentication is not the
product innovation.

For the hackathon: - allow a simple demo identity or lightweight auth
flow; - do not spend disproportionate time on OAuth polish; - keep
`user_id` ownership throughout the schema so production auth can be
enabled without redesigning data.

For a real farmer deployment, phone-based authentication may be more
appropriate than requiring an email/social identity. That product choice
is intentionally left open.

------------------------------------------------------------------------

# 22. Security

## 22.1 Secrets

Third-party API keys: - Edge Function secrets only; - never Flutter
assets; - never committed `.env`; - never database rows readable by
clients.

## 22.2 Authorization

Every mutation path must answer:

> "Is this authenticated actor allowed to act on this Harvest Case?"

Do not rely on UUID obscurity.

## 22.3 RLS

Enable before exposing tables through the Data API.

Use least privilege.

## 22.4 Storage

If images/audio are added: - private buckets by default; - user-scoped
object paths; - storage RLS; - signed URLs only where necessary; -
lifecycle cleanup for temporary media.

## 22.5 Logging

Do not log: - auth tokens; - secret keys; - full sensitive voice
transcripts unnecessarily; - exact farmer location when not needed.

------------------------------------------------------------------------

# 23. Data provenance and explainability

Every recommendation should be able to answer:

``` text
What farmer facts did we use?
What external observations did we use?
When were they observed?
Were they live, cached, or seeded?
What crop model/version did we use?
What costs/assumptions did we use?
What scenarios were rejected and why?
What was the baseline?
Why did the winning scenario win?
```

This is a first-class architecture requirement.

Store `engine_version`, `crop_config_version`, and immutable context
snapshots.

------------------------------------------------------------------------

# 24. Observability

Track at minimum:

``` text
recommendation computation time
provider latency
provider failure rate
live/cache/seed usage
recommendation run failures
number of feasible scenarios
monitor recomputations
material-change alerts
```

For the hackathon, structured logs plus database run records are enough.

Do not build a large observability platform before the engine works.

------------------------------------------------------------------------

# 25. Testing strategy

## 25.1 Value Engine unit tests --- highest priority

Use fixed fixtures.

Examples:

``` text
higher market price but excessive travel cost → nearer market wins
higher price and justified travel → farther market wins
must sell today → wait scenarios infeasible
storage forbidden → storage scenarios absent/rejected
temperature increase → modeled retention worsens
price unchanged but weather worsens → recommendation may change
split routing → beats all-together route in designed fixture
farmer current plan → selected as baseline
no current plan → documented fallback baseline
```

## 25.2 Golden scenario tests

Create a few end-to-end fixtures with known expected results.

Example fixture:

``` text
tomato_800kg_same_day.json
weather_change_same_case.json
split_grade_case.json
```

These are invaluable for AI agents: an agent can refactor implementation
while proving behavior did not drift.

## 25.3 Database tests

Test: - constraints; - RLS; - ownership; - invalid state transitions; -
privileged functions; - cascade behavior; - read-only reference data
permissions.

## 25.4 Edge Function integration tests

Mock provider adapters.

Test: - live success; - live failure → cache; - cache missing → seed; -
insufficient required context; - idempotent retry; - unauthorized case
access.

## 25.5 Flutter tests

Prioritize: - Harvest Case validation; - confirmation flow; -
recommendation rendering; - loading/error/degraded states; -
alternatives; - alert presentation.

------------------------------------------------------------------------

# 26. Migrations and schema discipline

All schema changes must be migrations under:

``` text
supabase/migrations/
```

Never rely on undocumented Dashboard-only schema edits.

Rules: 1. migration filenames are timestamped and descriptive; 2.
migrations are append-only after shared deployment; 3. RLS is created
with the table, not as a forgotten later task; 4. seed/demo data is
separate from production migrations; 5. destructive migrations require
explicit review; 6. functions using `SECURITY DEFINER` must set a safe
`search_path` and have tightly scoped execution grants.

------------------------------------------------------------------------

# 27. Suggested repository layout

``` text
harvest_twin/
├── README.md
├── TECHNICAL_ARCHITECTURE.md
├── docs/
│   ├── product/
│   │   └── harvest_twin_solution_context.pdf
│   ├── decisions/
│   │   └── ADR-*.md
│   └── data_sources/
│       └── README.md
│
├── lib/
│   ├── app/
│   ├── core/
│   ├── features/
│   ├── shared/
│   └── main.dart
│
├── test/
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   ├── seed.sql
│   ├── seed/
│   ├── tests/
│   └── functions/
│       ├── _shared/
│       │   ├── auth/
│       │   ├── providers/
│       │   ├── value_engine/
│       │   ├── recommendation/
│       │   └── types/
│       ├── evaluate-harvest-case/
│       ├── monitor-active-cases/
│       └── simulate-context-change/
│
├── integration_test/
├── env/
│   └── development.example.json
└── pubspec.yaml
```

------------------------------------------------------------------------

# 28. API boundary principles

Prefer a small number of meaningful backend operations.

Examples:

``` text
POST /functions/v1/evaluate-harvest-case
POST /functions/v1/recompute-harvest-case
POST /functions/v1/simulate-context-change
```

Normal user-owned CRUD can use the Supabase Data API where RLS makes it
safe.

Do not expose raw third-party provider endpoints to Flutter.

------------------------------------------------------------------------

# 29. Performance

The product should feel immediate even though it may consult several
sources.

Strategies: - parallel provider fetches; - cache destination/reference
data; - cache recent normalized observations; - bounded timeouts; -
generate only plausible scenarios; - keep Monte Carlo count modest; -
avoid LLM calls on the critical numerical path; - return canonical
recommendation before optional noncritical enrichment if needed.

Record `computation_ms` for each run.

------------------------------------------------------------------------

# 30. AI policy inside the product

AI is a UX/enrichment layer, not the authority.

## Allowed

-   speech transcription;
-   language detection;
-   structured extraction proposal;
-   translation;
-   explanation simplification;
-   optional image assistance.

## Must be confirmed

-   crop/quantity extracted from ambiguous speech;
-   farmer condition inferred from media;
-   critical time/urgency;
-   current plan when uncertain.

## Forbidden as authoritative input without evidence

-   invented market price;
-   invented weather;
-   invented buyer;
-   invented storage availability;
-   invented distance;
-   invented crop-loss statistic;
-   invented guaranteed profit.

------------------------------------------------------------------------

# 31. Data-source policy

Every production external source must have a short registry entry:

``` text
provider name
data category
official/public status
license/terms notes
coverage
update frequency
fields used
normalization rules
fallback
known limitations
```

Keep this under:

``` text
docs/data_sources/
```

Do not hardwire the architecture to a particular market/weather vendor
until its availability, terms, and data shape have been verified.

The source documents mention categories such as public market-price
data, public storage-location data, weather, and documented crop/loss
guidance. They do not establish a final API vendor contract. Therefore
provider interfaces are fixed here, while exact vendors remain
replaceable implementation decisions.

------------------------------------------------------------------------

# 32. Hackathon build order

## Phase 0 --- Foundation

-   Flutter project boots.
-   Supabase local project initialized.
-   environment configuration established.
-   migrations run locally.
-   CI/lint/test baseline.
-   repository structure created.

## Phase 1 --- Domain + database

Build: - crop configs; - Harvest Case; - constraints; - destinations; -
observations; - recommendation runs; - scenario results; -
recommendation snapshots; - alerts; - RLS.

Seed one excellent tomato demo case and supporting context.

## Phase 2 --- Pure Value Engine

Before live APIs: - decay model; - transport/storage cost; - baseline; -
scenario generator; - feasibility; - ranking; - split allocator; -
uncertainty; - unit/golden tests.

At the end of this phase the engine should run entirely against
fixtures.

## Phase 3 --- Evaluation function

Implement `evaluate-harvest-case`.

Use seed providers first.

Prove:

``` text
Harvest Case → Context Snapshot → scenarios → recommendation
```

end-to-end.

## Phase 4 --- Flutter core experience

Build: - register; - confirm; - evaluating; - recommendation card; -
why; - alternatives; - active case.

Do not build dashboards first.

## Phase 5 --- Live provider adapters

Replace one seed adapter at a time with verified live providers.

Keep fallback.

## Phase 6 --- Monitoring

Implement: - active-case selector; - recompute; - material-change
diff; - alert persistence; - in-app update.

Add demo simulation controls.

## Phase 7 --- Language/voice

Add: - localization; - TTS; - optional STT; - extraction + confirmation.

## Phase 8 --- Stretch

Only after the core is stable: - photo assistance; - FPO dashboard; -
SMS/IVR; - more crops; - push notifications.

------------------------------------------------------------------------

# 33. What NOT to build first

Do not start with: - a huge analytics dashboard; - nationwide crop
coverage; - custom ML training; - complex microservices; - Kubernetes; -
a vector database; - RAG; - a chatbot as the core experience; - a
perfect authentication flow; - an LP/MIP solver before the simple
allocator works; - elaborate event infrastructure; - dozens of Edge
Functions.

None of these proves the core product.

The hackathon proof is:

> **Given a farmer's real constraints and a defensible external context,
> can Harvest Twin compute a better-supported feasible option, explain
> why, compare it with the farmer's plan, and react when the world
> changes?**

------------------------------------------------------------------------

# 34. Architecture Decision Records

When a major choice changes, add an ADR.

Example:

``` text
docs/decisions/
  ADR-001-supabase-backend.md
  ADR-002-deterministic-value-engine.md
  ADR-003-provider-adapter-fallback.md
  ADR-004-context-snapshots.md
```

Each ADR: - context; - decision; - alternatives considered; -
consequences; - date/status.

This prevents future agents from repeatedly reopening settled decisions
without understanding why they were made.

------------------------------------------------------------------------

# 35. Agent handoff protocol

At the end of every substantial implementation session, update a small
section in the root README or `docs/STATUS.md`:

``` text
CURRENT STATE
- What works
- What is partially implemented
- What is not started

LAST VERIFIED
- flutter analyze
- flutter test
- supabase db reset
- supabase test db
- edge-function tests

NEXT TASK
- one concrete next implementation objective

KNOWN ISSUES
- concise list

DO NOT CHANGE
- current invariants/decisions relevant to the next task
```

This architecture document should remain stable; day-to-day status
should not clutter it.

------------------------------------------------------------------------

# 36. Rules for coding agents

An AI coding agent working on Harvest Twin must:

1.  Read this document before changing architecture.
2.  Preserve farmer-first product invariants.
3.  Inspect existing migrations before creating new schema.
4.  Never rewrite already-deployed migrations merely for convenience.
5.  Put secrets server-side.
6.  Keep Value Engine logic independent from UI.
7.  Keep provider-specific code outside the Value Engine.
8.  Never introduce an LLM into numerical recommendation ranking without
    an explicit architecture decision.
9.  Add tests for every material engine behavior.
10. Record data provenance.
11. Preserve the baseline comparison.
12. Preserve uncertainty language.
13. Avoid unnecessary packages/services.
14. Prefer a small coherent implementation over speculative abstraction.
15. Never fabricate external agricultural data in production paths.
16. Mark demo/seed data explicitly.
17. Keep the recommendation reproducible from its stored context
    snapshot.
18. Use migrations for database changes.
19. Keep RLS and authorization intact.
20. Run the full relevant verification suite before declaring a task
    complete.

------------------------------------------------------------------------

# 37. Definition of done for the hackathon core

The technical core is ready when this exact story works:

1.  A farmer registers a harvest.
2.  The app shows the structured interpretation and the farmer confirms
    it.
3.  The backend creates a Harvest Case.
4.  The backend obtains a normalized context snapshot.
5.  The engine creates several feasible scenarios.
6.  The farmer's current plan is evaluated as the baseline.
7.  The engine computes and ranks scenarios.
8.  One recommendation is shown as WHAT / WHERE / WHY / VALUE
    DIFFERENCE.
9.  The farmer can inspect 2--3 alternatives.
10. The UI clearly labels estimates and basis.
11. A simulated or real weather/price change is introduced.
12. The same engine recomputes the active case.
13. If the material-change rule is crossed, an alert is created.
14. The updated recommendation appears.
15. The farmer remains free to ignore it.

If this works reliably, Harvest Twin demonstrates its core innovation.

------------------------------------------------------------------------

# 38. Initial implementation assumptions

These choices are intentionally made so development can begin without
requiring the product owner to make low-level architecture decisions:

  Area                       Default
  -------------------------- --------------------------------------------
  Client                     Flutter
  Backend                    Supabase
  Database                   PostgreSQL
  Server compute             Supabase Edge Functions / TypeScript
  Core decision logic        Deterministic Value Engine
  LLM in numerical ranking   No
  App state                  Riverpod
  Navigation                 go_router
  User-facing architecture   Feature-first
  External data              Provider adapters
  Failure fallback           Live → cache → explicit seed/demo
  Monitoring                 Supabase Cron → protected Edge Function
  Recommendation history     Immutable snapshots/runs
  Security                   Auth + RLS + server-side secrets
  First crop                 Tomato
  More crops                 Config-driven
  Split routing              Greedy V1 allocator
  Uncertainty                Small seeded sensitivity/Monte Carlo layer
  Primary UI                 One recommendation, progressive disclosure
  Demo resilience            First-class requirement

These are defaults, not permanent dogma. Change them through explicit
architecture decisions when evidence justifies it.

------------------------------------------------------------------------

# 39. Important open decisions

These should **not block the first implementation**:

-   exact market-price provider/API;
-   exact weather provider;
-   exact routing/distance provider;
-   exact storage dataset/provider;
-   exact STT/TTS vendors;
-   production farmer authentication method;
-   final supported language list;
-   push notification provider;
-   exact crop calibration parameters;
-   whether FPO dashboard ships;
-   whether SMS/IVR ships;
-   whether a future optimization solver replaces greedy allocation.

The architecture deliberately isolates these choices.

------------------------------------------------------------------------

# 40. Source-to-architecture mapping

The non-technical source establishes these product requirements:

-   farmer expertise is trusted input;
-   external visibility is the system advantage;
-   the product compares sell/wait/store/route/split scenarios;
-   the recommendation is compared with the farmer's current/usual plan;
-   the primary result is WHAT / WHERE / WHY / VALUE DIFFERENCE;
-   native-language text and voice are core accessibility features;
-   active cases are monitored;
-   alerts should be actionable rather than noisy;
-   assumptions and uncertainty should be visible;
-   the product must not promise guaranteed outcomes;
-   narrow credible coverage is preferred over unsupported breadth.

The merged/upgraded solution additionally proposes:

-   a unified Value Engine;
-   temperature-aware decay;
-   config-driven crops;
-   split-routing allocation;
-   uncertainty ranges;
-   offline seed fallbacks;
-   response-time tracking;
-   a secondary FPO/analyst view;
-   a demoable event-driven monitor.

This technical architecture operationalizes those ideas while
deliberately leaving external vendor selection replaceable.

------------------------------------------------------------------------

# 41. Current Supabase-specific implementation guidance

As of the architecture drafting date, Supabase supports the primitives
this design depends on:

-   Flutter client integration through `supabase_flutter`;
-   Postgres with Row Level Security;
-   TypeScript Edge Functions;
-   Cron jobs backed by `pg_cron`;
-   scheduled invocation of Edge Functions;
-   server-side secrets and authenticated/service-to-service function
    patterns.

Implementation rule:

> Use Supabase as the platform, but keep the **Harvest Twin domain model
> and Value Engine portable**. Supabase should host the system, not
> become the domain model.

This gives the project hackathon speed without coupling the mathematical
core to Flutter widgets or vendor-specific API responses.

------------------------------------------------------------------------

# 42. Final architecture summary

``` text
FARMER
  │
  │ form / speech / optional camera
  ▼
FLUTTER
  │
  │ confirmed structured input
  ▼
HARVEST CASE (Supabase/Postgres)
  │
  ▼
CONTEXT ORCHESTRATOR (Edge Function)
  ├── market
  ├── weather
  ├── route
  ├── storage
  └── buyer
  │
  ▼
IMMUTABLE CONTEXT SNAPSHOT
  │
  ▼
DETERMINISTIC VALUE ENGINE
  ├── crop decay
  ├── scenario generation
  ├── feasibility
  ├── transport/storage economics
  ├── split allocation
  ├── uncertainty
  └── baseline comparison
  │
  ▼
CANONICAL RECOMMENDATION
  │
  ├── primary option
  ├── alternatives
  ├── reasons
  ├── assumptions
  ├── data basis
  └── value difference
  │
  ▼
LOCALIZED FARMER EXPERIENCE
  │
  ├── WHAT
  ├── WHERE
  ├── WHY
  └── VALUE DIFFERENCE
  │
  ▼
ACTIVE CASE MONITOR
  │
  └── recompute → material-change check → alert only if actionable
```

**North star:** turn external complexity into one farmer-understandable
action that may preserve more of the harvest's value.

------------------------------------------------------------------------

## Appendix A --- Recommended first vertical slice

Do not implement the architecture horizontally.

Implement one complete vertical slice:

``` text
Tomato
800 kg
Already harvested
Must sell today
Current plan = Market A
Two alternative destinations
Seeded current prices
Seeded route costs
Seeded weather
↓
Three feasible scenarios
↓
Baseline + recommendation
↓
Recommendation card
↓
Simulated heat/rain or price change
↓
Recompute
↓
Actionable alert
```

Once that is fully tested, replace seed providers and add crop configs
one at a time.

------------------------------------------------------------------------

## Appendix B --- Minimal canonical errors

``` text
UNAUTHENTICATED
FORBIDDEN
CASE_NOT_FOUND
CASE_NOT_EVALUABLE
INVALID_CASE
CROP_CONFIG_MISSING
INSUFFICIENT_CONTEXT
NO_FEASIBLE_SCENARIOS
PROVIDER_TIMEOUT
PROVIDER_UNAVAILABLE
ENGINE_FAILURE
PERSISTENCE_FAILURE
```

Return safe user-facing messages separately from diagnostic logs.

------------------------------------------------------------------------

## Appendix C --- Recommended verification command set

Adapt to the repository as it evolves:

``` bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test

supabase start
supabase db reset
supabase test db

# Run Edge Function/domain tests using the project's chosen Deno test command.
# Then verify migrations and generated types are in sync.
git diff --check
```

Never claim a verification passed unless it was actually executed
successfully.

------------------------------------------------------------------------

**End of technical source of truth.**
