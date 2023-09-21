const check = require('check-types');

function _sanitize(raw, clean) {
    // error & warning messages
    var messages = { errors: [], warnings: [] };

    // target input param
    var fareZoneAuthorities = raw.fare_zone_authorities;

    // param 'fare_zone_authorities' is optional and should not
    // error when simply not set by the user
    if (check.assigned(fareZoneAuthorities)){

        // must be valid string
        if (!check.nonEmptyString(fareZoneAuthorities)) {
            messages.errors.push('fare_zone_authorities is not a string');
        }
    }

    return messages;
}

function _expected(){
    return [{ name: 'fare_zone_authorities' }];
}

module.exports = () => ({
    sanitize: _sanitize,
    expected: _expected
});
