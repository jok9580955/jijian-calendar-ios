#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "极简日历-倒数日-日程提醒与桌面小组件.xcodeproj"
SCHEME = "极简日历-倒数日-日程提醒与桌面小组件"
BUNDLE_ID = "com.daniao.jijiancalendar"
DERIVED_DATA = ROOT / ".build" / "screenshot-derived"
SCREENSHOT_ROOT = ROOT / "fastlane" / "screenshots"

LOCALES = [
    "ar-SA", "ca", "zh-Hans", "zh-Hant", "hr", "cs", "da", "nl-NL", "en-AU",
    "en-CA", "en-GB", "en-US", "fi", "fr-CA", "fr-FR", "de-DE", "el", "he",
    "hi", "hu", "id", "it", "ja", "ko", "ms", "no", "pl", "pt-BR", "pt-PT",
    "ro", "ru", "sk", "es-MX", "es-ES", "sv", "th", "tr", "uk", "vi",
]

COPY = {
    "en": {
        "screens": [
            ("Calendar, countdowns, reminders", "Schedules, birthdays, holidays and plans stay together."),
            ("Countdown days at a glance", "Track launches, trips, birthdays and anniversaries."),
            ("Smart reminders for every plan", "Choose repeat rules and alerts before the day arrives."),
            ("Home and Lock Screen widgets", "See today's events and countdowns without opening the app."),
            ("Private by design", "No ads, no account and no third-party analytics."),
        ],
        "labels": [
            ["Today", "Countdowns", "Reminders"],
            ["Launch", "Trip", "Birthday"],
            ["Schedule", "Repeat", "Alert"],
            ["Calendar", "Countdown", "Reminder"],
            ["No tracking", "iCloud sync", "ICS import/export"],
        ],
        "footers": [
            "One-time purchase. No ads. No account.",
            "Pin important days to widgets.",
            "Works with Apple Calendar and ICS.",
            "Syncs privately with iCloud.",
            "Your calendar data stays on your devices.",
        ],
    },
    "zh-Hans": {
        "screens": [
            ("日历、倒数日、提醒一屏管理", "日程、生日、节假日和计划清爽放在一起。"),
            ("重要日子一眼倒数", "记录发布、旅行、生日和纪念日。"),
            ("每个计划都有聪明提醒", "设置重复规则和提前提醒，不错过重要时刻。"),
            ("桌面与锁屏小组件", "不用打开 App，也能看今天日程和倒数日。"),
            ("隐私友好设计", "无广告、无账号、无第三方分析。"),
        ],
        "labels": [
            ["今天", "倒数日", "提醒"],
            ["发布", "旅行", "生日"],
            ["日程", "重复", "提醒"],
            ["日历", "倒数日", "提醒"],
            ["不追踪", "iCloud 同步", "ICS 导入导出"],
        ],
        "footers": ["一次性付费。无广告。无账号。", "重要日子可固定到小组件。", "支持 Apple 日历与 ICS。", "通过 iCloud 私密同步。", "你的日历数据留在你的设备上。"],
    },
    "zh-Hant": {
        "screens": [
            ("日曆、倒數日、提醒一屏管理", "日程、生日、節日和計劃清爽放在一起。"),
            ("重要日子一眼倒數", "記錄發佈、旅行、生日和紀念日。"),
            ("每個計劃都有聰明提醒", "設定重複規則和提前提醒，不錯過重要時刻。"),
            ("主畫面與鎖定畫面小工具", "不用打開 App，也能看今天日程和倒數日。"),
            ("重視隱私的設計", "無廣告、無帳號、無第三方分析。"),
        ],
        "labels": [
            ["今天", "倒數日", "提醒"],
            ["發佈", "旅行", "生日"],
            ["日程", "重複", "提醒"],
            ["日曆", "倒數日", "提醒"],
            ["不追蹤", "iCloud 同步", "ICS 匯入匯出"],
        ],
        "footers": ["一次性付費。無廣告。無帳號。", "重要日子可固定到小工具。", "支援 Apple 日曆與 ICS。", "透過 iCloud 私密同步。", "你的日曆資料留在你的裝置上。"],
    },
    "ja": {
        "screens": [
            ("予定、カウントダウン、通知を一つに", "予定、誕生日、祝日、計画をすっきり管理。"),
            ("大切な日まで一目でカウント", "リリース、旅行、誕生日、記念日を記録。"),
            ("予定ごとに賢くリマインド", "繰り返しと事前通知を自由に設定。"),
            ("ホーム画面とロック画面ウィジェット", "アプリを開かずに今日の予定と残り日数を確認。"),
            ("プライバシー重視", "広告なし、アカウント不要、第三者分析なし。"),
        ],
        "labels": [["今日", "残り日数", "通知"], ["公開", "旅行", "誕生日"], ["予定", "繰り返し", "通知"], ["カレンダー", "カウント", "通知"], ["追跡なし", "iCloud 同期", "ICS 入出力"]],
        "footers": ["買い切り。広告なし。アカウント不要。", "大切な日をウィジェットに固定。", "Apple カレンダーと ICS に対応。", "iCloud でプライベート同期。", "カレンダーデータはあなたの端末に残ります。"],
    },
    "ko": {
        "screens": [
            ("캘린더, 카운트다운, 알림을 한눈에", "일정, 생일, 공휴일과 계획을 깔끔하게 관리하세요."),
            ("중요한 날까지 남은 시간을 바로 확인", "출시, 여행, 생일과 기념일을 기록하세요."),
            ("모든 계획에 똑똑한 알림", "반복 규칙과 사전 알림을 설정하세요."),
            ("홈 및 잠금 화면 위젯", "앱을 열지 않아도 오늘 일정과 카운트다운을 확인하세요."),
            ("개인정보 중심 설계", "광고, 계정, 제3자 분석이 없습니다."),
        ],
        "labels": [["오늘", "카운트다운", "알림"], ["출시", "여행", "생일"], ["일정", "반복", "알림"], ["캘린더", "카운트다운", "알림"], ["추적 없음", "iCloud 동기화", "ICS 가져오기/내보내기"]],
        "footers": ["일회성 구매. 광고 없음. 계정 없음.", "중요한 날을 위젯에 고정하세요.", "Apple 캘린더와 ICS 지원.", "iCloud로 비공개 동기화.", "캘린더 데이터는 내 기기에 남습니다."],
    },
    "fr": {
        "screens": [
            ("Calendrier, comptes à rebours, rappels", "Vos événements, anniversaires, jours fériés et projets au même endroit."),
            ("Les jours importants en un coup d'oeil", "Suivez lancements, voyages, anniversaires et dates clés."),
            ("Des rappels malins pour chaque plan", "Choisissez répétitions et alertes avant le jour J."),
            ("Widgets d'accueil et d'écran verrouillé", "Voyez les événements du jour sans ouvrir l'app."),
            ("Conçu pour la vie privée", "Sans publicité, sans compte, sans analyse tierce."),
        ],
        "labels": [["Aujourd'hui", "Comptes", "Rappels"], ["Lancement", "Voyage", "Anniversaire"], ["Événement", "Répéter", "Alerte"], ["Calendrier", "Compte", "Rappel"], ["Sans suivi", "Sync iCloud", "Import/export ICS"]],
        "footers": ["Achat unique. Sans pub. Sans compte.", "Épinglez les dates dans les widgets.", "Compatible Apple Calendrier et ICS.", "Synchronisation privée avec iCloud.", "Vos données restent sur vos appareils."],
    },
    "de": {
        "screens": [
            ("Kalender, Countdowns, Erinnerungen", "Termine, Geburtstage, Feiertage und Pläne an einem Ort."),
            ("Wichtige Tage auf einen Blick", "Verfolge Starts, Reisen, Geburtstage und Jahrestage."),
            ("Kluge Erinnerungen für jeden Plan", "Wähle Wiederholungen und Warnungen rechtzeitig aus."),
            ("Home- und Sperrbildschirm-Widgets", "Sieh heutige Termine, ohne die App zu öffnen."),
            ("Für Privatsphäre gemacht", "Keine Werbung, kein Konto, keine Drittanbieter-Analyse."),
        ],
        "labels": [["Heute", "Countdowns", "Erinnerungen"], ["Start", "Reise", "Geburtstag"], ["Termin", "Wiederholen", "Alarm"], ["Kalender", "Countdown", "Erinnerung"], ["Kein Tracking", "iCloud-Sync", "ICS Import/Export"]],
        "footers": ["Einmalkauf. Keine Werbung. Kein Konto.", "Wichtige Tage an Widgets anheften.", "Mit Apple Kalender und ICS.", "Privat mit iCloud synchronisieren.", "Deine Kalenderdaten bleiben auf deinen Geräten."],
    },
    "es": {
        "screens": [
            ("Calendario, cuenta atrás y avisos", "Eventos, cumpleaños, festivos y planes en una vista limpia."),
            ("Días importantes de un vistazo", "Sigue lanzamientos, viajes, cumpleaños y aniversarios."),
            ("Recordatorios inteligentes para cada plan", "Elige repeticiones y alertas antes de que llegue el día."),
            ("Widgets de inicio y pantalla bloqueada", "Consulta eventos y cuentas atrás sin abrir la app."),
            ("Privacidad desde el diseño", "Sin anuncios, sin cuenta y sin analíticas de terceros."),
        ],
        "labels": [["Hoy", "Cuenta atrás", "Avisos"], ["Lanzamiento", "Viaje", "Cumpleaños"], ["Evento", "Repetir", "Alerta"], ["Calendario", "Cuenta atrás", "Aviso"], ["Sin rastreo", "Sync iCloud", "Importar/exportar ICS"]],
        "footers": ["Pago único. Sin anuncios. Sin cuenta.", "Fija días importantes en widgets.", "Compatible con Apple Calendar e ICS.", "Sincronización privada con iCloud.", "Tus datos quedan en tus dispositivos."],
    },
    "pt": {
        "screens": [
            ("Calendário, contagens e lembretes", "Eventos, aniversários, feriados e planos em uma visão limpa."),
            ("Dias importantes num relance", "Acompanhe lançamentos, viagens, aniversários e datas especiais."),
            ("Lembretes inteligentes para cada plano", "Escolha repetições e alertas antes do dia chegar."),
            ("Widgets da tela inicial e bloqueada", "Veja eventos de hoje sem abrir o app."),
            ("Privacidade desde o início", "Sem anúncios, sem conta e sem análise de terceiros."),
        ],
        "labels": [["Hoje", "Contagens", "Lembretes"], ["Lançamento", "Viagem", "Aniversário"], ["Evento", "Repetir", "Alerta"], ["Calendário", "Contagem", "Lembrete"], ["Sem rastreio", "Sync iCloud", "Importar/exportar ICS"]],
        "footers": ["Compra única. Sem anúncios. Sem conta.", "Fixe dias importantes nos widgets.", "Compatível com Apple Calendar e ICS.", "Sincronização privada com iCloud.", "Seus dados ficam nos seus dispositivos."],
    },
    "it": {
        "screens": [
            ("Calendario, countdown, promemoria", "Eventi, compleanni, festività e piani in una vista pulita."),
            ("Date importanti a colpo d'occhio", "Segui lanci, viaggi, compleanni e anniversari."),
            ("Promemoria intelligenti per ogni piano", "Scegli ripetizioni e avvisi prima del giorno."),
            ("Widget Home e schermata di blocco", "Vedi eventi e countdown senza aprire l'app."),
            ("Pensata per la privacy", "Niente pubblicità, account o analisi di terze parti."),
        ],
        "labels": [["Oggi", "Countdown", "Promemoria"], ["Lancio", "Viaggio", "Compleanno"], ["Evento", "Ripeti", "Avviso"], ["Calendario", "Countdown", "Promemoria"], ["No tracking", "Sync iCloud", "Import/export ICS"]],
        "footers": ["Acquisto unico. Niente pubblicità. Nessun account.", "Fissa le date importanti nei widget.", "Supporta Apple Calendario e ICS.", "Sincronizzazione privata con iCloud.", "I dati restano sui tuoi dispositivi."],
    },
    "ar": {
        "screens": [
            ("تقويم وعد تنازلي وتذكيرات", "اجمع المواعيد وأعياد الميلاد والعطلات والخطط في عرض واضح."),
            ("الأيام المهمة بلمحة", "تابع الإطلاقات والرحلات وأعياد الميلاد والذكريات."),
            ("تذكيرات ذكية لكل خطة", "اختر التكرار والتنبيهات قبل حلول اليوم."),
            ("ودجات الشاشة الرئيسية والقفل", "شاهد أحداث اليوم والعد التنازلي دون فتح التطبيق."),
            ("مصمم للخصوصية", "بلا إعلانات، بلا حساب، بلا تحليلات خارجية."),
        ],
        "labels": [["اليوم", "عد تنازلي", "تذكيرات"], ["إطلاق", "رحلة", "عيد ميلاد"], ["موعد", "تكرار", "تنبيه"], ["تقويم", "عد تنازلي", "تذكير"], ["بلا تتبع", "مزامنة iCloud", "استيراد/تصدير ICS"]],
        "footers": ["شراء لمرة واحدة. بلا إعلانات. بلا حساب.", "ثبّت الأيام المهمة في الودجات.", "يدعم تقويم Apple و ICS.", "مزامنة خاصة عبر iCloud.", "تبقى بيانات التقويم على أجهزتك."],
    },
    "he": {
        "screens": [
            ("לוח שנה, ספירה לאחור ותזכורות", "אירועים, ימי הולדת, חגים ותוכניות במקום נקי אחד."),
            ("ימים חשובים במבט מהיר", "עקבו אחרי השקות, נסיעות, ימי הולדת וימי שנה."),
            ("תזכורות חכמות לכל תוכנית", "בחרו חזרות והתראות לפני שהיום מגיע."),
            ("יישומונים למסך הבית והנעילה", "ראו את אירועי היום בלי לפתוח את האפליקציה."),
            ("פרטיות כברירת מחדל", "ללא מודעות, ללא חשבון וללא ניתוח צד שלישי."),
        ],
        "labels": [["היום", "ספירה", "תזכורות"], ["השקה", "נסיעה", "יום הולדת"], ["אירוע", "חזרה", "התראה"], ["לוח שנה", "ספירה", "תזכורת"], ["ללא מעקב", "סנכרון iCloud", "ייבוא/ייצוא ICS"]],
        "footers": ["רכישה חד-פעמית. בלי מודעות. בלי חשבון.", "נעצו ימים חשובים ביישומונים.", "תומך בלוח שנה של Apple וב-ICS.", "סנכרון פרטי עם iCloud.", "נתוני הלוח נשארים במכשירים שלכם."],
    },
    "ru": {
        "screens": [
            ("Календарь, отсчет и напоминания", "События, дни рождения, праздники и планы в одном чистом виде."),
            ("Важные даты сразу видны", "Следите за запусками, поездками, днями рождения и годовщинами."),
            ("Умные напоминания для каждого плана", "Настраивайте повторы и оповещения заранее."),
            ("Виджеты для экрана Домой и блокировки", "Смотрите события дня, не открывая приложение."),
            ("Приватность в основе", "Без рекламы, без аккаунта и без сторонней аналитики."),
        ],
        "labels": [["Сегодня", "Отсчет", "Напоминания"], ["Запуск", "Поездка", "День рождения"], ["Событие", "Повтор", "Оповещение"], ["Календарь", "Отсчет", "Напоминание"], ["Без трекинга", "Синхр. iCloud", "Импорт/экспорт ICS"]],
        "footers": ["Разовая покупка. Без рекламы. Без аккаунта.", "Закрепляйте важные даты в виджетах.", "Поддержка Apple Calendar и ICS.", "Приватная синхронизация через iCloud.", "Данные календаря остаются на ваших устройствах."],
    },
    "hi": {
        "screens": [
            ("कैलेंडर, काउंटडाउन, रिमाइंडर", "इवेंट, जन्मदिन, छुट्टियां और योजनाएं एक साफ दृश्य में।"),
            ("ज़रूरी दिन एक नज़र में", "लॉन्च, यात्रा, जन्मदिन और वर्षगांठ ट्रैक करें।"),
            ("हर योजना के लिए स्मार्ट रिमाइंडर", "दिन आने से पहले रिपीट और अलर्ट चुनें।"),
            ("होम और लॉक स्क्रीन विजेट", "ऐप खोले बिना आज के इवेंट देखें।"),
            ("निजता के लिए बनाया गया", "विज्ञापन नहीं, खाता नहीं, तृतीय-पक्ष विश्लेषण नहीं।"),
        ],
        "labels": [["आज", "काउंटडाउन", "रिमाइंडर"], ["लॉन्च", "यात्रा", "जन्मदिन"], ["इवेंट", "दोहराएं", "अलर्ट"], ["कैलेंडर", "काउंटडाउन", "रिमाइंडर"], ["ट्रैकिंग नहीं", "iCloud सिंक", "ICS आयात/निर्यात"]],
        "footers": ["एक बार खरीदें। विज्ञापन नहीं। खाता नहीं।", "ज़रूरी दिन विजेट में पिन करें।", "Apple Calendar और ICS समर्थित।", "iCloud से निजी सिंक।", "आपका कैलेंडर डेटा आपके डिवाइस पर रहता है।"],
    },
    "th": {
        "screens": [
            ("ปฏิทิน นับถอยหลัง และเตือน", "รวมกิจกรรม วันเกิด วันหยุด และแผนไว้ในมุมมองสะอาดตา"),
            ("วันสำคัญเห็นได้ทันที", "ติดตามการเปิดตัว ทริป วันเกิด และวันครบรอบ"),
            ("การเตือนฉลาดสำหรับทุกแผน", "ตั้งการทำซ้ำและการแจ้งเตือนล่วงหน้า"),
            ("วิดเจ็ตหน้าจอโฮมและล็อก", "ดูงานวันนี้โดยไม่ต้องเปิดแอป"),
            ("ออกแบบเพื่อความเป็นส่วนตัว", "ไม่มีโฆษณา ไม่มีบัญชี ไม่มีการวิเคราะห์จากบุคคลที่สาม"),
        ],
        "labels": [["วันนี้", "นับถอยหลัง", "เตือน"], ["เปิดตัว", "ทริป", "วันเกิด"], ["กิจกรรม", "ทำซ้ำ", "แจ้งเตือน"], ["ปฏิทิน", "นับถอยหลัง", "เตือน"], ["ไม่ติดตาม", "ซิงค์ iCloud", "นำเข้า/ส่งออก ICS"]],
        "footers": ["ซื้อครั้งเดียว ไม่มีโฆษณา ไม่มีบัญชี", "ปักหมุดวันสำคัญในวิดเจ็ต", "รองรับ Apple Calendar และ ICS", "ซิงค์ส่วนตัวด้วย iCloud", "ข้อมูลปฏิทินอยู่บนอุปกรณ์ของคุณ"],
    },
    "vi": {
        "screens": [
            ("Lịch, đếm ngày, nhắc việc", "Sự kiện, sinh nhật, ngày lễ và kế hoạch trong một giao diện gọn."),
            ("Ngày quan trọng trong nháy mắt", "Theo dõi ra mắt, chuyến đi, sinh nhật và kỷ niệm."),
            ("Nhắc việc thông minh cho mọi kế hoạch", "Chọn lặp lại và báo trước khi ngày đến."),
            ("Tiện ích Màn hình chính và khóa", "Xem sự kiện hôm nay mà không mở ứng dụng."),
            ("Thiết kế vì quyền riêng tư", "Không quảng cáo, không tài khoản, không phân tích bên thứ ba."),
        ],
        "labels": [["Hôm nay", "Đếm ngày", "Nhắc việc"], ["Ra mắt", "Chuyến đi", "Sinh nhật"], ["Sự kiện", "Lặp lại", "Báo trước"], ["Lịch", "Đếm ngày", "Nhắc việc"], ["Không theo dõi", "Đồng bộ iCloud", "Nhập/xuất ICS"]],
        "footers": ["Mua một lần. Không quảng cáo. Không tài khoản.", "Ghim ngày quan trọng vào tiện ích.", "Hỗ trợ Apple Calendar và ICS.", "Đồng bộ riêng tư bằng iCloud.", "Dữ liệu lịch ở lại trên thiết bị của bạn."],
    },
    "tr": {
        "screens": [
            ("Takvim, geri sayım, hatırlatıcı", "Etkinlikler, doğum günleri, tatiller ve planlar tek temiz görünümde."),
            ("Önemli günler bir bakışta", "Lansmanları, seyahatleri, doğum günlerini ve yıldönümlerini izleyin."),
            ("Her plan için akıllı hatırlatıcılar", "Gün gelmeden tekrarları ve uyarıları seçin."),
            ("Ana Ekran ve Kilit Ekranı widget'ları", "Uygulamayı açmadan bugünün etkinliklerini görün."),
            ("Gizlilik için tasarlandı", "Reklam yok, hesap yok, üçüncü taraf analizi yok."),
        ],
        "labels": [["Bugün", "Geri sayım", "Hatırlatıcı"], ["Lansman", "Seyahat", "Doğum günü"], ["Etkinlik", "Tekrar", "Uyarı"], ["Takvim", "Geri sayım", "Hatırlatıcı"], ["Takip yok", "iCloud eşzamanlama", "ICS içe/dışa aktar"]],
        "footers": ["Tek seferlik satın alma. Reklam yok. Hesap yok.", "Önemli günleri widget'lara sabitleyin.", "Apple Calendar ve ICS desteği.", "iCloud ile özel eşzamanlama.", "Takvim verileriniz cihazlarınızda kalır."],
    },
    "id": {
        "screens": [
            ("Kalender, hitung mundur, pengingat", "Acara, ulang tahun, libur, dan rencana dalam satu tampilan bersih."),
            ("Hari penting terlihat sekilas", "Lacak peluncuran, perjalanan, ulang tahun, dan hari jadi."),
            ("Pengingat cerdas untuk setiap rencana", "Pilih pengulangan dan alarm sebelum harinya tiba."),
            ("Widget Layar Utama dan Terkunci", "Lihat acara hari ini tanpa membuka aplikasi."),
            ("Dirancang untuk privasi", "Tanpa iklan, tanpa akun, tanpa analitik pihak ketiga."),
        ],
        "labels": [["Hari ini", "Hitung mundur", "Pengingat"], ["Peluncuran", "Perjalanan", "Ulang tahun"], ["Acara", "Ulangi", "Alarm"], ["Kalender", "Hitung mundur", "Pengingat"], ["Tanpa pelacakan", "Sinkron iCloud", "Impor/ekspor ICS"]],
        "footers": ["Pembelian sekali. Tanpa iklan. Tanpa akun.", "Sematkan hari penting ke widget.", "Mendukung Apple Calendar dan ICS.", "Sinkron pribadi dengan iCloud.", "Data kalender tetap di perangkat Anda."],
    },
    "ms": {
        "screens": [
            ("Kalendar, kiraan, peringatan", "Acara, hari lahir, cuti dan rancangan dalam satu paparan bersih."),
            ("Hari penting sepintas lalu", "Jejaki pelancaran, perjalanan, hari lahir dan ulang tahun."),
            ("Peringatan pintar untuk setiap rancangan", "Pilih ulangan dan amaran sebelum harinya tiba."),
            ("Widget Skrin Utama dan Kunci", "Lihat acara hari ini tanpa membuka app."),
            ("Direka untuk privasi", "Tiada iklan, tiada akaun, tiada analitik pihak ketiga."),
        ],
        "labels": [["Hari ini", "Kiraan", "Peringatan"], ["Pelancaran", "Perjalanan", "Hari lahir"], ["Acara", "Ulang", "Amaran"], ["Kalendar", "Kiraan", "Peringatan"], ["Tiada penjejakan", "Segerak iCloud", "Import/eksport ICS"]],
        "footers": ["Pembelian sekali. Tiada iklan. Tiada akaun.", "Pin hari penting pada widget.", "Menyokong Apple Calendar dan ICS.", "Segerak peribadi dengan iCloud.", "Data kalendar kekal pada peranti anda."],
    },
}

