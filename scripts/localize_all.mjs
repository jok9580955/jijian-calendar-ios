import fs from "node:fs";
import path from "node:path";

const locales = [
  "ar-SA", "ca", "zh-Hans", "zh-Hant", "hr", "cs", "da", "nl-NL", "en-AU",
  "en-CA", "en-GB", "en-US", "fi", "fr-CA", "fr-FR", "de-DE", "el", "he",
  "hi", "hu", "id", "it", "ja", "ko", "ms", "no", "pl", "pt-BR", "pt-PT",
  "ro", "ru", "sk", "es-MX", "es-ES", "sv", "th", "tr", "uk", "vi"
];

const languageNames = {
  "ar-SA": "Arabic", ca: "Catalan", "zh-Hans": "Simplified Chinese",
  "zh-Hant": "Traditional Chinese", hr: "Croatian", cs: "Czech", da: "Danish",
  "nl-NL": "Dutch", "en-AU": "English", "en-CA": "English", "en-GB": "English",
  "en-US": "English", fi: "Finnish", "fr-CA": "French", "fr-FR": "French",
  "de-DE": "German", el: "Greek", he: "Hebrew", hi: "Hindi", hu: "Hungarian",
  id: "Indonesian", it: "Italian", ja: "Japanese", ko: "Korean", ms: "Malay",
  no: "Norwegian", pl: "Polish", "pt-BR": "Portuguese", "pt-PT": "Portuguese",
  ro: "Romanian", ru: "Russian", sk: "Slovak", "es-MX": "Spanish",
  "es-ES": "Spanish", sv: "Swedish", th: "Thai", tr: "Turkish", uk: "Ukrainian", vi: "Vietnamese"
};

const en = {
  appName: "极简日历-倒数日-日程提醒与桌面小组件",
  tagline: "Calendar, countdowns, reminders and widgets",
  metadataName: "极简日历-倒数日-日程提醒与桌面小组件",
  metadataSubtitle: "Calendar reminders countdowns",
  metadataKeywords: "calendar,countdown,reminder,schedule,birthday,anniversary,widget,holiday,planner",
  promo: "A clean calendar for schedules, birthdays, countdown days, reminders, holidays, iCloud sync and widgets.",
  description: "Plan the days that matter without ads, accounts or noisy tracking. 极简日历-倒数日-日程提醒与桌面小组件 combines a clean calendar, countdown days, birthday and anniversary reminders, holiday information, Apple Calendar import, ICS export, iCloud sync and practical widgets.",
  features: [
    "Month, week and day calendar views",
    "Schedules, plans, birthdays, anniversaries and countdown days",
    "Repeating events and reminder lead times",
    "Lunar calendar and solar-term display for Chinese markets",
    "Local holiday packs for global markets",
    "Custom date badges, colors and symbols",
    "Apple Calendar import and optional export",
    "ICS import/export for portability",
    "Private iCloud sync across your devices",
    "Home Screen and Lock Screen widgets"
  ],
  privacy: "One-time purchase. No ads. No account. No third-party analytics.",
  release: "Initial global release with calendar, countdowns, reminders, holiday data, iCloud sync and widgets."
};

