# Siyaq (سياق) - Product Requirements Document (PRD)

## Project Overview
**Siyaq (سياq)** is a smart Islamic daily schedule management web and mobile application designed to harmonize user tasks, daily routines, and sleep schedules around dynamic prayer times.

---

## Key Features & Functional Requirements

### 1. Navigation & Liquid Glass Theme Mode
- **Tab Navigation**: Seamless switching between Dashboard (الرئيسية), Calendar (التقويم), AI Assistant (المساعد), and Settings (الإعدادات).
- **Theme Toggle**: Real-time switching between Light Mode, Dark Mode, and System Theme with frosted liquid glass visual blur (BackdropFilter).
- **Avatar Profile**: Avatar picker offering 5 customizable avatar images persisted in local storage.

### 2. Daily Dashboard & Adaptive Timeline
- **Dynamic Prayer Integration**: Fetches local prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) and renders them as distinct prayer blocks.
- **Schedule Adjuster**: Automatically shifts or pauses user tasks when overlapping with prayer times based on user preferences.
- **Free Time Slots**: Automatically calculates and displays available free time blocks. Tapping a free time slot opens the task addition sheet pre-filled with the selected slot's start and end times.
- **Task Actions**: Delete tasks directly from the timeline view.

### 3. Calendar & Task Management
- **Date Picker**: Multi-year date picker supporting Arabic and English localizations and Eastern/Western Arabic numerals.
- **Task Addition Sheet**:
  - Task title and optional description inputs.
  - Time range selector (Start Time and End Time).
  - Task types: Single Date (مؤقتة), Weekly Routine (روتين أسبوعي), Ramadan Schedule (خاص برمضان), Special Day (يوم مميز).
  - Sleep mode toggle (وقت النوم) with custom muted notification handling.
  - Prayer reaction options: Full shift (إزاحة), Pause/Split (إيقاف مؤقت), Cancel segment (إلغاء المتعارض).
- **Conflict Resolution Dialog**: Detects overlapping tasks and prompts the user to either trim/cut overlapping durations or replace/delete conflicting tasks.

### 4. Custom Prayer Times & App Settings
- **Prayer Timing Offsets**: Individual sliders for each prayer to adjust start offsets from -20 to +20 minutes.
- **Prayer Duration**: Individual sliders for each prayer to set worship duration from 10 to 60 minutes.
- **Arabic Prayer Labels**: Clear Arabic names for all 5 prayers (صلاة الفجر, صلاة الظهر, صلاة العصر, صلاة المغرب, صلاة العشاء).
- **AI Key Configuration (BYOK)**: Input fields for user's Google Gemini API Key and OpenAI API Key.
- **Reset Settings**: One-click action to restore default prayer configurations, theme modes, and clear stored credentials.

### 5. Weekly Schedule & Template Managers
- **Weekly Routine Manager**: Create and manage recurring tasks for Monday through Sunday.
- **Templates & Ramadan Mode**: Copy weekday routines to special dates or enable automated Ramadan mode templates.

---

## User Flows to Audit
1. **Onboarding & Navigation**: Launch app -> switch theme mode -> navigate through all 4 tabs -> change profile avatar.
2. **Dashboard Timeline Interaction**: View timeline -> scroll -> tap a free time slot -> observe pre-filled task creation sheet.
3. **Task Creation & Conflict Handling**: Add single task -> attempt to add overlapping task -> trigger conflict dialog -> select Trim or Delete -> verify schedule updates.
4. **Prayer Customization**: Navigate to Settings -> adjust Fajr offset to +10m -> adjust Isha duration to 30m -> verify prayer blocks and timeline shift accordingly -> reset settings.
5. **Calendar & Date Selection**: Pick a future date -> view scheduled tasks -> add custom task -> verify task count and list update.