LANGUAGE_ALIASES = {
    "en-AU": "en", "en-CA": "en", "en-GB": "en", "en-US": "en",
    "fr-CA": "fr", "fr-FR": "fr",
    "de-DE": "de",
    "es-MX": "es", "es-ES": "es",
    "pt-BR": "pt", "pt-PT": "pt",
    "ar-SA": "ar",
}

SIMPLE_LANGUAGE_COPY = {
    "ca": ("Calendari, compte enrere i avisos", "Esdeveniments, aniversaris, festius i plans en una vista neta.", "Avui", "Compte enrere", "Avisos", "Compra única. Sense anuncis. Sense compte."),
    "hr": ("Kalendar, odbrojavanje, podsjetnici", "Događaji, rođendani, blagdani i planovi u čistom prikazu.", "Danas", "Odbrojavanje", "Podsjetnici", "Jednokratna kupnja. Bez oglasa. Bez računa."),
    "cs": ("Kalendář, odpočty a připomínky", "Události, narozeniny, svátky a plány v čistém zobrazení.", "Dnes", "Odpočet", "Připomínky", "Jednorázový nákup. Bez reklam. Bez účtu."),
    "da": ("Kalender, nedtælling og påmindelser", "Begivenheder, fødselsdage, helligdage og planer i én ren visning.", "I dag", "Nedtælling", "Påmindelser", "Engangskøb. Ingen reklamer. Ingen konto."),
    "nl-NL": ("Kalender, aftellen en herinneringen", "Afspraken, verjaardagen, feestdagen en plannen in één helder overzicht.", "Vandaag", "Aftellen", "Herinneringen", "Eenmalige aankoop. Geen advertenties. Geen account."),
    "fi": ("Kalenteri, laskurit ja muistutukset", "Tapahtumat, syntymäpäivät, pyhät ja suunnitelmat samassa selkeässä näkymässä.", "Tänään", "Laskuri", "Muistutukset", "Kertaostos. Ei mainoksia. Ei tiliä."),
    "el": ("Ημερολόγιο, αντίστροφη μέτρηση, υπενθυμίσεις", "Γεγονότα, γενέθλια, αργίες και σχέδια σε καθαρή προβολή.", "Σήμερα", "Αντίστροφη", "Υπενθυμίσεις", "Εφάπαξ αγορά. Χωρίς διαφημίσεις. Χωρίς λογαριασμό."),
    "hu": ("Naptár, visszaszámlálás, emlékeztetők", "Események, születésnapok, ünnepek és tervek egy tiszta nézetben.", "Ma", "Visszaszámlálás", "Emlékeztetők", "Egyszeri vásárlás. Nincs reklám. Nincs fiók."),
    "no": ("Kalender, nedtelling og påminnelser", "Hendelser, bursdager, helligdager og planer i én ryddig visning.", "I dag", "Nedtelling", "Påminnelser", "Engangskjøp. Ingen annonser. Ingen konto."),
    "pl": ("Kalendarz, odliczanie, przypomnienia", "Wydarzenia, urodziny, święta i plany w jednym czystym widoku.", "Dzisiaj", "Odliczanie", "Przypomnienia", "Jednorazowy zakup. Bez reklam. Bez konta."),
    "ro": ("Calendar, numărătoare și mementouri", "Evenimente, zile de naștere, sărbători și planuri într-o vizualizare curată.", "Astăzi", "Numărătoare", "Mementouri", "Achiziție unică. Fără reclame. Fără cont."),
    "sk": ("Kalendár, odpočty a pripomienky", "Udalosti, narodeniny, sviatky a plány v čistom zobrazení.", "Dnes", "Odpočet", "Pripomienky", "Jednorazový nákup. Bez reklám. Bez účtu."),
    "sv": ("Kalender, nedräkning och påminnelser", "Händelser, födelsedagar, helgdagar och planer i en ren vy.", "I dag", "Nedräkning", "Påminnelser", "Engångsköp. Inga annonser. Inget konto."),
    "uk": ("Календар, відлік і нагадування", "Події, дні народження, свята й плани в одному чистому вигляді.", "Сьогодні", "Відлік", "Нагадування", "Разова покупка. Без реклами. Без акаунта."),
}