const officialName = "极简日历-倒数日-日程提醒与桌面小组件";
const localizedAppNames = {
  "ar-SA": "تقويم وعد تنازلي",
  ca: "Calendari Minimal Compte",
  "zh-Hans": officialName,
  "zh-Hant": "極簡日曆-倒數日提醒小工具",
  hr: "Minimal Kalendar Odbrojavanje",
  cs: "Minimal Kalendář Odpočet",
  da: "Minimal Kalender Nedtælling",
  "nl-NL": "Minimal Kalender Aftellen",
  "en-AU": "Minimal Calendar Countdown",
  "en-CA": "Minimal Calendar Countdown",
  "en-GB": "Minimal Calendar Countdown",
  "en-US": "Minimal Calendar Countdown",
  fi: "Minimal Kalenteri Laskuri",
  "fr-CA": "Calendrier Minimal Compte",
  "fr-FR": "Calendrier Minimal Compte",
  "de-DE": "Minimal Kalender Countdown",
  el: "Μίνιμαλ Ημερολόγιο",
  he: "לוח שנה ספירה לאחור",
  hi: "मिनिमल कैलेंडर काउंटडाउन",
  hu: "Minimal Naptár Számláló",
  id: "Kalender Minimal Hitung Mundur",
  it: "Calendario Minimal Countdown",
  ja: "ミニマル日暦 カウントダウン",
  ko: "미니멀 캘린더 카운트다운",
  ms: "Kalendar Minimal Kiraan",
  no: "Minimal Kalender Nedtelling",
  pl: "Minimal Kalendarz Odliczanie",
  "pt-BR": "Calendário Minimal Contagem",
  "pt-PT": "Calendário Minimal Contagem",
  ro: "Calendar Minimal Numărătoare",
  ru: "Минимал Календарь Отсчет",
  sk: "Minimal Kalendár Odpočet",
  "es-MX": "Calendario Minimal Cuenta",
  "es-ES": "Calendario Minimal Cuenta",
  sv: "Minimal Kalender Nedräkning",
  th: "ปฏิทินมินิมอลนับถอยหลัง",
  tr: "Minimal Takvim Geri Sayım",
  uk: "Мінімал Календар Відлік",
  vi: "Lịch Tối Giản Đếm Ngày"
};

