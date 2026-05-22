CREATE TABLE cards_catalog (
    id                       VARCHAR(20) PRIMARY KEY,
    name                     VARCHAR(255) NOT NULL,
    number                   VARCHAR(10) NOT NULL,

    supertype                VARCHAR(20) NOT NULL,
    subtypes                 TEXT[] DEFAULT '{}',
    rarity                   VARCHAR(30),

    hp                       INT,
    types                    TEXT[] DEFAULT '{}',
    evolves_from             VARCHAR(255),
    evolves_to               TEXT[] DEFAULT '{}',
    converted_retreat_cost   INT,
    retreat_cost             TEXT[] DEFAULT '{}',

    attacks                  JSONB DEFAULT '[]'::jsonb,
    weaknesses               JSONB DEFAULT '[]'::jsonb,
    resistances              JSONB DEFAULT '[]'::jsonb,
    abilities                JSONB DEFAULT '[]'::jsonb,
    rules                    JSONB DEFAULT '[]'::jsonb,
    legalities               JSONB DEFAULT '{}'::jsonb,

    image_small_url          VARCHAR(500),
    image_large_url          VARCHAR(500),

    artist                   VARCHAR(255),
    flavor_text              TEXT,
    national_pokedex_numbers INT[] DEFAULT '{}',

    created_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    CONSTRAINT chk_supertype CHECK (supertype IN ('Pokémon','Trainer','Energy'))
);

CREATE INDEX idx_cards_supertype   ON cards_catalog(supertype);
CREATE INDEX idx_cards_rarity      ON cards_catalog(rarity);
CREATE INDEX idx_cards_name_search ON cards_catalog USING gin(to_tsvector('english', name));
CREATE INDEX idx_cards_types       ON cards_catalog USING gin(types);
CREATE INDEX idx_cards_subtypes    ON cards_catalog USING gin(subtypes);