def run(command: list[str], check: bool = True) -> subprocess.CompletedProcess:
    print("+", " ".join(command))
    return subprocess.run(command, cwd=ROOT, check=check, text=True, capture_output=False)


def build_app(skip_build: bool) -> Path:
    if not skip_build:
        run([
            "xcodebuild",
            "-project", str(PROJECT),
            "-scheme", SCHEME,
            "-configuration", "Debug",
            "-destination", "generic/platform=iOS Simulator",
            "-derivedDataPath", str(DERIVED_DATA),
            "build",
            "CODE_SIGNING_ALLOWED=NO",
        ])
    product_dir = DERIVED_DATA / "Build" / "Products" / "Debug-iphonesimulator"
    apps = sorted(product_dir.glob("*.app"), key=lambda p: p.stat().st_mtime, reverse=True)
    for app in apps:
        if app.name == f"{SCHEME}.app":
            return app
    if apps:
        return apps[0]
    raise SystemExit(f"No simulator app found in {product_dir}")


def devices_json() -> dict:
    output = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], text=True)
    return json.loads(output)


def runtime_version(runtime_key: str) -> tuple[int, ...]:
    digits = "".join(ch if ch.isdigit() else "." for ch in runtime_key)
    return tuple(int(part) for part in digits.split(".") if part)


