CREATE TABLE "dhcp6_fingerprint" (
  "id" varchar(11) NOT NULL,
  "value" varchar(1000) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "dhcp6_enterprise" (
  "id" varchar(11) NOT NULL,
  "value" varchar(1000) DEFAULT NULL,
  "created_at" datetime DEFAULT NULL,
  "updated_at" datetime DEFAULT NULL,
  PRIMARY KEY ("id")
);

ALTER TABLE "combination" ADD COLUMN "dhcp6_fingerprint_id" varchar(11) DEFAULT NULL;
ALTER TABLE "combination" ADD COLUMN "dhcp6_enterprise_id" varchar(11) DEFAULT NULL;
