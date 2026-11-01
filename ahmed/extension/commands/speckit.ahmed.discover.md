---
description: After the idea is clear (specify + clarify), study similar products online - their look and their features - show the owner up to 10 distinct visual styles to pick one as the design reference, and propose features the competitors have that the spec lacks.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty). It may name a feature directory, or
be the owner's answer to the style or feature question asked in the previous turn.

## Why this step exists

Owner rule 2026-11-01, every project, every time: once the idea is complete, look online for products with a
similar idea; show him several clearly different styles, up to 10, so he picks the look he likes as the
reference the design is built on; and while searching, study what those products **do**, not only how they
look, and propose to him the features we do not have. A whole-app design made before he picked a direction
was wasted («المفروض كنت تخليه يعمل الصفحة الرئيسسة و صفحة واحدة من جوا الاول بأكتر من شكل موديرن مختلف
تماما و ميكونش بنفس الاستايل الثابت بتاع ال ai»).

Talk to the owner in Egyptian Arabic with English technical terms in Latin script.

## Scope

- **Features** (part B) run for every feature.
- **Style** (part A) runs once per project, on the first feature with a user interface. Its result lives in
  `docs/design/direction.md` and every later feature reuses it. Run it again only when the owner asks, or
  when a feature adds a new surface (for example a web page in a phone app project).
- Features with no user interface and no product equivalent (a build script, a library): write
  `FEATURE_DIR/discovery.md` with the line `Not applicable: <reason>` and stop.

## Part A: style reference (up to 10 directions)

0. **Ask first, never assume** (owner 2026-11-01, asked after the fact twice): in one AskUserQuestion call, the
   UI language(s) and direction, and the theme: dark only, light only, or both. Every direction then follows
   the answer; when it is one theme, variety comes from layout, organisation and palette only.
   **Read the product's shape**: if the app is a container of many modules or sections (a super app, a
   toolbox), the home screen is a launcher that gives every module equal weight and still works with the
   full planned count (read the module list from the docs); never design home around the first feature.
1. **Search, never invent.** Use WebSearch (and WebFetch on the best results) for real products with a similar
   idea and for current visual directions: Dribbble, Behance, Mobbin, App Store / Play Store pages, and the
   products' own sites. Note each source URL.
2. **Pick 5 to 10 directions that are clearly different from each other** (for example editorial minimal,
   bento grid, neubrutalism, dark glass, soft clay, data-dense utilitarian, monochrome dot-matrix, warm
   biophilic). Two that differ only in colour count as one. At least one must be a real shipped product.
   Avoid the generic AI look (purple gradient, rounded cards, centred hero) unless he asked for it.
3. **Show each direction on the owner's own app**, not as a description: render the home screen and one
   inner screen (the screen central to the idea) in that direction, at true phone size, side by side, with
   the real reference image(s) or link beside them. Use the `choice-page` skill: one question, one option per
   direction, `html_height` measured, the explanation in `text`, your recommendation marked. Never one long
   page of many small frames.
4. **Record the pick** in `docs/design/direction.md`: chosen direction, its references (URLs and saved image
   paths under `docs/design/references/`), palette, type, shape and motion rules, and the owner's notes
   verbatim. From then on every design request (to ChatGPT or anyone) attaches this file and its reference
   images, and the rest of the screens are designed in that direction.

## Part B: features similar products have

1. From the same research, list the features the similar products offer, with the product name and source
   URL for each.
2. Keep only those the spec does **not** already cover (check `spec.md` FR list and clarifications), and
   drop anything against the constitution (cost, privacy, scope rules).
3. Present them with the `editable-checklist-doc` skill: one line each, what it does, which products have it,
   your recommendation (now / later / no) with a one-line reason. Nothing is added without his tick.
4. Write `FEATURE_DIR/discovery.md`: products studied (name, URL, one line), the proposed features, and the
   owner's decision per feature. Accepted features go into `spec.md` through `/speckit-specify` refinement
   or a short clarify session, and the spec's checklist is re-validated.

## Done when

- `docs/design/direction.md` exists and names the chosen direction (or the feature is marked not applicable
  for style), **and**
- `FEATURE_DIR/discovery.md` exists with an owner decision on every proposed feature, or the line
  `Not applicable: <reason>`.

## Rules

- Evidence before claims: every product, feature and style cites the URL it came from.
- Reference images are for the owner's private choice and as design input; never ship them in the app.
- Free sources only; no paid design libraries or accounts without the owner's approval.