def resolve_device(name_or_udid: str) -> tuple[str, str]:
    data = devices_json()["devices"]
    matches = []
    for runtime, devices in data.items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if not device.get("isAvailable", True):
                continue
            if device["udid"] == name_or_udid or device["name"] == name_or_udid:
                matches.append((runtime_version(runtime), device["udid"], device["name"]))
    if not matches:
        raise SystemExit(f"Device not found: {name_or_udid}")
    _, udid, name = sorted(matches)[-1]
    return udid, name


def boot_device(udid: str) -> None:
    subprocess.run(["xcrun", "simctl", "boot", udid], cwd=ROOT, check=False)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"])


def locale_to_apple_locale(locale: str) -> str:
    return locale.replace("-", "_")


def copy_for(locale: str, screen: int) -> dict[str, str]:
    key = LANGUAGE_ALIASES.get(locale, locale)
    if key in SIMPLE_LANGUAGE_COPY:
        title, subtitle, a, b, c, footer = SIMPLE_LANGUAGE_COPY[key]
        if screen == 2:
            title = title.replace("Kalender", b).replace("Calendari", b).replace("Calendar", b)
        elif screen == 3:
            title = c
        elif screen == 4:
            title = "Widgets"
            subtitle = subtitle
        elif screen == 5:
            title = footer
        return {
            "headline": title,
            "subhead": subtitle,
            "labels": [a, b, c],
            "footer": footer,
        }
    pack = COPY.get(key) or COPY.get(locale) or COPY["en"]
    index = max(0, min(screen - 1, 4))
    headline, subhead = pack["screens"][index]
    return {
        "headline": headline,
        "subhead": subhead,
        "labels": pack["labels"][index],
        "footer": pack["footers"][index],
    }


