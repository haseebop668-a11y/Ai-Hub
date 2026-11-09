# Grade 9 Offline Learning — Study Discipline Requirements

Status: Approved product requirements  
Target branch: `feat/grade9-offline-learning-app`  
Runtime policy: Fully offline; network may be used only for development/build/update delivery.

## 1. Approved schedule settings

The following are the canonical initial settings. They must be persisted locally and used by the planner, reminders, dashboard, streaks, and reports.

```json
{
  "scheduleMode": "fixed",
  "weeklyRestDay": 7,
  "dailyStudyTargetMinutes": 300,
  "studyDaysPerWeek": 6,
  "timezoneMode": "device_local"
}
```

- `scheduleMode=fixed`: the learner follows a consistent daily start time and planned study windows. The exact start time is a required onboarding input and must not be silently invented. Until selected, the app may show the plan but must not claim that a fixed-time alarm is configured.
- `weeklyRestDay=7`: Sunday is a full rest day. It has no daily target, no missed-day penalty, and does not break a healthy streak.
- `dailyStudyTargetMinutes=300`: five hours of verified active learning per study day, Monday through Saturday.
- Device-local timezone is used for scheduling. Recompute future reminders after timezone or daylight-saving changes.

## 2. Five-hour learning plan

The planner should split 300 active minutes into six focused blocks of 50 minutes. Provide a configurable 5–15 minute break between blocks (default 10 minutes). Breaks, idle time, background time, and time spent merely viewing an open screen do not count toward the 300-minute target.

Suggested day:
- Block 1: 50 min — new concept
- Block 2: 50 min — guided examples and worked problems
- Block 3: 50 min — independent practice
- Block 4: 50 min — active recall and spaced review
- Block 5: 50 min — second subject / interleaved practice
- Block 6: 50 min — assessment, corrections, and teach-back

This is a planning template, not a rigid subject allocation. The autonomous planner selects topics from the learner's curriculum, diagnostic results, mastery, due reviews, and error history. It should adapt block content while preserving the daily active-time target.

## 3. Active-learning time accounting

Count time only while a learner is engaged in a supported learning activity:
- reading an assigned lesson with periodic interaction/checkpoints;
- answering a question, solving a problem, or completing a worked example;
- active recall, flashcards, oral teach-back, or language practice;
- completing an assessment and reviewing/correcting mistakes.

Pause or stop the active timer when:
- app is backgrounded or device is locked;
- learner is idle beyond a short configurable inactivity threshold;
- a break, pause, interruption, or app suspension is detected;
- content is left open without interaction.

Persist session start/end, activity type, duration, and completion state locally. Avoid collecting unnecessary personal data. Do not count overlapping timers twice. Restore sessions safely after process death/reboot.

## 4. Fixed-time reminders and alarm behavior

- User must choose a daily start time during onboarding/settings; allow later edits.
- Schedule reminders Monday–Saturday only; never schedule a study alarm on Sunday.
- Use Android-supported notification/alarm mechanisms, request exact-alarm/notification permissions only where required, and explain why.
- Re-register reminders after reboot, app update, permission changes, or timezone changes.
- If the target is incomplete, show a respectful reminder at configured intervals and a clear remaining-time indicator. Reminder escalation must be configurable and quiet hours must be respected.
- Android may defer or restrict alarms due to OS policies, battery optimization, or denied permissions. Display permission/optimization status and never promise guaranteed delivery.
- Do not bypass Android permissions, suppress system controls, or claim the app can force itself to run.

## 5. Focus mode and safety boundaries

- Provide an opt-in in-app Focus Mode that keeps the learner in the study flow, reduces in-app distractions, and can show a reminder when the learner leaves.
- Provide an optional parent/guardian PIN to exit or change discipline settings, while always retaining an emergency/accessible exit.
- Never lock the entire phone, block emergency calls, intercept other apps, hide system UI, or use device-admin/device-owner privileges as a default.
- Do not punish missed targets with data loss, public shaming, or irreversible streak resets. Support illness, family needs, and manual pause.

## 6. Weekly rest and progress

- Sunday is marked as Rest Day in calendar, dashboard, and reports.
- Sunday does not generate missed-study notifications, missed-target records, or streak penalties.
- Weekly report summarizes six planned study days, active minutes, topics mastered, review completion, and areas needing attention.
- A study streak advances on a completed scheduled study day; Sunday is neutral and does not interrupt it.
- If the learner studies voluntarily on Sunday, record it as optional bonus study, not a required target.

## 7. Learning quality and fatigue safeguards

A five-hour target is substantial. The app must encourage breaks, hydration, posture changes, and sleep; it must not encourage uninterrupted screen exposure. Offer an adjustable target and a gentle fatigue check-in without changing the approved 300-minute default automatically. If the learner reports fatigue or distress, suggest pausing and resuming later rather than pushing reminders.

## 8. Autonomous curriculum planner

The planner should automatically select the next activity using:
1. curriculum profile and chapter sequence;
2. initial diagnostic and current mastery;
3. spaced-repetition due items (SM-2 or validated equivalent);
4. recent mistakes and low-confidence answers;
5. prerequisites and interleaving opportunities;
6. remaining active minutes for the day.

Use short learning chunks, simple Urdu explanations with English subject terminology, worked examples, retrieval practice, hints before answers, Feynman-style teach-back, and mastery checks. Do not advance a learner solely because a timer expired.

## 9. Acceptance criteria

- Fresh install defaults to fixed mode, Sunday rest day, and 300 active minutes.
- The app clearly asks for a fixed daily start time before enabling the daily alarm.
- Monday–Saturday planner totals exactly 300 active minutes; break time is excluded.
- Sunday is visibly a rest day and never creates a missed-target penalty.
- Background/idle time does not increase the active-minute total.
- Duplicate sessions and timer overlap cannot inflate totals.
- Progress survives app restart and device reboot.
- Reminder scheduling responds correctly to permission denial, reboot, timezone change, and app update.
- Focus Mode is opt-in and cannot block emergency/system access.
- Unit tests cover schedule generation, Sunday exclusion, timer accounting, streak rules, and reminder rescheduling.
- Integration/UI tests cover onboarding, changing the start time, pausing/resuming sessions, and weekly reports.
- All core scheduling, planning, learning, progress, and reminder logic works without internet.

## 10. Out of scope / explicit non-goals

- No whole-device lock or coercive device-management behavior.
- No cloud account requirement, analytics upload, or runtime internet dependency.
- No claim that alarms are guaranteed when Android permissions are denied or the OS suppresses delivery.
- No automatic claim of official textbook status; each curriculum/content pack must carry source, edition, academic year, and verification/licensing status.