const packs = {
  "zh-Hans": {
    appName: "极简日历-倒数日-日程提醒与桌面小组件",
    metadataName: "极简日历-倒数日-日程提醒与桌面小组件",
    metadataSubtitle: "日程生日农历节假日提醒",
    metadataKeywords: "日历,倒数日,日程,提醒,生日,纪念日,小组件,农历,黄历,节假日,计划,桌面组件",
    promo: "清爽管理日程、生日、倒数日、提醒、节假日、iCloud 同步与桌面小组件。",
    description: "用极简日历-倒数日-日程提醒与桌面小组件记录重要日子，没有广告、没有账号、没有第三方分析。它把清爽日历、倒数日、生日和纪念日提醒、节假日信息、Apple 日历导入、ICS 导入导出、iCloud 同步和实用小组件放在一起。",
    features: ["月、周、日多视图", "日程、计划、生日、纪念日和倒数日", "重复事项和提前提醒", "农历、节气和中文市场节假日", "全球市场本地节假日", "自定义日期角标、颜色和图标", "导入 Apple 日历并可选择导出", "ICS 导入导出", "通过私人 iCloud 在设备间同步", "桌面和锁屏小组件"],
    privacy: "一次性付费。无广告。无账号。无第三方分析。",
    release: "首个全球版本，包含日历、倒数日、提醒、节假日、iCloud 同步和小组件。",
    ui: {
      "Add": "添加", "Settings": "设置", "Filter": "筛选", "All": "全部", "Delete": "删除",
      "Month": "月", "Week": "周", "Day": "日", "Schedule": "日程", "Plan": "计划",
      "Birthday": "生日", "Anniversary": "纪念日", "Countdown": "倒数日", "Countdowns": "倒数日",
      "Add badge": "添加角标", "Badge": "角标", "Icon": "图标", "Edit": "编辑", "Edit item": "编辑事项",
      "Export to Apple Calendar": "导出到 Apple 日历", "Calendar access denied": "日历权限被拒绝",
      "Exported to Apple Calendar": "已导出到 Apple 日历", "Export failed": "导出失败",
      "Themes": "主题", "Status": "状态", "OK": "好",
      "Calendar, countdowns, reminders and widgets": "日历、倒数日、提醒与小组件",
      "Search schedules, birthdays, countdowns": "搜索日程、生日和倒数日",
      "Today": "今天", "Today focus": "今日重点", "Selected day": "所选日期",
      "Nothing scheduled": "没有安排", "Add a plan, birthday, anniversary or countdown for this day.": "为这一天添加计划、生日、纪念日或倒数日。",
      "No countdowns yet": "还没有倒数日", "Track launches, exams, trips and anniversaries.": "记录发布、考试、旅行和纪念日。",
      "New item": "新建事项", "Details": "详情", "Title": "标题", "Notes": "备注", "Type": "类型",
      "Date": "日期", "All day": "全天", "Starts": "开始", "End date": "结束日期", "Ends": "结束",
      "Repeat": "重复", "Reminder": "提醒", "Style": "样式", "Pin countdown": "置顶倒数日",
      "Cancel": "取消", "Save": "保存", "Sync": "同步", "iCloud sync ready": "iCloud 同步已就绪",
      "Private CloudKit sync keeps your calendars available on your devices.": "私人 CloudKit 同步让你的日历在设备间保持可用。",
      "Import from Apple Calendar": "从 Apple 日历导入", "Calendar access: %@": "日历权限：%@",
      "Import and Export": "导入与导出", "Export ICS": "导出 ICS", "Paste ICS import": "粘贴 ICS 导入",
      "Privacy": "隐私", "No ads, no account, no third-party analytics": "无广告、无账号、无第三方分析",
      "One-time purchase": "一次性付费", "%lld local items": "%lld 个本地事项", "ICS Import": "ICS 导入",
      "Import events": "导入事项", "No repeat": "不重复", "Repeats": "重复", "Never": "永不",
      "Daily": "每天", "Weekly": "每周", "Monthly": "每月", "Yearly": "每年",
      "No reminder": "不提醒", "At time": "准时", "5 minutes before": "提前 5 分钟",
      "15 minutes before": "提前 15 分钟", "1 hour before": "提前 1 小时", "1 day before": "提前 1 天",
      "1 week before": "提前 1 周", "Untitled event": "未命名事项", "Event is coming up": "事项即将开始",
      "Product launch": "产品发布", "Prepare localized screenshots and App Store metadata.": "准备本地化截图和 App Store 文案。",
      "Weekly planning": "每周计划", "Review this week, schedule important reminders.": "回顾本周并安排重要提醒。",
      "Family birthday": "家人生日", "Add a gift note and yearly reminder.": "添加礼物备注和每年提醒。",
      "Coral": "珊瑚", "Ocean": "海洋", "Open the app to manage events": "打开 App 管理事项",
      "Countdowns, reminders and today's calendar.": "倒数日、提醒和今日日历。"
    }
  },
  "zh-Hant": {
    appName: "极简日历-倒数日-日程提醒与桌面小组件",
    metadataName: "极简日历-倒数日-日程提醒与桌面小组件",
    metadataSubtitle: "日程生日農曆節日提醒",
    metadataKeywords: "日曆,倒數日,日程,提醒,生日,紀念日,小工具,農曆,節日,計劃",
    promo: "清爽管理日程、生日、倒數日、提醒、節日、iCloud 同步與小工具。",
    description: "用极简日历-倒数日-日程提醒与桌面小组件記錄重要日子，沒有廣告、沒有帳號、沒有第三方分析。它整合清爽日曆、倒數日、生日與紀念日提醒、節日資訊、Apple 日曆匯入、ICS 匯入匯出、iCloud 同步和實用小工具。",
    features: ["月、週、日多視圖", "日程、計劃、生日、紀念日和倒數日", "重複事項和提前提醒", "農曆、節氣和中文市場節日", "全球市場本地節日", "自訂日期角標、顏色和圖示", "匯入 Apple 日曆並可選擇匯出", "ICS 匯入匯出", "透過私人 iCloud 在裝置間同步", "主畫面和鎖定畫面小工具"],
    privacy: "一次性付費。無廣告。無帳號。無第三方分析。",
    release: "首個全球版本，包含日曆、倒數日、提醒、節日、iCloud 同步和小工具。",
    ui: {}
  },
  ja: {
    metadataName: "极简日历-倒数日-日程提醒与桌面小组件", metadataSubtitle: "予定と記念日リマインダー",
    metadataKeywords: "カレンダー,予定,リマインダー,カウントダウン,誕生日,記念日,ウィジェット,祝日",
    promo: "予定、誕生日、カウントダウン、リマインダー、祝日、iCloud 同期、ウィジェットをすっきり管理。",
    description: "広告もアカウントも第三者分析もなく、大切な日を管理できます。极简日历-倒数日-日程提醒与桌面小组件はカレンダー、カウントダウン、誕生日と記念日のリマインダー、祝日情報、Apple カレンダー読み込み、ICS 入出力、iCloud 同期、実用的なウィジェットをまとめます。",
    features: ["月・週・日の表示", "予定、計画、誕生日、記念日、カウントダウン", "繰り返し予定と事前通知", "地域の祝日", "日付バッジ、色、アイコンのカスタマイズ", "Apple カレンダー読み込み", "ICS 入出力", "プライベート iCloud 同期", "ホーム画面とロック画面ウィジェット"],
    privacy: "買い切り。広告なし。アカウント不要。第三者分析なし。",
    release: "カレンダー、カウントダウン、リマインダー、祝日、iCloud 同期、ウィジェットを含む初回グローバルリリース。",
    ui: { "Add": "追加", "Settings": "設定", "Filter": "絞り込み", "All": "すべて", "Delete": "削除", "Today": "今日", "Save": "保存", "Cancel": "キャンセル", "Schedule": "予定", "Plan": "計画", "Birthday": "誕生日", "Anniversary": "記念日", "Countdown": "カウントダウン", "Countdowns": "カウントダウン", "Month": "月", "Week": "週", "Day": "日", "Title": "タイトル", "Notes": "メモ", "New item": "新規項目", "Privacy": "プライバシー" }
  },
  ko: {
    metadataName: "极简日历-倒数日-日程提醒与桌面小组件", metadataSubtitle: "일정 생일 기념일 알림",
    metadataKeywords: "캘린더,일정,리마인더,카운트다운,생일,기념일,위젯,공휴일",
    promo: "일정, 생일, 카운트다운, 알림, 공휴일, iCloud 동기화와 위젯을 깔끔하게 관리하세요.",
    description: "광고, 계정, 제3자 분석 없이 중요한 날을 관리합니다. 极简日历-倒数日-日程提醒与桌面小组件은 깔끔한 캘린더, 카운트다운, 생일과 기념일 알림, 공휴일, Apple 캘린더 가져오기, ICS 입출력, iCloud 동기화, 위젯을 제공합니다.",
    features: ["월/주/일 보기", "일정, 계획, 생일, 기념일, 카운트다운", "반복 일정과 사전 알림", "지역 공휴일", "날짜 배지와 색상 사용자화", "Apple 캘린더 가져오기", "ICS 가져오기/내보내기", "개인 iCloud 동기화", "홈 및 잠금 화면 위젯"],
    privacy: "일회성 구매. 광고 없음. 계정 없음. 제3자 분석 없음.",
    release: "캘린더, 카운트다운, 알림, 공휴일, iCloud 동기화, 위젯을 포함한 첫 글로벌 릴리스。",
    ui: { "Add": "추가", "Settings": "설정", "Filter": "필터", "All": "전체", "Delete": "삭제", "Today": "오늘", "Save": "저장", "Cancel": "취소", "Schedule": "일정", "Plan": "계획", "Birthday": "생일", "Anniversary": "기념일", "Countdown": "카운트다운", "Countdowns": "카운트다운", "Month": "월", "Week": "주", "Day": "일", "Title": "제목", "Notes": "메모", "New item": "새 항목", "Privacy": "개인정보" }
  }
};

