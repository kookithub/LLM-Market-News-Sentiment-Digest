# automation/

Everything that runs **outside** the Vue app to produce digests. The app never calls these tools; it
only reads the `news_digests` rows they write.

| Path | What belongs here |
|---|---|
| `contracts/` | The two data contracts every tool must honour. `ai-output.schema.json` (what any AI model returns) and `digest-record.schema.json` (what any automation writes to `news_digests`), each with an example. **Change a contract only together with `supabase/schema.sql`, the services and a CHANGELOG entry.** |
| `prompts/` | The exact AI prompt text, one file per version (`digest.v1.md`, `digest.v2.md`, …). Never edit a version in place; add a new file and bump `prompt_version` in Make step 4. |
| `make/` | `MAKE_SETUP.md` (build guide for the one Make.com scenario) and `scenario-blueprint.json` (exported scenario, secrets removed). |

Swapping any tool here (AI, news source, Make itself): see [`../docs/SWAPPING_TOOLS.md`](../docs/SWAPPING_TOOLS.md).
