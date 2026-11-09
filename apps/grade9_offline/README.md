# Grade 9 AI Tutor — offline-first Android app

This app is being redesigned from a flashcard utility into an **adaptive tutor**.
The learner should press one primary action — **Start today's study session** —
and the app chooses the next lesson, review queue, recall exercise and mini-test.

## Product behaviour

1. **Automatic study selection:** deterministic planner prioritizes overdue recall,
   low-mastery units, never-studied lessons and curriculum sequence. No daily
   subject/chapter picker is required.
2. **Teach → close book → recall → feedback → retest:** each lesson is taught in
   small steps, then the learner explains it in their own words, answers targeted
   questions, sees corrections and retries weak points.
3. **Spaced repetition:** recall results update per-unit mastery and due dates.
4. **Progress-aware sessions:** a short daily goal is filled with review + one
   focused lesson + closed-book recall + a mini-test.
5. **Local-first privacy:** learner profile, source files, extracted text, answers
   and progress stay on-device. Any optional online model call must be explicitly
   enabled and must disclose what is sent.

## Content pipeline (next implementation milestone)

- Use official PECTAA sources as the Punjab curriculum catalogue. Detect edition
  and academic year; never silently combine the 2020, 2025-26 and 2026-27 books.
- Keep Federal/NCC content as a separate curriculum profile.
- Import/download only from a curated, source-verified catalogue. A web search
  result is not proof of permission to redistribute a textbook PDF.
- Extract selectable PDF text locally; identify chapter headings and page ranges;
  OCR scanned pages locally only where an Urdu-capable model is available.
- Store source title, publisher, board, edition, year, page references and content
  hash with every extracted lesson.
- Generate explanations and questions from retrieved source passages, with page
  citations. Reject questions that cannot be traced to source material.
- User-owned PDFs can be imported locally. The tutor should not require the user
  to manually create flashcards or select chapters.

## Model strategy

The planner, mastery scoring, review scheduling and question templates are
deterministic and work offline. The LLM is an optional teaching assistant, not
the authority for curriculum facts. Do not bundle a large model inside the APK:
download a separately licensed, quantized model after install, with a clear
storage estimate, checksum, pause/resume and delete controls. The target device
is Snapdragon 865 with 8 GB RAM, so benchmark 0.5B–1B quantized models before
choosing a default. The model must be checked for education-use restrictions and
Urdu/English quality; model size or Apache licensing alone is not sufficient.
If local inference is too slow, use authored lesson templates offline rather than
making an API mandatory. Hugging Face hosted inference can only be an opt-in
online enhancement; free quotas and availability are not guaranteed.

## Current status

- Flutter dashboard, SQLite persistence, flashcards and SM-2 review exist.
- Adaptive planner core is being added with tests.
- PDF ingestion, curated official content catalogue, full lesson/assessment
  experience, model runtime and physical-device benchmarking are not complete.
- Do not describe this build as a finished AI tutor or claim 100% offline
  textbook coverage until those milestones pass.