const generic = {
  "fr-FR": ["Calendrier rappels anniversaires", "calendrier,compte à rebours,rappel,anniversaire,widget,planning,fêtes", "Achat unique. Sans publicité. Sans compte. Sans analyse tierce."],
  "fr-CA": ["Calendrier rappels anniversaires", "calendrier,compte à rebours,rappel,anniversaire,widget,planning,fêtes", "Achat unique. Sans publicité. Sans compte. Sans analyse tierce."],
  "de-DE": ["Kalender Termine Erinnerungen", "kalender,countdown,termine,erinnerung,geburtstag,jahrestag,widget,feiertage", "Einmalkauf. Keine Werbung. Kein Konto. Keine Analyse durch Dritte."],
  "es-ES": ["Calendario recordatorios días", "calendario,cuenta atrás,recordatorio,cumpleaños,aniversario,widget,festivos", "Pago único. Sin anuncios. Sin cuenta. Sin analíticas de terceros."],
  "es-MX": ["Calendario recordatorios días", "calendario,cuenta atrás,recordatorio,cumpleaños,aniversario,widget,festivos", "Pago único. Sin anuncios. Sin cuenta. Sin analíticas de terceros."],
  "pt-BR": ["Calendário lembretes datas", "calendário,contagem regressiva,lembrete,aniversário,widget,feriados", "Compra única. Sem anúncios. Sem conta. Sem análise de terceiros."],
  "pt-PT": ["Calendário lembretes datas", "calendário,contagem,lembrete,aniversário,widget,feriados", "Compra única. Sem anúncios. Sem conta. Sem análise de terceiros."],
  it: ["Calendario promemoria eventi", "calendario,countdown,promemoria,compleanno,anniversario,widget,festività", "Acquisto unico. Niente pubblicità. Nessun account. Nessuna analisi di terze parti."],
  ru: ["Календарь напоминания даты", "календарь,обратный отсчет,напоминание,день рождения,виджет,праздники", "Разовая покупка. Без рекламы. Без аккаунта. Без сторонней аналитики."],
  "ar-SA": ["تقويم تذكيرات وعد تنازلي", "تقويم,عد تنازلي,تذكير,عيد ميلاد,مناسبة,ودجت,عطلات", "شراء لمرة واحدة. بلا إعلانات. بلا حساب. بلا تحليلات خارجية."],
  he: ["לוח שנה תזכורות וספירה", "לוח שנה,ספירה לאחור,תזכורת,יום הולדת,יישומון,חגים", "רכישה חד-פעמית. ללא מודעות. ללא חשבון. ללא ניתוח צד שלישי."],
  hi: ["कैलेंडर रिमाइंडर काउंटडाउन", "कैलेंडर,काउंटडाउन,रिमाइंडर,जन्मदिन,विजेट,छुट्टियां", "एक बार खरीदें। विज्ञापन नहीं। खाता नहीं। तृतीय-पक्ष विश्लेषण नहीं।"],
  th: ["ปฏิทิน เตือน นับถอยหลัง", "ปฏิทิน,นับถอยหลัง,เตือน,วันเกิด,วิดเจ็ต,วันหยุด", "ซื้อครั้งเดียว ไม่มีโฆษณา ไม่มีบัญชี ไม่มีการวิเคราะห์จากบุคคลที่สาม"],
  vi: ["Lịch nhắc việc đếm ngày", "lịch,đếm ngày,nhắc việc,sinh nhật,kỷ niệm,tiện ích,ngày lễ", "Mua một lần. Không quảng cáo. Không tài khoản. Không phân tích bên thứ ba."],
  tr: ["Takvim hatırlatıcı geri sayım", "takvim,geri sayım,hatırlatıcı,doğum günü,widget,tatil", "Tek seferlik satın alma. Reklam yok. Hesap yok. Üçüncü taraf analiz yok."],
  uk: ["Календар нагадування дати", "календар,відлік,нагадування,день народження,віджет,свята", "Разова покупка. Без реклами. Без акаунта. Без сторонньої аналітики."],
  id: ["Kalender pengingat hitung hari", "kalender,hitung mundur,pengingat,ulang tahun,widget,libur", "Pembelian sekali. Tanpa iklan. Tanpa akun. Tanpa analitik pihak ketiga."],
  ms: ["Kalendar peringatan kira hari", "kalendar,kiraan,peringatan,hari jadi,widget,cuti", "Pembelian sekali. Tiada iklan. Tiada akaun. Tiada analitik pihak ketiga."]
};

