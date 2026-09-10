<?php

/**
 * Settings rows for the TonPays gateway, on installations that already exist.
 *
 * `db/tables/PaySetting.php` seeds only when the table is created, so an
 * install upgraded to a version with this gateway would have zero matching
 * rows and an admin pasting their API key would see it accepted and saved
 * nowhere. `statustonpays` deliberately lands on `offtonpays` for the same
 * reason `iranpay4` does: a gateway shown before it is configured takes the
 * buyer to a page that cannot be created.
 */

return static function (PDO $pdo, Schema $schema): void {
    if (!$schema->tableExists('PaySetting')) {
        return;
    }

    $defaults = [
        'statustonpays' => 'offtonpays',
        'apikey_tonpays' => '0',
        'chashbacktonpays' => '0',
        'minbalancetonpays' => '20000',
        'maxbalancetonpays' => '1000000',
        'helptonpays' => '2',
    ];

    // INSERT IGNORE rather than a delete-then-insert: an admin who configured
    // this gateway before upgrading keeps what they configured.
    $stmt = $pdo->prepare('INSERT IGNORE INTO PaySetting (NamePay, ValuePay) VALUES (:name, :value)');
    foreach ($defaults as $name => $value) {
        $stmt->execute([':name' => $name, ':value' => $value]);
    }
};
