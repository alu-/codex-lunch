---
name: lunch-planner
description: Fetch, extract, and summarize restaurant lunch menus from websites or provided HTML/text. Use when Codex needs to answer questions such as "what's for lunch today", compare today's lunch options across multiple restaurants, pull prices or allergens from menu pages, or turn noisy lunch webpage content into a concise daily summary.
---

# Lunch Planner

## Overview

Find current lunch information, verify that it is for the correct date, and reduce raw restaurant page content into a compact answer that highlights actual dishes instead of site chrome.

Paths in this skill are relative to the skill directory, not the repository root. For example, `references/restaurants.md` resolves to `.codex/skills/lunch-planner/references/restaurants.md`.

Use `references/restaurants.md` as the default restaurant list unless the user explicitly adds, removes, or overrides sources for the current task.

## Workflow

1. Load `references/restaurants.md` from the skill directory and treat those restaurants as the user's standing lunch sources.
2. Fetch the live page content when the request is about today's or this week's lunch. Use a Chrome-like HTTP user agent by default when making web requests.
3. Confirm the menu date explicitly from the visible menu content. Use absolute dates in the answer.
4. Save fetched webpage content and always run `scripts/extract_menu_text.py` from the skill directory on it before interpreting the menu. Use the cleaned plain text as the model input, even if the page looks simple.
5. Summarize only dishes that are actually available for the requested date.
6. Include prices, vegetarian options, allergens, or lunch hours only when the source provides them.
7. Do not append a separate source summary section at the end. Put the source URL directly in each restaurant heading, for example `Restaurant Name (https://example.com/menu)`.
8. Write the final answer in Swedish, even if some source pages or dish labels are in English.
9. Order restaurants with a confirmed menu for the requested day first. Put restaurants with a fixed menu, a non-day-specific menu, or an unverified menu later in the list.
10. If a source does not contain any menu for the current week, save both the fetched HTML and the extracted plain text under a repo-level `debug/` directory for inspection.
11. End the response immediately after the lunch menu. Do not add follow-up questions, offers to refine the result, or any extra commentary before or after the menu.

## Extraction Rules

- Prefer official restaurant pages over aggregators.
- When fetching pages directly, send a Chrome-like user agent to reduce simplistic bot blocking.
- Ignore metadata timestamps such as `dateModified`, SEO fields, JSON-LD dates, and similar page metadata when judging whether a menu is current. Base freshness on the visible menu content only.
- Treat "today", "tomorrow", and weekday labels as date-sensitive. Resolve them against the current date before summarizing.
- Ignore page furniture such as navigation, cookie banners, booking widgets, and repeated footer text. Rely on `scripts/extract_menu_text.py` from the skill directory to remove this before summarizing.
- Keep dish names close to their neighboring prices or labels when extracting.
- If the page lists a whole week, return only the requested day unless the user asks for a weekly comparison.
- If the source is ambiguous or stale, say so directly instead of guessing.

## Source-Specific Notes

- VW Lunchverkstan shows the current week's menu without explicit dates. Treat its visible weekly menu as current for the present week, but note that the source does not print calendar dates.
- Pho 88 has a fixed menu that stays the same. Treat it as a non-day-specific fixed menu rather than trying to verify a current week or date from the page.

## Downloading inputs

When the user asks for a lunch source, download it with:

```bash
curl -L "https://example.com/" -o tmp/source.html
```

Save downloads under tmp/ unless the user requested another location.
If the file already exists, overwrite it.
After downloading, inspect the file before using it.
If a source does not contain any menu for the current week, also copy the fetched HTML into a repo-level `debug/` directory using a restaurant-specific filename.

## Using The Helper Script

Run the helper on every saved webpage or provided HTML/text before interpreting the menu:

```bash
python3 .codex/skills/lunch-planner/scripts/extract_menu_text.py page.html
python3 .codex/skills/lunch-planner/scripts/extract_menu_text.py restaurant-a.html restaurant-b.html
```

The script removes HTML, CSS, JavaScript, SVG, and template content, then prints cleaned plain text. Always use that cleaned text as model input instead of relying on raw webpage content or brittle rule-based menu extraction.
If a source does not contain any menu for the current week, save the extracted plain text into the repo-level `debug/` directory next to the saved HTML.

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