const uiKeys = [
  "极简日历", officialName, "Add", "Settings", "Filter", "All", "Delete", "Month", "Week", "Day", "Schedule",
  "Plan", "Birthday", "Anniversary", "Countdown", "Countdowns",
  "Add badge", "Badge", "Icon", "Edit", "Edit item", "Export to Apple Calendar",
  "Calendar access denied", "Exported to Apple Calendar", "Export failed", "Themes", "Status", "OK",
  "Calendar, countdowns, reminders and widgets", "Search schedules, birthdays, countdowns", "iCloud",
  "Today", "Today focus", "Upcoming", "Selected day", "Nothing scheduled",
  "Add a plan, birthday, anniversary or countdown for this day.", "No countdowns yet",
  "Track launches, exams, trips and anniversaries.", "New item", "Details", "Title", "Notes", "Type",
  "Date", "All day", "Starts", "End date", "Ends", "Repeat", "Reminder", "Style", "Pin countdown",
  "Cancel", "Save", "Sync", "iCloud sync ready",
  "Private CloudKit sync keeps your calendars available on your devices.", "Import from Apple Calendar",
  "Calendar access: %@", "Import and Export", "Export ICS", "Paste ICS import", "Privacy",
  "No ads, no account, no third-party analytics", "One-time purchase", "%lld local items",
  "ICS Import", "Import events", "No repeat", "Repeats", "Never", "Daily", "Weekly", "Monthly",
  "Yearly", "No reminder", "At time", "5 minutes before", "15 minutes before", "1 hour before",
  "1 day before", "1 week before", "Untitled event", "Event is coming up", "Product launch",
  "Prepare localized screenshots and App Store metadata.", "Weekly planning",
  "Review this week, schedule important reminders.", "Family birthday",
  "Add a gift note and yearly reminder.", "Coral", "Ocean", "Open the app to manage events",
  "Countdowns, reminders and today's calendar."
];

