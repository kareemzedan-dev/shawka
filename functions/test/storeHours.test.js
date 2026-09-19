const test = require("node:test");
const assert = require("node:assert/strict");
const {
  isStoreSellable,
  isWithinOperatingHours,
  cairoWeekdayAndMinutes,
} = require("../shared/storeHours");

test("fallbackOpen when no schedule", () => {
  assert.equal(isStoreSellable({ isActive: true, isOpen: true }), true);
  assert.equal(isStoreSellable({ isActive: true, isOpen: false }), false);
});

test("forceClosed always blocks", () => {
  assert.equal(
    isStoreSellable({
      isActive: true,
      isOpen: true,
      forceClosed: true,
      operatingHours: {
        1: { closed: false, open: "00:00", close: "23:59" },
        2: { closed: false, open: "00:00", close: "23:59" },
        3: { closed: false, open: "00:00", close: "23:59" },
        4: { closed: false, open: "00:00", close: "23:59" },
        5: { closed: false, open: "00:00", close: "23:59" },
        6: { closed: false, open: "00:00", close: "23:59" },
        7: { closed: false, open: "00:00", close: "23:59" },
      },
    }),
    false,
  );
});

test("schedule closed day", () => {
  const wall = cairoWeekdayAndMinutes(new Date());
  assert.ok(wall);
  const hours = {};
  for (let i = 1; i <= 7; i++) {
    hours[String(i)] = {
      closed: i === wall.weekday,
      open: "00:00",
      close: "23:59",
    };
  }
  assert.equal(
    isWithinOperatingHours({ operatingHours: hours }),
    false,
  );
});

test("overnight window spans previous day after midnight", () => {
  const hours = {
    4: { closed: false, open: "22:00", close: "02:00" }, // Thursday
  };
  // Friday 2026-08-14 01:30 Africa/Cairo = 2026-08-13 22:30 UTC (DST +3)
  const fridayNight = new Date("2026-08-13T22:30:00.000Z");
  assert.equal(isWithinOperatingHours({ operatingHours: hours }, fridayNight), true);
  // Friday noon should be closed (no Friday schedule, Thursday overnight ended)
  const fridayNoon = new Date("2026-08-14T09:00:00.000Z");
  assert.equal(isWithinOperatingHours({ operatingHours: hours }, fridayNoon), false);
});
