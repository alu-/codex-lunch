---
name: lunch-planner
description: Fetch, extract, and summarize restaurant lunch menus from websites or provided HTML/text. Use when Codex needs to answer questions such as "what's for lunch today", compare today's lunch options across multiple restaurants, pull prices or allergens from menu pages, or turn noisy lunch webpage content into a concise daily summary.
---

# Lunch Planner

## Overview

Find current lunch information in the local prepared inputs, verify that it is for the correct date, and reduce raw restaurant page content into a compact answer that highlights actual dishes instead of site chrome.

Paths in this skill are relative to the skill directory, not the repository root. For example, `references/restaurants.md` resolves to `.codex/skills/lunch-planner/references/restaurants.md`.

Use `references/restaurants.md` as the default restaurant list unless the user explicitly adds, removes, or overrides sources for the current task.

This skill assumes a shell script has already fetched each restaurant page and run the extractor. The skill should only read those local files and produce the final summary. It should not fetch webpages itself and it should not run the extraction helper itself.

## Workflow

1. Load `references/restaurants.md` from the skill directory and treat those restaurants as the user's standing lunch sources.
2. Read the local manifest prepared by the shell script when it is available, for example `tmp/lunch-planner/manifest.md`, and use it to find the local HTML and extracted text files for each restaurant.
3. Confirm the menu date explicitly from the visible menu content in the extracted text. Use absolute dates in the answer.
4. Use the prepared extracted plain text as the primary model input, even if the matching HTML is also available.
5. Read the local HTML only when the extracted text is ambiguous and you need to double-check that the extracted text preserved the visible menu correctly.
6. Summarize only dishes that are actually available for the requested date.
7. Include prices, vegetarian options, allergens, or lunch hours only when the source provides them.
8. Do not append a separate source summary section at the end. Put the source URL directly in each restaurant heading, for example `Restaurant Name (https://example.com/menu)`.
9. Write the final answer in Swedish, even if some source pages or dish labels are in English.
10. Order restaurants with a confirmed menu for the requested day first. Put restaurants with a fixed menu, a non-day-specific menu, or an unverified menu later in the list.
11. If a source does not contain any menu for the current week, mention that directly from the local files instead of guessing.
12. End the response immediately after the lunch menu. Do not add follow-up questions, offers to refine the result, or any extra commentary before or after the menu.

## Extraction Rules

- Prefer official restaurant pages over aggregators.
- Ignore metadata timestamps such as `dateModified`, SEO fields, JSON-LD dates, and similar page metadata when judging whether a menu is current. Base freshness on the visible menu content only.
- Treat "today", "tomorrow", and weekday labels as date-sensitive. Resolve them against the current date before summarizing.
- If the visible menu contains explicit day-and-month labels such as `Tisdag 17 mars`, treat those visible labels as authoritative for date verification.
- Do not invent or substitute a missing month or day from unrelated visible numbers such as copyright years, opening hours, phone numbers, prices, or other page furniture.
- Do not say that the page "shows" a specific full date unless that full date, or an unambiguous weekday plus day-and-month equivalent, is actually present in the visible menu text.
- Ignore page furniture such as navigation, cookie banners, booking widgets, and repeated footer text. The prepared extracted text should already remove most of this noise.
- Keep dish names close to their neighboring prices or labels when extracting.
- If the page lists a whole week, return only the requested day unless the user asks for a weekly comparison.
- If the source is ambiguous or stale, say so directly instead of guessing.

## Source-Specific Notes

- VW Lunchverkstan shows the current week's menu without explicit dates. Treat its visible weekly menu as current for the present week, but note that the source does not print calendar dates.
- Pho 88 has a fixed menu that stays the same. Treat it as a non-day-specific fixed menu rather than trying to verify a current week or date from the page.

## Local Inputs

The expected default input layout is:

```bash
tmp/lunch-planner/manifest.md
tmp/lunch-planner/restaurant-name.html
tmp/lunch-planner/restaurant-name.txt
```

The manifest should map each restaurant name and URL to its local HTML and extracted text files.
Prefer the extracted text files as the main input.
Do not fetch webpages from inside the skill when these local files are present.

## Preprocessing Boundary

Fetching and extraction are preprocessing steps owned by the shell script, not by this skill.
This skill should consume the prepared files and produce the compiled lunch summary.

## Output Shape

- Start with the requested date and area if known.
- Write the final answer in Swedish.
- Group results by restaurant, and include the menu URL in the restaurant heading.
- Put restaurants with a confirmed menu for the requested day first, and move fixed or non-day-specific menus later in the list.
- For each restaurant, list the dishes in plain language.
- Add one short note for price, dietary tags, or uncertainty when relevant.
- Do not end with a source summary section.
- Do not add any closing sentence, call to action, or follow-up question after the final restaurant entry.

See `references/output-format.md` in the skill directory for a compact response template and date-handling checklist.
See `references/restaurants.md` in the skill directory for the persistent restaurant list.