function pack(locale) {
  const base = packs[locale] ?? {};
  const g = generic[locale];
  const localizedName = localizedAppNames[locale] ?? localizedAppNames["en-US"];
  return {
    ...en,
    ...base,
    appName: localizedName,
    metadataName: localizedName,
    metadataSubtitle: base.metadataSubtitle ?? g?.[0] ?? en.metadataSubtitle,
    metadataKeywords: base.metadataKeywords ?? g?.[1] ?? en.metadataKeywords,
    privacy: base.privacy ?? g?.[2] ?? en.privacy,
    ui: { ...(base.ui ?? {}) }
  };
}

function localizedValue(key, locale) {
  const p = pack(locale);
  if (p.ui[key]) return p.ui[key];
  if (key === "极简日历" || key === officialName) return p.appName ?? officialName;
  if (key === "Calendar, countdowns, reminders and widgets") return p.tagline ?? en.tagline;
  if (key === "No ads, no account, no third-party analytics") return p.privacy.replaceAll(".", "");
  if (locale.startsWith("en")) return key;
  return key;
}

function buildCatalog() {
  const strings = {};
  for (const key of uiKeys) {
    const localizations = {};
    for (const locale of locales) {
      localizations[locale] = {
        stringUnit: {
          state: "translated",
          value: localizedValue(key, locale)
        }
      };
    }
    strings[key] = { localizations };
  }
  return { sourceLanguage: "en", strings, version: "1.0" };
}

function writeMetadata(root) {
  for (const locale of locales) {
    const p = pack(locale);
    const dir = path.join(root, "fastlane", "metadata", locale);
    fs.mkdirSync(dir, { recursive: true });
    const language = languageNames[locale] ?? locale;
    const description = `${p.metadataName}

${p.description}

Key features:
${p.features.map((feature) => `• ${feature}`).join("\n")}

${p.privacy}
`;
    fs.writeFileSync(path.join(dir, "name.txt"), `${p.metadataName}\n`);
    fs.writeFileSync(path.join(dir, "subtitle.txt"), `${p.metadataSubtitle}\n`);
    fs.writeFileSync(path.join(dir, "keywords.txt"), `${p.metadataKeywords.slice(0, 100)}\n`);
    fs.writeFileSync(path.join(dir, "promotional_text.txt"), `${p.promo}\n`);
    fs.writeFileSync(path.join(dir, "description.txt"), description);
    fs.writeFileSync(path.join(dir, "release_notes.txt"), `${p.release} (${language})\n`);
  }
}

function escapePlistString(value) {
  return value.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"");
}

function writeInfoPlistStrings(root) {
  const appRoot = path.join(root, "极简日历-倒数日-日程提醒与桌面小组件");
  for (const locale of locales) {
    const p = pack(locale);
    const dir = path.join(appRoot, `${locale}.lproj`);
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(
      path.join(dir, "InfoPlist.strings"),
      `CFBundleDisplayName = "${escapePlistString(p.appName)}";\nCFBundleName = "${escapePlistString(p.appName)}";\n`,
      "utf8"
    );
  }
}

const root = process.cwd();
const catalogPath = path.join(root, "极简日历-倒数日-日程提醒与桌面小组件", "Localizable.xcstrings");
fs.writeFileSync(catalogPath, `${JSON.stringify(buildCatalog(), null, 2)}\n`);
writeMetadata(root);
writeInfoPlistStrings(root);
console.log(`Localized ${uiKeys.length} UI keys and metadata for ${locales.length} locales.`);
