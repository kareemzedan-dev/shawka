const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DEFAULTS,
  getConfig,
  templateOverrides,
} = require("../shared/config");

test("Remote Config template values are normalized to typed config", () => {
  const template = {
    parameters: {
      driver_assignment_accept_seconds: {
        defaultValue: { value: "60" },
      },
      driver_background_location_enabled: {
        defaultValue: { value: "false" },
      },
    },
  };
  const config = getConfig(templateOverrides(template));
  assert.equal(config.driver_assignment_accept_seconds, 60);
  assert.equal(config.driver_background_location_enabled, false);
  assert.equal(
    config.driver_assignment_max_rounds,
    DEFAULTS.driver_assignment_max_rounds,
  );
});

test("runtime assignment values are clamped to production-safe bounds", () => {
  const config = getConfig({
    driver_assignment_accept_seconds: 1,
    driver_assignment_max_rounds: 100,
    driver_assignment_radius_km: -10,
    driver_assignment_candidates_per_round: 1000,
  });
  assert.equal(config.driver_assignment_accept_seconds, 10);
  assert.equal(config.driver_assignment_max_rounds, 10);
  assert.equal(config.driver_assignment_radius_km, 1);
  assert.equal(config.driver_assignment_candidates_per_round, 100);
});
