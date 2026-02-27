# Minutes of Meeting

## Meeting Details

| Field | Value |
|-------|-------|
| **Meeting** | Sprint 14 Planning — Notification Center |
| **Date** | February 25, 2026 — 10:00 AM (60 min) |
| **Duration** | 55 minutes |
| **Organizer** | Demo PM |
| **Attendees** | Demo PM, Sarah Chen (Eng Lead), Marcus Rivera (Design), Priya Patel (QA Lead), Alex Kim (Platform), Jordan Lee (Mobile) |
| **Absent** | Chris Wong (Backend — on PTO, async update sent) |
| **Location** | Teams — Sprint Planning Channel |

---

## Agenda & Discussion

### 1. Sprint 13 Retrospective (5 min)
**Presenter:** Sarah Chen

Sprint 13 closed with 18/21 story points completed (86% velocity). The notification service API v1 integration was completed ahead of schedule. Two items carried over: the DND scheduling UI and the preference persistence layer. Team morale is high after shipping the notification feed MVP to internal dogfood.

> 💡 **Key Insight:** Dogfood users reported that the feed "felt fast" — p95 load time was 120ms, well under the 200ms target.

### 2. Sprint 14 Scope Review (20 min)
**Presenter:** Demo PM

Reviewed 12 candidate stories for Sprint 14. After estimation, the team committed to 24 story points across 8 stories. Key items:

- **Priority filtering UI** (5 pts) — Marcus has Figma mocks ready, will use existing FilterBar component
- **DND scheduling backend** (8 pts) — Alex to build the scheduling service; discussed cron vs. calendar-based approaches
- **Daily digest email template** (3 pts) — Reuse existing email framework; Priya flagged need for RTL language testing
- **Cross-device sync** (5 pts) — Jordan working on WebSocket approach; fallback to polling if latency > 5s
- **Accessibility audit prep** (3 pts) — Marcus to run axe-core scan and document gaps before external audit

> 💡 **Key Insight:** Team agreed to use calendar-based DND scheduling (not cron) because users think in "meeting blocks" not "time expressions."

### 3. API v2 Migration Risk (15 min)
**Presenter:** Alex Kim

Platform team confirmed API v2 will be in public preview by March 15. Current v1 integration works but lacks batch-dismiss and priority-classification endpoints. Alex proposed a clean adapter pattern: build against v1 now, swap to v2 behind the adapter when ready. No code changes needed in the UI layer.

> ⚠️ **Risk:** If v2 preview slips past March 30, we'll need to build batch-dismiss on v1 (estimated +3 pts).

### 4. Design Review: DND & Digest (10 min)
**Presenter:** Marcus Rivera

Walked through three DND UI options:
- **Option A:** Toggle + time picker (simplest, but lacks recurring schedules)
- **Option B:** Calendar overlay with drag-to-select blocks (most intuitive, +2 pts)
- **Option C:** Preset buttons (Focus 2h / Meeting 1h / Custom) with one-tap activation

Team voted for **Option C** with a "Custom" expansion that opens a time picker. Ships faster than Option B, covers 90% of use cases.

> 💡 **Pro Tip from Marcus:** "Don't build a scheduling UI when presets solve 90% of the problem. We can always add the full calendar later."

### 5. QA Strategy (5 min)
**Presenter:** Priya Patel

QA will run automated regression on existing notification feed plus manual testing for new features. Priya requested a staging environment with >1000 notifications seeded for performance testing. Alex confirmed staging can be seeded by March 3.

---

## Decisions

| # | Decision | Made By | Rationale |
|---|----------|---------|-----------|
| 1 | Use calendar-based DND scheduling (not cron) | Team consensus | Users think in meeting blocks, not time expressions |
| 2 | DND UI: Option C (presets + custom) | Marcus + Team vote | Ships faster, covers 90% of use cases |
| 3 | API v2 adapter pattern for migration | Alex | Zero UI code changes when v2 lands |
| 4 | RTL language testing included in Sprint 14 QA | Priya | 18% of user base uses RTL languages |

## Action Items

| # | Action | Owner | Deadline | Priority | Status |
|---|--------|-------|----------|----------|--------|
| 1 | Finalize Figma mocks for DND presets UI | Marcus Rivera | Feb 28 | 🔴 High | ⬜ Open |
| 2 | Build DND scheduling service (calendar-based) | Alex Kim | Mar 7 | 🔴 High | ⬜ Open |
| 3 | Seed staging environment with 1000+ notifications | Alex Kim | Mar 3 | 🟡 Medium | ⬜ Open |
| 4 | Set up RTL language test matrix | Priya Patel | Mar 3 | 🟡 Medium | ⬜ Open |
| 5 | Send async Sprint 14 scope summary to Chris Wong | Demo PM | Feb 26 | 🟢 Low | ⬜ Open |
| 6 | Draft v2 migration contingency plan (if preview slips) | Alex Kim | Mar 10 | 🟡 Medium | ⬜ Open |
| 7 | Schedule accessibility audit with external vendor | Demo PM | Mar 5 | 🟡 Medium | ⬜ Open |

## Parking Lot
- [ ] AI-powered notification summarization — revisit in Q3 planning
- [ ] Custom notification sounds — low demand, defer to v2
- [ ] Third-party source integration (Slack/Discord) — needs separate PRD and partner evaluation

## Next Meeting
- **Date:** March 4, 2026 — 10:00 AM
- **Agenda Preview:** Sprint 14 standup, DND design sign-off, staging environment demo

---
*Generated by Brain OS `/mom` — reviewed and approved for distribution*
