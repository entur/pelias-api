function filterByFareZones(req, renderedQuery) {
  if (!req || !req.query) {
      return;
  }
  if (!renderedQuery || !renderedQuery.body || !renderedQuery.body.query || !renderedQuery.body.query.bool) {
      return;
  }
  var fareZoneIds = req.query.fare_zone_ids;
  var fareZoneAuthorities = req.query.fare_zone_authorities;
  if (fareZoneIds || fareZoneAuthorities) {
      if (!renderedQuery.body.query.bool.filter) {
          renderedQuery.body.query.bool.filter = [];
      }

      if (fareZoneIds) {
          var fareZoneIdsTerms = {
              terms: {
                  'fare_zones': fareZoneIds.split(',')
              }
          };
          renderedQuery.body.query.bool.filter.push(fareZoneIdsTerms);
      }

      if (fareZoneAuthorities) {
          var fareZoneAuthoritiesTerms = {
              terms: {
                  'tariff_zone_authorities': fareZoneAuthorities.split(',')
              }
          };
          renderedQuery.body.query.bool.filter.push(fareZoneAuthoritiesTerms);
      }
  }
}

module.exports = filterByFareZones;