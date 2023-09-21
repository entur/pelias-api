const check = require('check-types');

function _sanitize(raw, clean) {
    // error & warning messages
    var messages = { errors: [], warnings: [] };

    // target input param
    var fareZoneIds = raw.fare_zone_ids;

    // param 'fare_zone_ids' is optional and should not
    // error when simply not set by the user
    if (check.assigned(fareZoneIds)){

        // must be valid string
        if (!check.nonEmptyString(fareZoneIds)) {
            messages.errors.push('fare_zone_ids is not a string');
        }
    }

    return messages;
}

function _expected(){
    return [{ name: 'fare_zone_ids' }];
}

module.exports = () => ({
    sanitize: _sanitize,
    expected: _expected
});
