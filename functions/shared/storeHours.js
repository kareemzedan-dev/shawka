/**
 * تقييم ساعات عمل المتجر بتوقيت Africa/Cairo
 * (متوافق مع StoreOperatingHours في تطبيق Flutter).
 */

function parseMinutes(value) {
  if (typeof value !== "string") return null;
  const parts = value.split(":");
  if (parts.length !== 2) return null;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isFinite(h) || !Number.isFinite(m)) return null;
  return h * 60 + m;
}

function cairoWeekdayAndMinutes(now = new Date()) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Africa/Cairo",
    weekday: "short",
    hour: "numeric",
    minute: "numeric",
    hourCycle: "h23",
  }).formatToParts(now);

  const get = (type) => parts.find((p) => p.type === type)?.value;
  const weekdayMap = {
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
    Sun: 7,
  };
  const weekday = weekdayMap[get("weekday")];
  const hour = Number(get("hour"));
  const minute = Number(get("minute"));
  if (!weekday || !Number.isFinite(hour) || !Number.isFinite(minute)) {
    return null;
  }
  return { weekday, minutes: hour * 60 + minute };
}

/**
 * هل المتجر ضمن ساعات العمل الآن؟
 * لا يفحص isActive / forceClosed — استخدم assertStoreSellable لذلك.
 */
function isWithinOperatingHours(store, now = new Date()) {
  const hours = store?.operatingHours;
  const hasSchedule =
    hours && typeof hours === "object" && Object.keys(hours).length > 0;

  if (!hasSchedule) {
    // الحقل isOpen في Firestore = fallbackOpen عند غياب الجدول
    return store?.isOpen !== false;
  }

  const wall = cairoWeekdayAndMinutes(now);
  if (!wall) return false;

  const day = hours[String(wall.weekday)] || hours[wall.weekday];
  if (day && typeof day === "object" && day.closed !== true) {
    const open = parseMinutes(day.open);
    const close = parseMinutes(day.close);
    if (open != null && close != null) {
      if (close <= open) {
        if (wall.minutes >= open) return true;
      } else if (wall.minutes >= open && wall.minutes < close) {
        return true;
      }
    }
  }

  // امتداد دوام الأمس بعد منتصف الليل (مثل 22:00 → 02:00).
  const yesterdayWeekday = wall.weekday === 1 ? 7 : wall.weekday - 1;
  const yesterday =
    hours[String(yesterdayWeekday)] || hours[yesterdayWeekday];
  if (yesterday && typeof yesterday === "object" && yesterday.closed !== true) {
    const open = parseMinutes(yesterday.open);
    const close = parseMinutes(yesterday.close);
    if (open != null && close != null && close <= open && wall.minutes < close) {
      return true;
    }
  }

  return false;
}

/**
 * هل يمكن قبول طلب من هذا المتجر الآن؟
 */
function isStoreSellable(store, now = new Date()) {
  if (!store) return false;
  if (store.isActive === false || store.status === "disabled") return false;
  if (store.forceClosed === true) return false;
  return isWithinOperatingHours(store, now);
}

module.exports = {
  isWithinOperatingHours,
  isStoreSellable,
  cairoWeekdayAndMinutes,
  parseMinutes,
};