def launch_and_capture(udid: str, app_path: Path, locale: str, screen: int, output_path: Path, delay: float) -> None:
    copy = copy_for(locale, screen)
    subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE_ID], cwd=ROOT, check=False)
    args = [
        "xcrun", "simctl", "launch", udid, BUNDLE_ID,
        "-FASTLANE_SNAPSHOT", "YES",
        "-ScreenshotMode", str(screen),
        "-AppleLanguages", f"({locale})",
        "-AppleLocale", locale_to_apple_locale(locale),
        "-ScreenshotHeadline", copy["headline"],
        "-ScreenshotSubhead", copy["subhead"],
        "-ScreenshotLabelA", copy["labels"][0],
        "-ScreenshotLabelB", copy["labels"][1],
        "-ScreenshotLabelC", copy["labels"][2],
        "-ScreenshotFooter", copy["footer"],
    ]
    run(args)
    time.sleep(delay)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    run(["xcrun", "simctl", "io", udid, "screenshot", str(output_path)])


def sanitize(value: str) -> str:
    return "".join(ch if ch.isalnum() else "_" for ch in value).strip("_")


def parse_csv(value: str | None, default: list[str]) -> list[str]:
    if not value:
        return default
    return [part.strip() for part in value.split(",") if part.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture localized simulator screenshots for App Store Connect.")
    parser.add_argument("--locales", help="Comma-separated App Store locales. Defaults to all 39 locales.")
    parser.add_argument("--devices", help="Comma-separated simulator names or UDIDs.", default="iPhone 17 Pro Max,iPad Pro 13-inch (M5)")
    parser.add_argument("--screens", help="Comma-separated screen modes 1-5.", default="1,2,3,4,5")
    parser.add_argument("--delay", type=float, default=1.4)
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--clean", action="store_true", help="Clean selected locale screenshot folders before capture.")
    args = parser.parse_args()

    locales = parse_csv(args.locales, LOCALES)
    screens = [int(part) for part in parse_csv(args.screens, ["1", "2", "3", "4", "5"])]
    app_path = build_app(args.skip_build)
    print(f"Using app: {app_path}")

    devices = [resolve_device(name) for name in parse_csv(args.devices, [])]
    for locale in locales:
        if args.clean:
            shutil.rmtree(SCREENSHOT_ROOT / locale, ignore_errors=True)

    for udid, device_name in devices:
        boot_device(udid)
        for locale in locales:
            subprocess.run(["xcrun", "simctl", "uninstall", udid, BUNDLE_ID], cwd=ROOT, check=False)
            run(["xcrun", "simctl", "install", udid, str(app_path)])
            device_prefix = "iPad" if "iPad" in device_name else "iPhone"
            safe_name = sanitize(device_name)
            for screen in screens:
                shot_name = f"{device_prefix}_{safe_name}-{screen:02d}.png"
                launch_and_capture(udid, app_path, locale, screen, SCREENSHOT_ROOT / locale / shot_name, args.delay)

    locale_dirs = [path for path in SCREENSHOT_ROOT.iterdir() if path.is_dir()] if SCREENSHOT_ROOT.exists() else []
    total_png = sum(1 for _ in SCREENSHOT_ROOT.glob("*/*.png")) if SCREENSHOT_ROOT.exists() else 0
    print(f"Captured locale_dirs={len(locale_dirs)} total_png={total_png}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
